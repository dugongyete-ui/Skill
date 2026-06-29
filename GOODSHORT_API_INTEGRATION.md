# GoodShort API — Panduan Integrasi Web

> **Platform:** GoodShort (drama pendek Asia)
> **Base URL:** `https://goodshort.goodbos.online`
> **Auth:** Tidak diperlukan (semua endpoint di bawah gratis)
> **CORS:** Tersedia — bisa dipanggil dari frontend browser langsung
> **Catatan penting:** Saat memutar video, wajib kirim header `Referer: https://goodshort.goodbos.online/`

---

## Struktur API Endpoint

### 1. Navigasi / Kategori

```
GET /nav?lang={lang}
```

**Fungsi:** Ambil daftar channel/kategori yang tersedia (Hot, New, Ranking, dll)

**Parameter:**
| Nama | Tipe | Wajib | Keterangan |
|---|---|---|---|
| `lang` | string | Ya | Bahasa: `en`, `in`, `zh`, `ja`, `ko`, `th`, `vi` |

**Contoh request:**
```
GET https://goodshort.goodbos.online/nav?lang=en
```

**Contoh response:**
```json
{
  "data": {
    "list": [
      { "channelId": -1,  "title": "Hot🔥",   "channelType": 1 },
      { "channelId": 429, "title": "New",      "channelType": 0 },
      { "channelId": -3,  "title": "Ranking",  "channelType": 3 }
    ]
  }
}
```

**Cara pakai:** Tampilkan `title` sebagai tab navigasi. Simpan `channelId` untuk dipakai di endpoint `/home`.

---

### 2. Daftar Drama (Homepage / Browse)

```
GET /home?lang={lang}&channelId={channelId}&page={page}&size={size}
```

**Fungsi:** Ambil daftar drama berdasarkan channel/kategori dengan paginasi

**Parameter:**
| Nama | Tipe | Wajib | Default | Keterangan |
|---|---|---|---|---|
| `lang` | string | Ya | — | Bahasa konten |
| `channelId` | integer | Ya | — | Dari `/nav`. `-1` = Hot, `429` = New |
| `page` | integer | Tidak | `1` | Halaman (mulai dari 1) |
| `size` | integer | Tidak | `24` | Jumlah drama per halaman (maks 24) |

**Contoh request:**
```
GET https://goodshort.goodbos.online/home?lang=en&channelId=-1&page=1&size=20
```

**Contoh response:**
```json
{
  "data": {
    "current": 1,
    "pages": 60,
    "continueWatching": false,
    "records": [
      {
        "channelId": -1,
        "columnStyle": "SLIDE_BANNER_SMALL",
        "items": [
          {
            "bookId": "31001424670",
            "bookName": "Awakened as a Dragon Tamer After Dragon Extinction",
            "cover": "https://acfs1.goodreels.com/videobook/202606/cover-Hz5v9OMQCs.jpg",
            "chapterCount": 68,
            "bookType": 5,
            "downloadEnable": true
          }
        ]
      }
    ]
  }
}
```

**Cara pakai:**
- Loop `data.records[]` → tiap record punya `items[]`
- Dari tiap item ambil: `bookId`, `bookName`, `cover`, `chapterCount`
- `bookId` dipakai untuk request episode
- `chapterCount` = total episode tersedia
- `data.pages` = total halaman untuk infinite scroll / pagination
- `data.current` = halaman saat ini

**Catatan struktur records:**
```
data.records adalah array of "column groups"
Tiap column group berisi items[] = array drama
Flatten semua items dari semua records untuk dapat flat list drama
```

---

### 3. Ambil Link Video Episode

```
GET /episode/?bookId={bookId}&ep={epNumber}
```

**Fungsi:** Ambil URL M3U8 (HLS) untuk episode tertentu

**Parameter:**
| Nama | Tipe | Wajib | Keterangan |
|---|---|---|---|
| `bookId` | string | Ya | ID drama dari endpoint `/home` |
| `ep` | integer | Ya | Nomor episode (mulai dari 1) |

**Catatan:** Perhatikan trailing slash setelah `/episode/` — wajib ada.

**Contoh request:**
```
GET https://goodshort.goodbos.online/episode/?bookId=31001424670&ep=1
```

**Contoh response:**
```json
{
  "data": {
    "consumptionUnLock": false,
    "list": [
      {
        "bookId": "31001424670",
        "buyWay": "免费",
        "cdn": "https://v3.goodshort.com/mts/.../720p/xxx_720p.m3u8?expiredTime=1783985969&tul=...",
        "cdnList": [
          {
            "cdnDomain": "https://v3-akm.goodreels.com",
            "videoPath": "https://v3-akm.goodreels.com/mts/.../720p/xxx_720p.m3u8?__token__=exp=1783985969~hmac=abc123..."
          },
          {
            "cdnDomain": "https://v2-akm.goodreels.com",
            "videoPath": "https://v2-akm.goodreels.com/mts/.../720p/xxx_720p.m3u8?__token__=exp=1783985969~hmac=def456..."
          }
        ]
      }
    ]
  }
}
```

**Cara ambil URL video yang benar:**
```
GUNAKAN: data.list[0].cdnList[0].videoPath  ← PRIORITAS UTAMA
FALLBACK: data.list[0].cdnList[1].videoPath  ← CDN kedua jika pertama gagal
JANGAN pakai: data.list[0].cdn               ← domain ini block akses tanpa Referer asli
```

**Cek paywall:**
```
data.list[0].buyWay === "免费"  → gratis, langsung putar
data.consumptionUnLock === false → tidak ada sistem koin/unlock
```

**Token expired:** URL mengandung `exp=TIMESTAMP` (unix time). Token valid beberapa jam. Jika video gagal diputar, fetch ulang endpoint ini untuk dapat URL baru.

---

### 4. Cara Memutar Video (HLS)

URL video dari `cdnList[].videoPath` adalah format **HLS M3U8**.

**Wajib:** Kirim header `Referer: https://goodshort.goodbos.online/` saat mengakses CDN.

#### Implementasi dengan HLS.js (untuk browser yang tidak support HLS native):

```html
<script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>

<video id="videoPlayer" controls playsinline></video>

<script>
async function playEpisode(bookId, ep) {
  // 1. Fetch URL video
  const res = await fetch(
    `https://goodshort.goodbos.online/episode/?bookId=${bookId}&ep=${ep}`
  );
  const data = await res.json();

  const cdnList = data.data.list[0].cdnList;
  const videoUrl = cdnList[0].videoPath; // Ambil CDN pertama

  // 2. Inisialisasi HLS player
  const video = document.getElementById('videoPlayer');

  if (Hls.isSupported()) {
    const hls = new Hls({
      xhrSetup: (xhr) => {
        xhr.setRequestHeader('Referer', 'https://goodshort.goodbos.online/');
      }
    });
    hls.loadSource(videoUrl);
    hls.attachMedia(video);
    hls.on(Hls.Events.MANIFEST_PARSED, () => video.play());

    // Fallback ke CDN kedua jika error
    hls.on(Hls.Events.ERROR, (event, data) => {
      if (data.fatal && cdnList[1]) {
        hls.destroy();
        playFromUrl(cdnList[1].videoPath, video);
      }
    });
  } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
    // Safari — native HLS support
    video.src = videoUrl;
    video.play();
  }
}
</script>
```

#### Catatan CORS untuk Referer:
- **HLS.js** bisa set header via `xhrSetup`
- **Native video tag** tidak bisa set Referer dari JS — gunakan proxy backend jika perlu
- **React Native / mobile app** — set header di level fetch/axios

---

## Contoh Alur Implementasi Lengkap

### Alur 1: Halaman Utama (Homepage)

```
1. GET /nav?lang=en
   → Dapat daftar channelId untuk tab navigasi

2. GET /home?lang=en&channelId=-1&page=1&size=20
   → Dapat daftar drama (bookId, bookName, cover, chapterCount)

3. Tampilkan grid card drama:
   - Thumbnail: cover URL (langsung dari CDN goodreels.com, tidak perlu proxy)
   - Judul: bookName
   - Badge episode: chapterCount + " eps"
```

### Alur 2: Halaman Detail / Player

```
1. Simpan bookId dan chapterCount dari halaman sebelumnya

2. Tampilkan list nomor episode: [1] [2] [3] ... [chapterCount]

3. Ketika user klik episode N:
   GET /episode/?bookId={bookId}&ep={N}
   → Ambil cdnList[0].videoPath
   → Load ke HLS player

4. Tombol "Episode Berikutnya":
   ep = ep + 1 (sampai chapterCount)
   → Fetch ulang /episode/ untuk dapat URL baru
```

### Alur 3: Paginasi / Infinite Scroll

```
Cek: data.current < data.pages → masih ada halaman berikutnya

Scroll ke bawah → GET /home?...&page={currentPage+1}
→ Append items baru ke list
```

---

## Struktur Data Lengkap

### Drama Card (dari /home)

```typescript
interface DramaItem {
  bookId: string;        // ID unik drama — pakai untuk /episode/
  bookName: string;      // Judul drama
  cover: string;         // URL thumbnail (CDN goodreels.com)
  chapterCount: number;  // Total episode tersedia
  bookType: number;      // Type konten (5 = drama pendek)
  channelId: number;     // Channel asal
  downloadEnable: boolean;
}
```

### Episode Response (dari /episode/)

```typescript
interface EpisodeResponse {
  data: {
    consumptionUnLock: boolean;  // false = tidak ada paywall
    list: Array<{
      bookId: string;
      buyWay: string;     // "免费" = gratis
      cdn: string;        // URL CDN utama (jangan dipakai langsung)
      cdnList: Array<{
        cdnDomain: string;
        videoPath: string;  // ← URL M3U8 yang dipakai untuk player
      }>;
    }>;
  };
}
```

### Channel Nav (dari /nav)

```typescript
interface NavChannel {
  channelId: number;    // Pakai ini di /home?channelId=
  title: string;        // Label tab (Hot🔥, New, Ranking, dll)
  channelType: number;  // Tipe internal
  layerId: string;
}
```

---

## Bahasa yang Didukung

| Kode | Bahasa |
|---|---|
| `en` | English |
| `in` | Bahasa Indonesia |
| `zh` | 中文 (Mandarin) |
| `ja` | 日本語 |
| `ko` | 한국어 |
| `th` | ภาษาไทย |
| `vi` | Tiếng Việt |

---

## Hal-hal yang TIDAK Bisa Dilakukan (Gratis)

| Fitur | Status | Catatan |
|---|---|---|
| Search/pencarian drama | ❌ | Butuh code berbayar dari owner |
| Filter by genre | ❌ | Tidak tersedia gratis |
| Halaman detail drama | ❌ | Tidak ada endpoint detail gratis |
| Daftar semua episode sekaligus | ❌ | Perlu fetch /episode/ satu per satu |
| Subtitle/terjemahan | ❌ | Tidak tersedia di API ini |

**Alternatif untuk search:** Tampilkan tab Hot / New / Ranking sebagai pengganti fitur pencarian.

---

## Contoh Kode Fetch (JavaScript/Browser)

```javascript
const API_BASE = 'https://goodshort.goodbos.online';

// Ambil daftar tab/kategori
async function getChannels(lang = 'en') {
  const res = await fetch(`${API_BASE}/nav?lang=${lang}`);
  const json = await res.json();
  return json.data.list; // Array of { channelId, title }
}

// Ambil daftar drama
async function getDramas(channelId = -1, page = 1, lang = 'en') {
  const res = await fetch(
    `${API_BASE}/home?lang=${lang}&channelId=${channelId}&page=${page}&size=20`
  );
  const json = await res.json();

  // Flatten items dari semua records
  const items = [];
  for (const record of json.data.records) {
    for (const item of record.items) {
      items.push({
        bookId: item.bookId,
        title: item.bookName,
        cover: item.cover,
        totalEps: item.chapterCount,
      });
    }
  }

  return {
    dramas: items,
    totalPages: json.data.pages,
    currentPage: json.data.current,
  };
}

// Ambil URL video episode
async function getEpisodeUrl(bookId, ep = 1) {
  const res = await fetch(
    `${API_BASE}/episode/?bookId=${bookId}&ep=${ep}`
  );
  const json = await res.json();

  const episodeData = json.data.list[0];

  return {
    isLocked: episodeData.buyWay !== '免费',
    cdnPrimary: episodeData.cdnList[0]?.videoPath,   // Gunakan ini
    cdnFallback: episodeData.cdnList[1]?.videoPath,  // Fallback
  };
}

// Contoh penggunaan lengkap
async function main() {
  // 1. Ambil channel
  const channels = await getChannels('en');
  console.log('Channels:', channels);

  // 2. Ambil drama dari channel Hot
  const { dramas, totalPages } = await getDramas(-1, 1, 'en');
  console.log('Dramas:', dramas);

  // 3. Ambil URL episode 1 dari drama pertama
  const { cdnPrimary } = await getEpisodeUrl(dramas[0].bookId, 1);
  console.log('Video URL:', cdnPrimary);
}
```

---

## Batasan & Catatan Teknis

| Aspek | Detail |
|---|---|
| **Rate limit** | Tidak diketahui — gunakan wajar, jangan spam |
| **Token expiry** | URL video expired setelah beberapa jam (`exp=` di URL) |
| **Referer wajib** | Wajib di CDN `v3-akm.goodreels.com` / `v2-akm.goodreels.com` |
| **HTTPS** | Wajib — semua endpoint HTTPS |
| **CORS** | API mengizinkan akses dari browser (tidak perlu proxy backend) |
| **Cover image** | CDN `acfs1.goodreels.com` — bisa langsung dipakai di `<img>` tag |
| **Video CDN** | `v3-akm.goodreels.com` dan `v2-akm.goodreels.com` — coba keduanya |
| **Format video** | HLS (.m3u8) — butuh HLS.js di browser yang tidak support native |

---

## Checklist Implementasi

- [ ] Install HLS.js (`npm install hls.js` atau pakai CDN)
- [ ] Fetch `/nav` untuk dapat channelId tab navigasi
- [ ] Fetch `/home?channelId=-1` untuk tampilan awal (Hot)
- [ ] Flatten `records[].items[]` untuk dapat flat list drama
- [ ] Tampilkan card: cover, title, total episode
- [ ] Klik drama → tampilkan tombol episode 1 s/d chapterCount
- [ ] Klik episode → fetch `/episode/?bookId=X&ep=N` → ambil `cdnList[0].videoPath`
- [ ] Load URL M3U8 ke HLS.js dengan `xhrSetup` untuk Referer header
- [ ] Handle error CDN → fallback ke `cdnList[1].videoPath`
- [ ] Handle token expired (re-fetch `/episode/` jika video gagal load)
- [ ] Implementasi paginasi: `page++` ketika scroll ke bawah, cek `current < pages`
