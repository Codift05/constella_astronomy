# 7. Gap Analysis — PRD vs Kode

**Tanggal:** 14 November 2026
**Dasar:** 27 kriteria penerimaan di [04-features-mvp.md](04-features-mvp.md), diperiksa langsung terhadap kode di `app/lib/`.

## Ringkasan

| | 13 Nov | 14 Nov pagi | 14 Nov siang | 14 Nov sore | Porsi |
|---|---|---|---|---|---|
| Selesai | 7 | 10 | 14 | **15** | 56% |
| Sebagian | 7 | 6 | 4 | **3** | 11% |
| Belum | 13 | 11 | 9 | **9** | 33% |

Perubahan 14 November: timer hitung mundur dibangun, Stardust Energy jadi nyata, progress bar
melengkung dibuat, penyimpanan SQLite lokal masuk, onboarding dibangun, dark mode dibangun, dan
seluruh elemen non-PRD dihapus (lihat §7.6).

Yang sudah jalan adalah **lapisan interaksi dan lapisan simpan**: gestur, animasi, haptic, navigasi,
aksesibilitas, dua tema, dan data yang bertahan setelah aplikasi ditutup. Yang belum adalah
**lapisan dunia nyata**: tidak ada AR sungguhan, tidak ada GPS, tidak ada backend. Angka yang
tampil di layar kini berasal dari database, bukan dari kode — kecuali posisi planet, yang memang
belum ada sumbernya.

Satu kalimat: aplikasi ini sudah terasa benar dan sudah ingat, tapi belum tahu apa-apa tentang
langit di atasnya.

---

## 7.1 Yang paling perlu diluruskan lebih dulu

**Yang dibangun bukan AR, melainkan kamera dengan lapisan 2D di atasnya.**

PRD §2 menyebut `arkit_plugin` (iOS) dan `arcore_flutter_plugin` (Android). Keduanya tidak dipakai;
`pubspec.yaml` hanya memuat `camera: ^0.12.2`. Konsekuensinya nyata, bukan sekadar soal nama paket:

| Yang hilang tanpa ARKit/ARCore | Akibat yang terlihat pengguna |
|---|---|
| World tracking | Orb menempel di tengah layar, ikut bergerak saat ponsel digeser. PRD meminta orb "melayang" di satu titik ruang |
| Anchor spasial | Node rasi bintang memakai koordinat layar. Begitu kamera bergeser, bentuknya ikut bergeser |
| Scene semantics / sky segmentation | Portal mengganti **seluruh** lingkaran jadi langit malam, termasuk gedung dan tanah, bukan hanya langit |
| Depth | Tidak bisa membedakan lampu jauh dari lampu dekat |

Ini satu akar yang menjelaskan 5 dari 13 kriteria yang belum selesai. Memutuskan
[open questions #1–#4](06-open-questions.md) adalah pekerjaan pertama, bukan menulis kode lagi.

---

## 7.2 Per fitur

### 4.1 AR Time-Bubble — 4 selesai, 2 sebagian, 1 belum

| Kriteria | Status | Bukti / yang kurang |
|---|---|---|
| Orb melayang stabil relatif terhadap dunia | **Sebagian** | Sumbu tegak sudah tertambat: memiringkan ponsel ke atas-bawah membuat orb tetap di titik langit yang sama, dihitung dari akselerometer sehingga tidak hanyut. Arah mata angin **belum** — memutar badan masih membawa orb ikut serta, dan itu hanya bisa diselesaikan world tracking AR |
| Tap orb → ekspansi spring | **Selesai** | `SpringSimulation` dengan `AppSpring.portal` |
| Haptic berat saat portal penuh | **Selesai** | `_onPortalTick` memicu `heavyImpact` di ambang 0,98 |
| Langit siang diganti Bima Sakti | **Selesai** | `_NightSkyPainter` kini sadar cakrawala: hanya bagian di atas garis cakrawala yang diganti, dengan gradasi 90 pt supaya pertemuannya tidak berupa garis keras. Gedung di bawah cakrawala tetap terlihat. **Batasnya:** cakrawalanya geometris, bukan hasil segmentasi — gedung yang menjulang di atas garis itu tetap tertutup langit |
| Posisi planet sesuai waktu + GPS | **Belum** | 3 planet dengan koordinat tetap di `cosmic_night_screen.dart:506`. Tidak ada GPS di seluruh proyek |
| Portal bisa ditutup dan dibuka ulang | **Selesai** | `_togglePortal` dua arah, tanpa restart sesi kamera |
| Fallback saat perangkat tidak mendukung | **Sebagian** | Ada penanganan kamera ditolak/tidak ada + timeout 8 detik. Belum ada deteksi kemampuan sky replacement, karena fiturnya memang belum ada |

### 4.2 Skyline Constellations — 4 selesai, 1 sebagian, 1 belum

| Kriteria | Status | Bukti / yang kurang |
|---|---|---|
| Node otomatis pada sumber cahaya ekstrem | **Belum** | Node ditaruh manual lewat ketukan. Butuh deteksi titik terang atau scene semantics |
| Garis mengikuti jari, mengunci ke node | **Selesai** | `ConstellationLayer` + `ConstellationDraft.nodeAt`, radius 36 pt |
| Haptic ringan tiap node tersambung | **Selesai** | `lightImpact` pada `_handlePanEnd` |
| Kartu glass berisi label landmark | **Sebagian** | Kartunya ada, tapi namanya diketik pengguna. PRD meminta label landmark hasil deteksi, misal "Jembatan Kota" |
| `node_coordinates` tersimpan dan dimuat ulang sesi berikutnya | **Selesai** | SQLite lokal, paginasi keyset. Belum sampai Supabase — lihat `db/001_init.sql` |
| Rasi bisa dihapus atau diberi nama ulang | **Selesai** | Geser baris untuk hapus (dengan konfirmasi), ketuk untuk ganti nama |

### 4.3 Astro-Transit — 0 dari 6

Belum ada satu baris pun. Yang dibutuhkan:

| Kriteria | Prasyarat yang belum ada |
|---|---|
| Pesawat dari API radar berdasarkan GPS | Pilihan API radar ([#5](06-open-questions.md)), izin lokasi, paket geolokasi |
| Ekor partikel stardust 3D | Mesin partikel; `CustomPainter` 2D tidak cukup |
| Rute + ETA di Dynamic Island | Modul Swift dengan ActivityKit ([#8](06-open-questions.md)) |
| Padanan pill melayang di Android | Notifikasi foreground service |
| Tetap aman saat API gagal | Lapisan jaringan belum ada |
| API key tidak pernah sampai ke klien | Backend Golang belum ada |

### 4.4 Gamification, Mascot & Focus Timer — 7 selesai, 1 belum

| Kriteria | Status | Bukti / yang kurang |
|---|---|---|
| Maskot melayang + merespons tap | **Selesai** | `CosmicMascot`, animasi idle 3 detik, `SpringTap`. Catatan: PRD minta karakter **3D**, ini masih `CustomPainter` 2D |
| Speech bubble memandu onboarding | **Selesai** | 4 langkah dengan maskot tetap di tempat; langkah terakhir menjelaskan kamera sebelum sistem meminta izin. Bertahan di tabel `profile` |
| Chip durasi + angka besar | **Selesai** | 7 preset, stepper ±5 menit, batas 5–120, 4 unit test |
| Tombol memulai timer dan masuk Malam Kosmik | **Selesai** | `FocusSession.start()` lalu push `CosmicNightScreen(session:)`; pil hitung mundur dengan jeda dan menyerah |
| Sesi tersimpan ke `focus_sessions` | **Selesai** | Ditulis ke tabel `focus_sessions` di SQLite saat sesi tuntas. Belum sampai Supabase |
| Stardust bertambah + progress bar **melengkung** + spring | **Selesai** | `StardustStore.completeSession` menambah energy; `CurvedProgressBar` busur 240 derajat dengan `Curves.elasticOut`. Besaran hadiahnya masih placeholder 1 per menit ([#10](06-open-questions.md)) |
| Lo-fi player | **Belum** | Tidak ada paket audio di `pubspec.yaml` |
| Timer akurat saat aplikasi di background | **Selesai** | Sisa waktu dihitung dari jam dinding, bukan akumulasi tick. 8 unit test di `focus_session_test.dart` |

---
