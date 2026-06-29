# api.dramabuzz.sbs — Hasil Rekon Lengkap

> **Tanggal rekon:** 2026-06-29
> **Owner:** @nanomilkiss / @nanomilkisbot (Telegram)
> **Ekosistem:** dramabos.asia (frontend) + api.dramabuzz.sbs (backend) + goodbos.online (11 subdomain platform)
> **Total platform:** 42+ (klaim owner)

---

## Ringkasan Cepat

| Platform | Base URL | Browse | Search | Detail | Stream |
|---|---|---|---|---|---|
| **GoodShort** | goodshort.goodbos.online | ✅ Free | ❌ | ❌ | ✅ Free |
| **FlickReels** | flickreels.goodbos.online | ✅ Free | ✅ Free | ❌ | 🔑 Key |
| **ReelShort** | reelshort.goodbos.online | ✅ Free | ✅ Free | ❌ 500 | 🔑 Key |
| **iDrama** | idrama.goodbos.online | ✅ Free | ✅ Free | 🔑 Key | 🔑 Key |
| **NetShort** | netshort.goodbos.online | ✅ Free | ✅ Free | ✅ Free | 🔑 Key |
| **RaptDrama** | raptdrama.goodbos.online | ✅ Free | ✅ Free | ✅ Free | 🔑 Key |
| **DramaBite** | dramabite.goodbos.online | ✅ Free | ✅ Free | ❌ | 🔑 Key |
| **Melolo** | melolo.goodbos.online | ❌ Key | ✅ Free | 🔑 Key | 🔑 Key |
| **DramaBox** | dramabox.goodbos.online | 🔑 Key | 🔑 Key | 🔑 Key | 🔑 Key |
| **ShortMax** | shortmax.goodbos.online | 🔑 Key | 🔑 Key | 🔑 Key | 🔑 Key |
| **PineDrama** | pinedrama.goodbos.online | 🔑 Key | 🔑 Key | 🔑 Key | 🔑 Key |

**Legend:** ✅ Free = HTTP 200 tanpa auth | 🔑 Key = butuh kode berbayar | ❌ = tidak tersedia/error

---

## api.dramabuzz.sbs — Backend Utama

### Auth & Pricing

```
Auth method:  ?key=KODE_AKSES  (query param)
              X-Api-Key: KODE_AKSES  (header, alternatif)

Beli key via: https://t.me/nanomilkisbot
Harga:        Rp 40.000 – Rp 129.000 / paket
```

### Endpoint yang Ditemukan

| Endpoint | Method | Status tanpa key | Keterangan |
|---|---|---|---|
| `/api/status` | GET | 401 | Cek status key, satu-satunya endpoint konfirmasi |

**Response `/api/status` tanpa key:**
```json
{
  "success": false,
  "error": "Unauthorized",
  "message": "Kode akses diperlukan untuk mengakses API",
  "usage": {
    "query": "curl http://host/api/status?key=KODE_AKSES"
  }
}
```

**Catatan:** api.dramabuzz.sbs adalah *gateway/proxy* ke semua platform. Endpoint aktualnya tidak diekspos publik — semua route `/api/*` selain `/api/status` return 404. Endpoint nyata ada di tiap subdomain goodbos.online (lihat bagian bawah).

---

## Platform 1: GoodShort ✅ FULL STACK GRATIS

> **Dokumentasi lengkap:** lihat `GOODSHORT_API_INTEGRATION.md`

```
Base URL: https://goodshort.goodbos.online
Auth:     Tidak diperlukan
```

| Endpoint | Status | Keterangan |
|---|---|---|
| `GET /nav?lang={lang}` | ✅ 200 | Daftar tab/kategori |
| `GET /home?lang={lang}&channelId={id}&page={n}&size={n}` | ✅ 200 | Daftar drama |
| `GET /episode/?bookId={id}&ep={n}` | ✅ 200 | HLS M3U8 stream |

---

## Platform 2: FlickReels ✅ Browse Gratis

```
Base URL: https://flickreels.goodbos.online
Auth:     Tidak diperlukan untuk browse
          Butuh key untuk stream (format tidak diketahui)
```

### Endpoint Gratis

#### GET /api/home
Daftar drama populer.

**Contoh request:**
```
GET https://flickreels.goodbos.online/api/home
```

**Contoh response:**
```json
{
  "status_code": 1,
  "msg": "获取成功",
  "data": {
    "data": [
      {
        "playlet_id": 7932,
        "title": "Pernikahan Kontrak Sama Musuhku",
        "cover": "https://zshipubcdn.farsunpteltd.com/playlet/1782526447_f5QsbjbEca.jpg",
        "upload_num": 84,
        "introduce": "..."
      }
    ]
  }
}
```

**Field penting:**
- `playlet_id` — ID drama (pakai untuk detail/episode)
- `title` — Judul drama
- `cover` — URL thumbnail
- `upload_num` — Jumlah episode tersedia

#### GET /api/list
Identik dengan `/api/home`, daftar drama.

#### GET /search?q={query}
Cari drama.

**Parameter:** `q` = kata kunci pencarian

**Catatan:** Jika query terlalu pendek / tidak cocok, `data` bisa null.

```json
{ "data": null, "status_code": 1, "msg": "获取成功" }
```

#### GET /trending
Daftar drama trending.

**Contoh response:**
```json
{
  "data": [
    {
      "cover": "https://zshipubcdn.farsunpteltd.com/playlet/...",
      "hot_num": "893.4K",
      "introduce": "..."
    }
  ]
}
```

#### GET /languages
Daftar bahasa yang tersedia.

---

## Platform 3: ReelShort ✅ Browse Gratis

```
Base URL: https://reelshort.goodbos.online
Auth:     Tidak diperlukan untuk browse
          Butuh key untuk stream episode
```

### Endpoint Gratis

#### GET /home
Daftar drama (homepage).

**Contoh response:**
```json
{
  "books": [
    {
      "id": "6a211c74b6d9a41c8b01403f",
      "title": "High Society",
      "pic": "https://v-img.crazymaplestudios.com/v-images/...",
      "chapters": 77
    }
  ]
}
```

**Field penting:**
- `id` — ID drama (string hex)
- `title` — Judul
- `pic` — URL thumbnail
- `chapters` — Total episode

#### GET /search?q={query}
Cari drama.

**Contoh response:**
```json
{
  "lang": "en",
  "page": 1,
  "query": "love",
  "results": [
    {
      "id": "67773dcf3d3252065f0e5651",
      "title": "Love Me Two Times",
      "pic": "https://...",
      "chapters": 52
    }
  ]
}
```

#### GET /trending
Drama yang sedang trending.

**Contoh response:**
```json
{
  "lang": "en",
  "popular": [
    { "id": "...", "title": "Not the Bride He Wanted", "pic": "...", "chapters": 57 }
  ]
}
```

#### GET /languages
Daftar bahasa yang didukung.

**Response:**
```json
{ "languages": ["zh", "en", "ja", "ko", "zh-TW", "th", "vi", "in", "ru", "fr", "de", "it", "es", "hi", "pt", "ar", "ms", "tr", "pl"] }
```

### Endpoint Berbayar (401)

| Endpoint | Status |
|---|---|
| `GET /allepisodes/{id}` | 🔑 401 |
| `GET /chapters/{id}` | 🔑 401 |
| `GET /detail/{id}` | ❌ 500 |

---

## Platform 4: iDrama ✅ Browse Gratis

```
Base URL: https://idrama.goodbos.online
Auth:     Tidak diperlukan untuk browse
          Search: minimal 2 kata
```

### Endpoint Gratis

#### GET /home
Daftar navigasi channel/tab.

**Contoh response:**
```json
{
  "list": [
    { "content_type": "normal", "key": "channel_dca44299", "title": "Populer" },
    { "content_type": "normal", "key": "rankings_id", "title": "Ranking" }
  ]
}
```

#### GET /hot
Daftar drama hot/populer.

**Contoh response:**
```json
{
  "hot_drama_list": [
    {
      "base_price": 50,
      "collect_count": 10692,
      "compress_cover_url": "https://p.idrama.video/...",
      "category_tag": [{ "id": 6, "tag_local": "Fantasi Ajaib" }],
      "content_tag": [{ "id": 50, "tag_local": "Werewolf" }]
    }
  ]
}
```

#### GET /search?q={query}
Cari drama. **Minimal 2 kata.**

**Error jika 1 kata:**
```json
{ "error": "Search requires at least 2 words" }
```

#### GET /tab/{key}
Konten per tab/channel.

#### GET /section/{id}
Konten per section.

### Endpoint Berbayar (401)

| Endpoint | Status |
|---|---|
| `GET /drama/{id}` | 🔑 401 |
| `GET /unlock/{id}/{ep}` | 🔑 401 |

---

## Platform 5: NetShort ✅ Browse + Detail Gratis

```
Base URL: https://netshort.goodbos.online
Auth:     Tidak diperlukan untuk browse & detail
          Butuh key untuk stream video
Default lang: id_ID (Indonesia)
```

### Endpoint Gratis

#### GET /api/home/
Daftar drama homepage.

**Contoh response:**
```json
{
  "data": {
    "contentType": 4,
    "groupId": "1894729251567251457",
    "contentName": "Semua Serial🎬",
    "contentModel": 13,
    "contentInfos": [
      {
        "shortPlayId": "2070686423515004930",
        "shortPlayLibraryId": "2070087381781188609",
        "shortPlayName": "Menebus Penyesalan Masa Lalu",
        "shortPlayLabels": ["Hidup Kembali", "Romantis Perkotaan", "Cinta dan Pernikahan"],
        "isNewLabel": true
      }
    ]
  }
}
```

**Field penting:**
- `shortPlayId` — ID episode/konten
- `shortPlayLibraryId` — ID drama (pakai untuk detail)
- `shortPlayName` — Judul
- `shortPlayLabels` / `labelArray` — Genre tags

#### GET /api/search?q={query}
Cari drama.

**Contoh response:**
```json
{
  "data": {
    "language": "id_ID",
    "searchCode": "love",
    "searchCodeSearchResult": [
      {
        "shortPlayId": "...",
        "shortPlayLibraryId": "...",
        "shortPlayName": "Main Lemah, Tapi Kuat",
        "shortPlayCover": "https://awscover.netshort.com/..."
      }
    ]
  }
}
```

#### GET /api/drama/{shortPlayLibraryId}
Detail drama lengkap.

**Contoh request:**
```
GET https://netshort.goodbos.online/api/drama/2070087381781188609
```

**Contoh response:**
```json
{
  "data": {
    "shortPlayId": "2070686423515004930",
    "shortPlayLibraryId": "2070087381781188609",
    "shortPlayName": "Menebus Penyesalan Masa Lalu",
    "shortPlayCover": "https://awscover.netshort.com/...",
    "shortPlayLabels": ["Perkotaan"],
    "payPoint": 15,
    "totalEpisode": 69,
    "onlineState": 1
  }
}
```

#### GET /api/list/{page}
Daftar drama per halaman.

**Contoh:** `/api/list/1`, `/api/list/2`

**Contoh response:**
```json
{
  "data": {
    "maxOffset": 2,
    "dataList": [
      {
        "shortPlayId": "...",
        "shortPlayLibraryId": "...",
        "shortPlayCover": "...",
        "shortPlayName": "Anak Kembar Rahasia Raja Binatang"
      }
    ]
  }
}
```

#### GET /api/categories
Daftar kategori/genre + filter region.

#### GET /api/banner
Banner/highlight drama.

#### GET /api/language
Daftar bahasa yang tersedia.

**Contoh response:**
```json
{
  "data": [
    { "code": "in", "locale": "id_ID", "name": "Indonesia" },
    { "code": "en", "locale": "en_US", "name": "English" }
  ]
}
```

### Endpoint Berbayar (401)

| Endpoint | Status |
|---|---|
| `GET /api/watch/{shortPlayId}` | 🔑 401 |

---

## Platform 6: RaptDrama ✅ Browse + Detail Gratis

```
Base URL: https://raptdrama.goodbos.online
Auth:     Tidak diperlukan untuk browse & detail
          Butuh "code" untuk stream (format: ?code=KODE)
CDN:      https://apis.raptdrama.com/
```

### Endpoint Gratis

#### GET /api/home?page={n}&lang={lang}
Daftar drama homepage dengan paginasi.

**Contoh request:**
```
GET https://raptdrama.goodbos.online/api/home?page=1&lang=en
```

**Contoh response:**
```json
{
  "code": 200,
  "data": {
    "hasMore": true,
    "items": [
      {
        "id": 2278,
        "title": "The Doctor Who Knows My Body",
        "update_time": 1772681506,
        "view": 11723,
        "image": "https://apis.raptdrama.com/public/uploads/images/.../xxx.jpg",
        "tstype": "18",
        "desc": "..."
      }
    ]
  }
}
```

**Field penting:**
- `id` — ID drama (integer, pakai untuk detail/episode)
- `title` — Judul
- `image` — URL thumbnail
- `view` — Jumlah penonton
- `tstype` — Tipe konten
- `hasMore` — Ada halaman berikutnya

#### GET /api/search?q={query}&lang={lang}
Cari drama.

**Contoh response:**
```json
{
  "code": 200,
  "data": [
    {
      "id": 1943,
      "title": "WHEN LOVE RUNS DEEP",
      "image": "https://apis.raptdrama.com/...",
      "view": 25326,
      "desc": "..."
    }
  ]
}
```

#### GET /api/detail?id={id}&lang={lang}
Detail drama lengkap.

**Contoh response:**
```json
{
  "code": 200,
  "data": {
    "id": 2242,
    "title": "Campus Memoir",
    "update_time": 1768720714,
    "view": 14820,
    "image": "https://apis.raptdrama.com/...",
    "desc": "Desire, betrayal, forbidden games..."
  }
}
```

#### GET /api/episodes?id={id}&lang={lang}
Daftar episode sebuah drama.

**Contoh response:**
```json
{
  "code": 200,
  "data": {
    "episodes": [
      {
        "id": 24393,
        "title": "Episode 1",
        "sort": 100,
        "idx": 1,
        "is_vip": "0",
        "bunny_id": "c35fde23-24dc-40e2-a547-2ceb84a4491d",
        "has_video": true
      },
      {
        "id": 24400,
        "title": "Episode 2",
        "idx": 2,
        "is_vip": "0",
        "bunny_id": "61a325c4-...",
        "has_video": true
      },
      {
        "id": 24413,
        "title": "Episode 3",
        "idx": 3,
        "is_vip": "1",
        "bunny_id": "92439a11-...",
        "has_video": true
      }
    ]
  }
}
```

**Catatan penting:**
- `is_vip: "0"` = episode gratis
- `is_vip: "1"` = episode VIP (butuh key)
- `bunny_id` = Bunny CDN video ID (dipakai di `/api/playurl`)

#### GET /api/languages
Daftar bahasa.

### Endpoint Berbayar (403)

| Endpoint | Status | Pesan Error |
|---|---|---|
| `GET /api/allepisodes?id={id}&lang={lang}` | 🔑 403 | - |
| `GET /api/playurl?id={id}&ep={n}&lang={lang}` | 🔑 403 | `"invalid or missing code"` |

**Format key:** `?code=KODE_AKSES` (berdasarkan pesan error)

---

## Platform 7: DramaBite ✅ Browse Gratis

```
Base URL: https://dramabite.goodbos.online
Auth:     Tidak diperlukan untuk browse
          Butuh "code" untuk detail & stream
```

### Endpoint Gratis

#### GET /home
Daftar drama homepage.

**Contoh response:**
```json
{
  "module_list": [
    {
      "module_id": 542,
      "module_item_list": [
        {
          "Item": {
            "VideoInfo": {
              "cid": "11912",
              "cover_url": "https://cdn-oss.miniepisode.media/episode/...",
              "desc": "..."
            }
          }
        }
      ]
    }
  ]
}
```

**Field penting:**
- `VideoInfo.cid` — ID drama
- `VideoInfo.cover_url` — Thumbnail
- `VideoInfo.desc` — Deskripsi

#### GET /search?q={query}
Cari drama.

#### GET /languages
Daftar bahasa.

### Endpoint Berbayar

| Endpoint | Status | Pesan Error |
|---|---|---|
| `GET /drama/{cid}` | ✅ 200 | Return "Acara tidak tersedia" (data kosong) |
| `GET /episodes/{cid}` | ❌ | `"invalid code"` |
| `GET /play/{cid}` | ❌ | `"invalid code"` |

**Format key:** Belum diketahui (kemungkinan `?code=` atau `Authorization: Bearer`)

---

## Platform 8: Melolo (Sebagian Gratis)

```
Base URL: https://melolo.goodbos.online
Auth:     Butuh key untuk sebagian besar endpoint
```

### Endpoint Gratis

#### GET /api/search?q={query}
Satu-satunya endpoint tanpa auth.

**Contoh response:**
```json
{
  "code": 0,
  "count": 20,
  "data": [
    {
      "author": "guoerchuanmei",
      "cover": "https://wsrv.nl/?output=jpg&url=ssl%3A...",
      "episodes": 79,
      "id": "7632237702196235317",
      "intro": "..."
    }
  ]
}
```

### Endpoint Berbayar (401)

| Endpoint | Status |
|---|---|
| `GET /api/home` | 🔑 401 |
| `GET /api/video` | 🔑 401 |
| `GET /api/detail/{id}` | 🔑 401 |

---

## Platform 9: DramaBox 🔑 Semua Berbayar

```
Base URL: https://dramabox.goodbos.online
Auth:     ?code=KODE_AKSES (wajib semua endpoint)
```

### Endpoint (semua butuh auth)

| Endpoint | Keterangan |
|---|---|
| `GET /api/v1/homepage?page={n}&lang={lang}&code={code}` | Daftar drama |
| `GET /api/v1/search?q={q}&lang={lang}&code={code}` | Cari drama |
| `GET /api/v1/detail?id={id}&lang={lang}&code={code}` | Detail drama |
| `GET /api/v1/allepisode?id={id}&lang={lang}&code={code}` | Semua episode |
| `GET /api/v1/latest?lang={lang}&code={code}` | Drama terbaru |
| `GET /api/v1/foryou?lang={lang}&code={code}` | Rekomendasi |
| `GET /api/v1/dubbed?lang={lang}&code={code}` | Drama dubbing |

**Format auth:** Semua endpoint pakai `?code=KODE_AKSES`

---

## Platform 10: ShortMax 🔑 Semua Berbayar

```
Base URL: https://shortmax.goodbos.online
Auth:     Butuh key semua endpoint
```

### Endpoint (semua butuh auth)

| Endpoint | Keterangan |
|---|---|
| `GET /api/v1/hot` | Drama populer |
| `GET /api/v1/new` | Drama terbaru |
| `GET /api/v1/popular` | Drama trending |
| `GET /api/v1/ranking` | Ranking drama |
| `GET /api/v1/search?q={q}` | Cari drama |
| `GET /api/v1/detail/{code}` | Detail drama |
| `GET /api/v1/alleps/{code}` | Semua episode |
| `GET /api/v1/category/{id}` | Filter kategori |
| `GET /api/v1/vip` | Konten VIP |
| `GET /api/v1/languages` | Daftar bahasa |

---

## Platform 11: PineDrama 🔑 Semua Berbayar

```
Base URL: https://pinedrama.goodbos.online
Auth:     Butuh key semua endpoint
```

### Endpoint Gratis

| Endpoint | Status |
|---|---|
| `GET /language` | ✅ 200 |

**Response `/language`:**
```json
{
  "available": [
    { "code": "id", "name": "Indonesia" },
    { "code": "en", "name": "English" },
    { "code": "th", "name": "ไทย" }
  ]
}
```

### Endpoint Berbayar

| Endpoint | Status |
|---|---|
| `GET /home` | 🔑 401 |
| `GET /search?q={q}` | ❌ 403 |
| `GET /category` | 🔑 401 |
| `GET /detail` | 🔑 401 |
| `GET /episode` | 🔑 401 |

---

## Cara Mendapatkan Key

Semua platform yang butuh auth menggunakan key dari owner yang sama.

1. Buka Telegram: [@nanomilkisbot](https://t.me/nanomilkisbot)
2. Pilih paket (Rp 40.000 – Rp 129.000)
3. Bayar via QRIS/transfer
4. Dapat `KODE_AKSES`

Format penggunaan per platform:
- DramaBox, GoodShort, RaptDrama: `?code=KODE_AKSES`
- Melolo, ShortMax, PineDrama: kemungkinan sama `?code=KODE_AKSES`
- api.dramabuzz.sbs: `?key=KODE_AKSES` atau `X-Api-Key: KODE_AKSES`

---

## Rekomendasi untuk Web Gratis

Berdasarkan hasil rekon, kombinasi platform yang bisa dipakai **100% gratis** untuk website drama:

### Opsi 1: GoodShort Only (Paling Simple)
```
Browse: GoodShort /home → dapat drama list + bookId
Stream: GoodShort /episode/?bookId=X&ep=N → HLS M3U8 ✅
```
**Pro:** Full stack gratis, stream langsung
**Con:** Tidak ada search

### Opsi 2: ReelShort (Browse+Search) + GoodShort (Stream)
```
Browse:  ReelShort /home → drama list
Search:  ReelShort /search?q=X → hasil pencarian
Stream:  GoodShort /episode/?bookId=X&ep=N → HLS ✅
```
**Masalah:** ID drama ReelShort ≠ ID GoodShort (beda platform)

### Opsi 3: NetShort (Browse+Detail) + GoodShort (Stream)
```
Browse:  NetShort /api/home/ → list + ID drama
Detail:  NetShort /api/drama/{id} → info lengkap
Stream:  GoodShort /episode/?bookId=X&ep=N → HLS ✅
```
**Masalah:** Sama — ID NetShort ≠ ID GoodShort

### Opsi 4: RaptDrama (Browse+Detail+Episode List) + butuh key untuk stream
```
Browse:  RaptDrama /api/home?page=1&lang=en
Search:  RaptDrama /api/search?q=X&lang=en
Detail:  RaptDrama /api/detail?id=X&lang=en
Episodes: RaptDrama /api/episodes?id=X&lang=en → dapat list ep + is_vip
Stream:  ❌ /api/playurl butuh code
```
**Best untuk UI** — paling lengkap data gratis, tinggal butuh key untuk stream

---

## Kesimpulan

| Yang benar-benar gratis | Yang butuh beli key |
|---|---|
| GoodShort (browse + stream) | DramaBox, ShortMax, PineDrama (semua) |
| FlickReels (browse only) | ReelShort, iDrama, NetShort (stream) |
| ReelShort (browse + search) | RaptDrama, DramaBite, Melolo (stream) |
| iDrama (browse + search) | api.dramabuzz.sbs (semua) |
| NetShort (browse + detail) | |
| RaptDrama (browse + detail + ep list) | |
| DramaBite (browse) | |
| Melolo (search only) | |

**Satu-satunya yang bisa full browse dan stream gratis: GoodShort**
