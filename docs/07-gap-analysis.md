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

## 7.3 Bagian PRD di luar daftar kriteria

| PRD | Status | Catatan |
|---|---|---|
| §2 Backend Golang (Gin/Fiber) | **Belum** | Tidak ada folder backend sama sekali |
| §2 Supabase + PostgreSQL + Auth | **Ditunda, skema siap** | Keputusan 14 Nov: lokal dulu. `db/001_init.sql` berisi tabel, indeks, RLS, dan fungsi `award_stardust`; sudah diuji parse terhadap PostgreSQL 16 asli |
| §3 SF Pro Rounded / Display | **Sebagian** | Hanya resolve di iOS. Android jatuh ke font sistem — [#7](06-open-questions.md) belum dijawab |
| §3 Frosted glass di semua kartu | **Sebagian, disengaja** | Dipakai di layar AR dengan `BackdropGroup`. Dicabut dari tab bar karena terukur memakan 10 ms di frame terburuk |
| §3 Squircle & kapsul | **Selesai** | `RoundedSuperellipseBorder` + `StadiumBorder` |
| §3 Haptic di setiap interaksi | **Selesai** | `SpringTap` membawa haptic ke semua elemen yang bisa ditekan |
| §3 Spring di semua transisi | **Selesai** | Tidak ada `Curves.linear` yang terlihat pengguna |
| §5 Tabel `users` | **Padanan lokal** | Tabel `profile` satu baris memegang `stardust_energy`. Tanpa `user_id` sampai auth ada |
| §5 Tabel `constellations` | **Selesai lokal** | Tabel SQLite dengan indeks `(created_at DESC, id DESC)` untuk paginasi keyset |
| §5 Tabel `focus_sessions` | **Selesai lokal** | Ditulis saat sesi tuntas |

## 7.4 Di luar PRD, tapi akan menagih

| Hal | Kenapa penting |
|---|---|
| Manajemen state | Masih `setState` per layar. `_stardust` sudah terduplikasi di dua file — gejala awal |
| Jalan ke Pengaturan saat izin ditolak permanen | Onboarding sudah menjelaskan sebelum izin diminta, tapi kalau pengguna menolak permanen belum ada tombol menuju Pengaturan |
| Kebijakan privasi | Kamera + GPS selalu aktif ([#15](06-open-questions.md)) |
| Nama & desain maskot sendiri | "Nova" masih placeholder ([#17](06-open-questions.md)) |

---

## 7.5 Urutan kerja yang disarankan

Diurutkan menurut apa yang membuka jalan bagi yang lain, bukan menurut besarnya.

| # | Pekerjaan | Membuka | Terhalang oleh |
|---|---|---|---|
| ~~1~~ | ~~Timer hitung mundur~~ | — | **Selesai 14 Nov** |
| ~~2~~ | ~~Penyimpanan lokal + onboarding~~ | — | **Selesai 14 Nov** |
| ~~3~~ | ~~Dark mode~~ | — | **Selesai 14 Nov** |
| 1 | **Jawab open questions #1–#6** | 5 kriteria AR | Keputusan produk, bukan kode |
| 2 | **Manajemen state terpusat** | Menghentikan duplikasi `_stardust` sebelum menyebar | Tidak ada |
| 3 | **Jalan ke Pengaturan saat izin ditolak permanen** | AR bisa dipulihkan tanpa reinstall | Tidak ada |
| 4 | **AR sungguhan (ARKit/ARCore)** | 4.1 dan 4.2 sepenuhnya | #1–#4 |
| 5 | **Backend Golang + Supabase** | 4.3, sinkron antar perangkat | Pilihan API radar (#5) |
| 6 | **Astro-Transit** | — | #6, #7, GPS |
| 7 | **Lo-fi player** | — | Lisensi musik (#16) |
| 8 | **Maskot 3D** | — | Desain karakter (#17) |

Nomor 2 dan 3 adalah satu-satunya pekerjaan yang **tidak terhalang apa pun**. Sisanya menunggu
keputusan produk, bukan menunggu kode.

---

## 7.6 Yang dihapus pada 14 November 2026

Pembersihan elemen yang tidak bisa dilacak ke PRD.

| Dihapus | Asal | Alasan |
|---|---|---|
| Kategori fokus (Study / Work / Creative / Reading) | Gambar referensi Foku | Tidak ada di PRD. Enum `FocusCategory`, kartu "What are you focusing on?", dan 4 kunci l10n ikut dihapus |
| Kartu "Tonight above you" (4 planets visible, 2 transits overhead) | Karangan sendiri | Angkanya tidak bersumber dari apa pun — tidak ada GPS, tidak ada API radar. Menampilkan data palsu seolah nyata |
| Tab Profile beserta layarnya | Karangan sendiri | PRD §4.4 meminta **indikator status**, bukan layar profil. Fungsinya pindah ke kartu Stardust di layar Langit |
| Angka hardcode `340` / `12` / `185` | Karangan sendiri | Diganti nilai nyata dari `StardustStore` dan `ConstellationStore` |
| `SoftProgressBar` lurus untuk Stardust | Salah baca PRD | PRD meminta progress bar **melengkung**. Diganti `CurvedProgressBar` |

Navigasi menyusut dari 4 tab menjadi 3: Langit, Rasi, Fokus — satu per fitur PRD yang punya layar.
Fitur 4.3 Astro-Transit belum punya tab karena belum dibangun.

---

## 7.7 Dark mode — dibangun 14 November 2026

Bukan salah satu dari 27 kriteria, tapi tercatat di §7.4 sebagai utang yang akan menagih. Sekarang
lunas.

| Bagian | Hasil |
|---|---|
| Sumber warna | `AppColor` dibubarkan. Seluruh warna pindah ke `AppPalette` (`ThemeExtension`) dengan instance `light` dan `dark` |
| Perpindahan | Diinterpolasi lewat `lerp`, 360 ms `easeInOutCubic`. Tidak berkedip |
| Pilihan pengguna | Ikut sistem (bawaan) / terang / gelap, diputar lewat tombol di header Langit, tersimpan di `profile.theme_mode` (migrasi SQLite v3) |
| Status bar | `AnnotatedRegion` mengikuti tema; layar AR memaksa ikon terang karena ia selalu hitam |
| Permukaan yang tidak ikut tema | Layar AR, lapisan gambar rasi, galat kamera — semuanya memakai `AppNight` |
| Penjagaan kontras | 34 pasangan warna diperiksa terhadap WCAG AA di setiap `flutter test` |

Tiga token **berbalik** antar tema, tidak sekadar digelapkan: tombol utama, pemisah kartu, dan chip
terpilih. Alasannya ada di [03-design-system.md §3.1](03-design-system.md).

**Cacat yang ikut tertangkap.** Tes kontras baru itu langsung menemukan kesalahan di tema **terang**
yang lolos dari audit Apple manual sebelumnya: `accentStrong` lama `#5C8EE6` hanya **2,997:1** di
latar sekunder `#F4F6F8`, sementara ambang ikon non-teks adalah 3:1. Audit sebelumnya menghitungnya
terhadap putih (3,25:1) dan tidak memeriksa latar sekunder, padahal ikon empty-state daftar rasi dan
titik indikator onboarding digambar di sana. Diganti `#5687DC`: 3,29:1 di latar sekunder, 3,56:1 di
kartu putih, 3,11:1 di `accentWash`.

**Status pengujian:** 107 tes lolos (57 sebelumnya + 41 kontras + 7 mode tema + 2 destructive),
`flutter analyze` bersih.

### Diverifikasi di aplikasi berjalan, bukan hanya di tes

Emulator akhirnya bisa dijalankan setelah disk dibersihkan pada 14 November. Penyebab ia gagal
sebelumnya ada dua, dan keduanya sudah dicatat agar tidak mengulang pencarian: disk penuh, lalu
renderer software `swiftshader_indirect` yang **segfault** saat boot. Perintah yang berhasil:

```
emulator -avd iphone_13 -no-window -gpu host -memory 2048 -no-audio
```

Yang terbukti jalan di Android 14 (1170x2532), bukan sekadar lolos tes:

| Diperiksa | Hasil |
|---|---|
| Onboarding peluncuran pertama | Tampil, maskot diam saat teks berganti, Lewati bekerja |
| Tema terang dan gelap di tiga tab | Benar. Tombol utama berbalik, kartu dapat tepi, ikon status bar ikut |
| Pilihan tema bertahan | Tutup paksa lalu buka lagi: tetap gelap, onboarding tidak muncul lagi. Migrasi SQLite v3 bekerja |
| Portal AR | Terbuka penuh, starfield dan pita Bima Sakti tampil, petunjuk berganti ke "Tap the city lights" |
| Preview kamera | Memenuhi layar. Umpan emulator memang rusak — aplikasi kamera **bawaan Android** menampilkan kerusakan yang sama, jadi itu emulatornya, bukan kode kita |

Tangkapan layarnya ada di [screenshots/](screenshots/).

**Yang masih belum terverifikasi di perangkat nyata:** menggambar rasi di atas umpan kamera
sungguhan, hapus-geser, dan ganti nama. Umpan kamera emulator terlalu rusak untuk menguji
penempatan node, dan itu memang pekerjaan untuk ponsel fisik.

---

## 7.8 Cakrawala dari sensor — dibangun 14 November 2026 sore

PRD §4.1 meminta langit siang diganti Bima Sakti, dan orb melayang stabil terhadap dunia. Keduanya
tercatat **Sebagian** karena portal menutupi seluruh lingkaran — termasuk gedung dan tanah — dan orb
terkunci di tengah layar.

Keduanya butuh satu hal yang sama: ponsel harus tahu di mana atas. Itu tidak memerlukan ARKit atau
ARCore. Akselerometer mengukur arah gravitasi, jadi **sudut elevasi bersifat absolut dan tidak
hanyut**.

| Dibangun | Isi |
|---|---|
| `lib/ar/sky_attitude.dart` | `skyElevation()` — elevasi kamera dari satu pembacaan akselerometer. `horizonY()` — posisi cakrawala di layar lewat model pinhole. `SkyAttitude` — aliran sensor yang dilicinkan low-pass |
| Langit sadar cakrawala | `_NightSkyPainter` hanya mengisi di atas garis cakrawala, dengan gradasi 90 pt di pertemuannya. Bintang dan Bima Sakti tertambat ke pita langit setinggi 3x layar, jadi ikut bergeser saat ponsel dimiringkan |
| Orb tertambat tegak | Orb tetap di titik langit yang sama saat ponsel diangguk, dibatasi 34% tinggi layar supaya selalu bisa dijangkau jari |
| Paket baru | `sensors_plus: ^7.1.1` — satu-satunya dependensi yang ditambahkan |

### Yang sengaja tidak dibangun

**Arah mata angin tidak dipalsukan.** Memutar badan ke kiri atau kanan tidak terbaca akselerometer.
Giroskop bisa diintegrasikan untuk menebaknya, tapi hasilnya hanyut beberapa derajat per menit —
bentuk rasi yang sudah digambar akan merayap pelan dari tempatnya, dan itu lebih buruk daripada
jujur terkunci ke layar. Sumbu itu menunggu world tracking sungguhan
([#1–#4](06-open-questions.md)).

### Biaya performa yang belum diukur di perangkat nyata

Painter sekarang memakai satu `saveLayer` untuk gradasi cakrawala dan menggambar 520 bintang, naik
dari 220. Untuk menahan biayanya, `SkyAttitude` hanya memberi tahu pendengar saat elevasi berubah
lebih dari ~0,7 derajat, jadi raster cache langit tetap berguna selama ponsel relatif diam. Angka
frame di perangkat nyata **belum diukur** — emulator memakai vsync-nya sendiri sehingga angkanya
tidak mewakili.

### Diverifikasi di emulator dengan sensor palsu

`adb emu sensor set acceleration x:y:z` memberi nilai akselerometer apa pun, jadi keempat sikap bisa
diuji sungguhan:

| Sikap | Nilai | Hasil |
|---|---|---|
| Tegak, kamera di cakrawala | `0:9.81:0` | Garis cakrawala di tengah layar, langit di atas, gedung di bawah |
| Menengadah 30° | `0:8.496:-4.905` | Cakrawala turun ke ~85% layar, langit mengisi hampir semuanya |
| Menunduk 30° | `0:8.496:4.905` | Cakrawala naik, langit menyusut |
| Menghadap tanah 80° | `0:1.7:9.66` | **Nol langit** — umpan kamera utuh, cabang `line <= 0` bekerja |

Tangkapan layarnya ada di [screenshots/](screenshots/) nomor 06 sampai 09.

**Pengujian:** 23 tes baru di `sky_attitude_test.dart` — matematika elevasi (termasuk jatuh bebas dan
sudut ekstrem), monotonitas `horizonY`, serta perilaku pelicin, ambang derau, tenggat sensor, dan
langganan ganda. Total **130 tes lolos**, `flutter analyze` bersih.

---

## 7.9 Penangkap bintang dan pelurusan navigasi — 14 November 2026 malam

Dua pekerjaan setelah pengujian pertama di ponsel sungguhan.

### Fokus turun dari navbar

Pengguna bertanya kenapa ada fitur fokus, dan pertanyaan itu sah: Fokus berdiri
sebagai tab setara, sehingga terbaca seperti aplikasi timer belajar yang nyempil
di aplikasi astronomi.

Fiturnya sendiri **ada di PRD** — [01-product-vision.md](01-product-vision.md)
menempatkan Constella di persimpangan tiga kategori, salah satunya *"Focus /
mindfulness app — tetapi hadiahnya adalah eksplorasi dunia nyata"*, dan
[§4.4](04-features-mvp.md) menyebut *"Tombol 'Start focus session' memulai timer
dan masuk ke mode Malam Kosmik"*.

Yang salah adalah penempatannya, dan itu kesalahan implementasi, bukan
kesalahan PRD. Sekarang navbar berisi **Langit, Bintang, Rasi**, dan sesi fokus
menjadi pintu kedua menuju portal yang sama dari layar Langit.

### Penangkap bintang (fitur baru, §4.5)

Lihat [04-features-mvp.md §4.5](04-features-mvp.md) untuk rinciannya.

| Bagian | Isi |
|---|---|
| Katalog | 1.637 bintang sampai magnitudo 5,0 dari HYG Database, 69 KB, dibundel |
| Matematika | Hari Julian, waktu sideris, ekuatorial ke horizontal, jarak sudut |
| Orientasi | Kompas terkompensasi kemiringan dari akselerometer dan magnetometer |
| Lokasi | `geolocator`, akurasi rendah, izin **lokasi perkiraan** saja |
| Pencocokan | Bintang terdekat dari arah bidik, dengan bobot keterangan |

**Yang berhasil dibuktikan di emulator:** pembacaan kompas menunjukkan `N 0° 23°`
persis sesuai nilai akselerometer dan magnetometer yang disuntikkan. Matematika
orientasinya benar di perangkat, bukan hanya di tes.

**Yang tidak bisa dibuktikan di emulator:** GPS AVD ini mati total —
`dumpsys location` melaporkan `last location=null` bahkan di tingkat sistem,
sehingga tidak ada aplikasi yang bisa mendapat posisi di sana. Jalur gagalnya
justru terbukti bekerja: pesan jelas plus tombol coba lagi, bukan layar kosong.
Identifikasi bintangnya dibuktikan lewat tes widget yang menyuntikkan posisi dan
arah bidik yang diketahui.

### Dua bug yang tertangkap, keduanya oleh tes

1. **Kompas membeku saat langit kosong.** `_match` keluar lebih awal tanpa
   membangun ulang, jadi pembacaan arah di atas layar berhenti di angka lama
   padahal ponsel digerakkan. Ditemukan saat tes widget pertama kali gagal.
2. **`CurvedProgressBar` meluap pada teks 200 persen.** Kotaknya bertinggi
   tetap sementara angka di tengahnya ikut membesar mengikuti Dynamic Type.
   Bug ini **sudah lama ada** tapi tidak pernah terlihat: kartu Stardust berada
   di bawah lipatan layar, dan `ListView` tidak pernah membangunnya. Baru muncul
   ketika tes menggulir ke bawah untuk meraih tombol sesi fokus.

### Penambahan dependensi

`geolocator: ^14.1.2`. Build Android dan paketnya diuji sebelum kode fiturnya
ditulis, supaya kalau gagal bisa dicabut tanpa membuang pekerjaan.

**Pengujian:** 182 tes lolos — 30 matematika langit, 15 katalog, 7 layar
penangkap bintang, sisanya yang sudah ada. `flutter analyze` bersih.
