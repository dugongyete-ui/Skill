#!/usr/bin/env bash
# ============================================================
# DramaBos API Key Generator
# Target: https://dramabos.live
# Rate limit: 1 akun per ~6 menit (Cloudflare enforced)
# Script otomatis tunggu cooldown dan lanjut register
# ============================================================

TARGET="https://dramabos.live"
OUTPUT="apikeys.md"
TOTAL=100
SAVE_FILE="/tmp/drb_progress.txt"   # simpan progress antar-run

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

SUCCESS_COUNT=0
declare -a RESULTS

log_ok()   { echo -e "${GREEN}[✓]${NC} $1"; }
log_fail() { echo -e "${RED}[✗]${NC} $1"; }
log_info() { echo -e "${CYAN}[i]${NC} $1"; }
log_wait() { echo -e "${YELLOW}[⏳]${NC} $1"; }

# ── Load progress sebelumnya ───────────────────────────────
if [[ -f "$SAVE_FILE" ]]; then
  log_info "Melanjutkan progress sebelumnya..."
  while IFS= read -r line; do
    RESULTS+=("$line")
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  done < "$SAVE_FILE"
  log_ok "Loaded ${SUCCESS_COUNT} akun dari save file"
fi

# ── Fungsi register 1 akun ─────────────────────────────────
register_account() {
  local INDEX=$1
  local RAND=$(cat /proc/sys/kernel/random/uuid | tr -d '-' | head -c 12)
  local EMAIL="dbuser_${RAND}@mailinator.com"
  local NAME="DBUser${RAND:0:8}"
  local PASS="Pass@$(echo $RAND | head -c 6)99"

  # Step 1: CSRF token
  local CSRF_RESP
  CSRF_RESP=$(curl -s -c /tmp/drb_c${INDEX}.txt \
    "${TARGET}/api/auth/csrf" \
    --tlsv1.3 --max-time 12 \
    -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/138.0.0.0 Safari/537.36" \
    -H "Accept: application/json" 2>/dev/null)

  local CSRF_TOKEN
  CSRF_TOKEN=$(echo "$CSRF_RESP" | grep -oE '"csrfToken":"[^"]+"' | cut -d'"' -f4)

  if [[ -z "$CSRF_TOKEN" ]]; then
    log_fail "#${INDEX} Gagal ambil CSRF (mungkin CF block)"
    return 2
  fi

  # Step 2: Register
  local REG_BODY REG_HTTP
  REG_BODY=$(curl -s \
    -c /tmp/drb_c${INDEX}.txt -b /tmp/drb_c${INDEX}.txt \
    -D /tmp/drb_h${INDEX}.txt \
    -w "\n__HTTP_CODE__:%{http_code}" \
    -X POST "${TARGET}/api/auth/register" \
    --tlsv1.3 --max-time 15 \
    -H "Content-Type: application/json" \
    -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/138.0.0.0 Safari/537.36" \
    -H "Origin: ${TARGET}" \
    -H "Referer: ${TARGET}/register" \
    -H "X-CSRF-Token: ${CSRF_TOKEN}" \
    -d "{\"name\":\"${NAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASS}\",\"csrfToken\":\"${CSRF_TOKEN}\"}" 2>/dev/null)

  REG_HTTP=$(echo "$REG_BODY" | grep -oE '__HTTP_CODE__:[0-9]+' | cut -d: -f2)
  REG_BODY=$(echo "$REG_BODY" | sed 's/__HTTP_CODE__:.*//')

  # Cek rate limit — ambil waktu tunggu
  if echo "$REG_BODY" | grep -qi "too many registration"; then
    local WAIT_SEC
    WAIT_SEC=$(echo "$REG_BODY" | grep -oE '[0-9]+ seconds' | grep -oE '[0-9]+' | head -1)
    WAIT_SEC=${WAIT_SEC:-370}
    echo "$EMAIL|RATE_LIMITED|${WAIT_SEC}s"
    rm -f /tmp/drb_c${INDEX}.txt /tmp/drb_h${INDEX}.txt
    return 1  # return 1 = rate limited
  fi

  if ! echo "$REG_BODY" | grep -q '"ok":true'; then
    log_fail "#${INDEX} Gagal register: ${REG_BODY:0:80}"
    rm -f /tmp/drb_c${INDEX}.txt /tmp/drb_h${INDEX}.txt
    return 2
  fi

  # Ambil session cookie
  local SESSION_COOKIE
  SESSION_COOKIE=$(grep -i 'dramabos_session' /tmp/drb_h${INDEX}.txt \
    | grep -oE 'dramabos_session=[^;]+' | head -1)

  if [[ -z "$SESSION_COOKIE" ]]; then
    SESSION_COOKIE=$(grep 'dramabos_session' /tmp/drb_c${INDEX}.txt 2>/dev/null \
      | awk '{print "dramabos_session="$7}' | head -1)
  fi

  if [[ -z "$SESSION_COOKIE" ]]; then
    log_fail "#${INDEX} Gagal ambil session cookie"
    rm -f /tmp/drb_c${INDEX}.txt /tmp/drb_h${INDEX}.txt
    return 2
  fi

  sleep 0.8

  # Step 3: Ambil API key dari dashboard (RSC)
  local DASH
  DASH=$(curl -s "${TARGET}/dashboard" \
    --tlsv1.3 --compressed --max-time 20 \
    -H "Cookie: ${SESSION_COOKIE}" \
    -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/138.0.0.0 Safari/537.36" \
    -H "Accept: text/x-component" \
    -H "RSC: 1" 2>/dev/null)

  local API_KEY
  API_KEY=$(echo "$DASH" | grep -oE '"apiKey":"dbk_live_[^"]+"' | cut -d'"' -f4 | head -1)

  # Fallback normal HTML
  if [[ -z "$API_KEY" ]]; then
    DASH=$(curl -s "${TARGET}/dashboard" \
      --tlsv1.3 --compressed --max-time 20 \
      -H "Cookie: ${SESSION_COOKIE}" \
      -H "User-Agent: Mozilla/5.0 Chrome/138.0.0.0" \
      -H "Accept: text/html" 2>/dev/null)
    API_KEY=$(echo "$DASH" | grep -oE '"apiKey":"dbk_live_[^"]+"' | cut -d'"' -f4 | head -1)
  fi

  rm -f /tmp/drb_c${INDEX}.txt /tmp/drb_h${INDEX}.txt

  if [[ -z "$API_KEY" ]]; then
    log_fail "#${INDEX} Gagal ekstrak API key"
    return 2
  fi

  log_ok "#${INDEX} ${EMAIL} → ${API_KEY}"
  local ENTRY="${INDEX}|${EMAIL}|${PASS}|${API_KEY}"
  RESULTS+=("$ENTRY")
  echo "$ENTRY" >> "$SAVE_FILE"   # simpan langsung
  return 0
}

# ── Tulis file Markdown ────────────────────────────────────
write_md() {
  local DONE=${#RESULTS[@]}
  {
    echo "# DramaBos API Keys"
    echo ""
    echo "> **Auto-generated:** $(date '+%Y-%m-%d %H:%M:%S')"
    echo "> **Base API:** \`https://prod-api.dramabos.live\`"
    echo "> **Auth:** \`Authorization: Bearer {API_KEY}\`"
    echo "> **Plan:** Free — 1.000 req/bulan, semua provider aktif"
    echo ""
    echo "## Ringkasan"
    echo ""
    echo "| | |"
    echo "|---|---|"
    echo "| Total akun berhasil | **${DONE}** / ${TOTAL} |"
    echo "| Tanggal generate | \`$(date '+%Y-%m-%d')\` |"
    echo "| Status | $([ $DONE -ge $TOTAL ] && echo '✅ Selesai' || echo "🔄 ${DONE}/${TOTAL} (lanjutkan dengan \`bash generate_apikeys.sh\`)") |"
    echo ""
    echo "## Provider Aktif"
    echo ""
    echo "| Provider | Search | Detail | Stream/HLS |"
    echo "|---|---|---|---|"
    echo "| **FlickReels** | \`/flickreels/api/flickreels/search?q={q}\` | \`/flickreels/api/flickreels/detail?id={id}\` | \`/flickreels/api/flickreels/hls?id={id}&ep={n}&ts={ts}&sig={sig}\` |"
    echo "| **ShortMax** | \`/shortmax/api/v1/search?q={q}\` | \`/shortmax/api/v1/detail/{code}\` | \`/shortmax/api/v1/play/{code}\` |"
    echo "| **iDrama** | \`/idrama/search?q={q}\` | \`/idrama/drama/{id}?lang=id\` | \`/idrama/unlock/{id}/{ep}?lang=id\` |"
    echo "| **DramaBox** | ❌ decode error | ❌ decode error | ❌ decode error |"
    echo ""
    echo "## Cara Pakai"
    echo ""
    echo "\`\`\`bash"
    echo "API_KEY=\"dbk_live_xxxxxxxxxxxxxxxx\""
    echo "BASE=\"https://prod-api.dramabos.live\""
    echo ""
    echo "# Search FlickReels"
    echo "curl -s \"\${BASE}/flickreels/api/flickreels/search?q=love+story\" \\"
    echo "  -H \"Authorization: Bearer \${API_KEY}\""
    echo ""
    echo "# Detail drama FlickReels (id dari search)"
    echo "curl -s \"\${BASE}/flickreels/api/flickreels/detail?id=240\" \\"
    echo "  -H \"Authorization: Bearer \${API_KEY}\""
    echo ""
    echo "# Episode list + link HLS"
    echo "curl -s \"\${BASE}/flickreels/api/flickreels/episode?id=240&ep=1\" \\"
    echo "  -H \"Authorization: Bearer \${API_KEY}\""
    echo ""
    echo "# Stream HLS langsung (m3u8 playlist)"
    echo "curl -s \"\${BASE}/flickreels/api/flickreels/hls?id=240&ep=1&ts={ts}&sig={sig}\" \\"
    echo "  -H \"Authorization: Bearer \${API_KEY}\""
    echo ""
    echo "# ShortMax search (min 2 kata)"
    echo "curl -s \"\${BASE}/shortmax/api/v1/search?q=love+story\" \\"
    echo "  -H \"Authorization: Bearer \${API_KEY}\""
    echo ""
    echo "# iDrama search"
    echo "curl -s \"\${BASE}/idrama/search?q=love+story\" \\"
    echo "  -H \"Authorization: Bearer \${API_KEY}\""
    echo "\`\`\`"
    echo ""
    echo "## Daftar API Key"
    echo ""
    echo "| No | Email | Password | API Key |"
    echo "|---|---|---|---|"

    for entry in "${RESULTS[@]}"; do
      IFS='|' read -r no email pass apikey <<< "$entry"
      echo "| ${no} | \`${email}\` | \`${pass}\` | \`${apikey}\` |"
    done

    if [[ ${#RESULTS[@]} -eq 0 ]]; then
      echo "| — | Belum ada akun | — | — |"
    fi

    echo ""
    echo "---"
    echo "*Generated by DramaBos API Key Generator | Rate limit: 1 akun/6 menit per IP*"
  } > "$OUTPUT"
}

# ── Main loop ──────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════╗"
echo -e "║      DramaBos API Key Generator — Target: ${TOTAL} Akun      ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
log_info "Target   : ${TARGET}"
log_info "Output   : ${OUTPUT}"
log_info "Progress : ${SUCCESS_COUNT}/${TOTAL} sudah ada"
echo ""

START_TS=$(date +%s)
INDEX=$((SUCCESS_COUNT + 1))

while [[ ${#RESULTS[@]} -lt $TOTAL ]]; do
  RESULT=$(register_account "$INDEX" 2>&1)
  EXIT_CODE=$?

  if [[ $EXIT_CODE -eq 0 ]]; then
    # Berhasil — tulis MD langsung
    write_md
    SUCCESS_COUNT=${#RESULTS[@]}
    INDEX=$((INDEX + 1))
    ELAPSED=$(( $(date +%s) - START_TS ))
    REMAINING=$(( (TOTAL - SUCCESS_COUNT) ))
    ETA=$(( REMAINING * 375 ))
    printf "  ${CYAN}[${SUCCESS_COUNT}/${TOTAL}]${NC} ETA: ~%dm%ds\n" $((ETA/60)) $((ETA%60))
    sleep 3

  elif [[ $EXIT_CODE -eq 1 ]]; then
    # Rate limited — tunggu
    WAIT_SEC=$(echo "$RESULT" | grep -oE '[0-9]+s' | grep -oE '[0-9]+' | head -1)
    WAIT_SEC=${WAIT_SEC:-370}
    WAIT_SEC=$((WAIT_SEC + 10))  # buffer 10 detik
    log_wait "Rate limit! Tunggu ${WAIT_SEC}s (~$((WAIT_SEC/60))m$((WAIT_SEC%60))s) lalu lanjut..."
    write_md  # simpan progress saat ini
    # Countdown
    for ((s=WAIT_SEC; s>0; s--)); do
      printf "\r  ${YELLOW}⏳ Cooldown: %3ds${NC}   " "$s"
      sleep 1
    done
    echo ""

  else
    # Error lain — skip, lanjut
    INDEX=$((INDEX + 1))
    sleep 2
  fi
done

write_md

echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════╗"
echo -e "║                    SELESAI! ✅                           ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${GREEN}Berhasil : ${#RESULTS[@]} akun${NC}"
echo -e "  ${YELLOW}Output   : ${OUTPUT}${NC}"
echo -e "  ${CYAN}Durasi   : $(( ($(date +%s) - START_TS) / 60 ))m${NC}"
echo ""
rm -f "$SAVE_FILE"
