# 4. Core Features & Acceptance Criteria (MVP)

Acceptance criteria diturunkan dari mekanik yang ditulis di PRD asli. Baris yang ditandai *(turunan)* adalah interpretasi yang perlu konfirmasi product owner.

---

## 4.1 AR Time-Bubble (Malam Kosmik)

**Deskripsi:** Portal spasial AR yang menimpa tangkapan kamera siang hari menjadi malam tata surya.

### Mekanik & UI
- Sebuah orb bercahaya di-render melayang di tengah layar kamera.
- Saat orb diklik, animasi spring melebarkan orb menjadi portal bundar raksasa.
- Di dalam portal, *sky replacement* diterapkan untuk memunculkan Bima Sakti dan posisi planet real-time.

### Acceptance Criteria
- [ ] Orb muncul dan melayang stabil relatif terhadap dunia, bukan menempel di layar.
- [ ] Tap pada orb memicu ekspansi dengan spring physics, bukan kurva linear.
- [ ] Haptic berat sekali saat portal mencapai ukuran penuh.
- [ ] Di dalam portal, langit siang diganti Bima Sakti.
- [ ] Posisi planet di dalam portal sesuai waktu dan koordinat GPS pengguna. *(turunan: toleransi akurasi perlu ditetapkan)*
- [ ] Portal bisa ditutup dan dibuka ulang tanpa restart sesi AR. *(turunan)*
- [ ] Ada fallback saat perangkat tidak mendukung sky replacement. *(turunan — lihat `06-open-questions.md`)*

---

## 4.2 Skyline Constellations (Rasi Bintang Kota)

**Deskripsi:** Pengguna dapat menggambar rasi bintang dari lampu-lampu kota (landmark) yang terdeteksi.

### Mekanik & UI
- Sistem melabuhkan node (titik neon) pada sumber cahaya ekstrem di kejauhan.
- Pengguna menggunakan gestur swipe/pan untuk menarik garis neon antar node.
- Setelah tersambung, muncul kartu glassmorphism melayang berisi label landmark (misalnya "Jembatan Kota").
- Koordinat bentuk dikirim ke backend Supabase.

### Acceptance Criteria
- [ ] Node otomatis terpasang pada titik cahaya terang yang terdeteksi kamera.
- [ ] Garis neon mengikuti jari saat pan, dan mengunci ke node terdekat saat dilepas.
- [ ] Haptic ringan setiap kali satu node tersambung.
- [ ] Kartu glassmorphism berisi label landmark muncul setelah bentuk tersambung.
- [ ] `node_coordinates` tersimpan ke tabel `constellations` dan bisa dimuat ulang di sesi berikutnya.
- [ ] Rasi bintang bisa dihapus atau diberi nama ulang oleh pemiliknya. *(turunan)*

---

## 4.3 Astro-Transit (Live Tracking Komet)

**Deskripsi:** Mengubah pesawat atau kapal laut yang lewat menjadi objek komet atau bintang jatuh.

### Mekanik & UI
- Mengonsumsi API radar pihak ketiga berdasarkan GPS pengguna.
- Menambahkan layer partikel 3D stardust di ekor pesawat yang terdeteksi kamera.
- **Dynamic Island Integration:** informasi rute dan ETA dirender memanjang dari Dynamic Island (iOS) atau sebagai notifikasi pill melayang (Android).

### Acceptance Criteria
- [ ] Pesawat dalam radius tertentu dari GPS pengguna terambil dari API radar. *(turunan: radius dan interval refresh perlu ditetapkan)*
- [ ] Ekor partikel stardust menempel pada posisi pesawat di viewport kamera.
- [ ] Rute dan ETA tampil di Dynamic Island pada perangkat iOS yang mendukungnya.
- [ ] Android menampilkan padanan berupa pill melayang.
- [ ] Aplikasi tetap berfungsi tanpa crash saat API radar gagal atau tidak punya data di wilayah itu.
- [ ] API key radar tidak pernah dikirim ke klien — semua request lewat backend Golang.

---

## 4.4 Gamification, Mascot & Focus Timer

**Deskripsi:** Integrasi elemen produktivitas dan relaksasi bergaya soft UI.

### Mekanik & UI
- **Cosmic Mascot:** karakter pendamping 3D bergaya soft (mirip maskot Foku pada referensi) yang melayang interaktif dan memberi panduan onboarding lewat speech bubble.
- **Focus Session Timer:** layar pengaturan sesi dengan angka besar dan opsi menit (5m, 10m, 25m) dalam bentuk chip button biru pastel, serta tombol kapsul Navy "Start focus session" untuk memulai mode Malam Kosmik.
- **Lo-Fi Player:** pemutar audio mini di atas Home Indicator dengan instrumen ambient atau lo-fi.
- **Status Bar:** indikator pengumpulan poin eksplorasi (Stardust Energy) dengan progress bar melengkung yang bersih.

### Acceptance Criteria
- [ ] Maskot melayang dengan animasi idle dan merespons tap.
- [ ] Speech bubble memandu pengguna baru melewati onboarding.
- [ ] Chip durasi (5m, 10m, 15m, 25m, 30m, 45m, 60m) bisa dipilih, dan nilai terpilih tampil sebagai angka besar.
- [ ] Tombol "Start focus session" memulai timer dan masuk ke mode Malam Kosmik.
- [ ] Sesi yang selesai tersimpan ke tabel `focus_sessions`.
- [ ] Stardust Energy bertambah setelah sesi selesai, dan progress bar melengkung ikut bergerak dengan spring animation.
- [ ] Lo-fi player bisa play, pause, dan ganti track; audio tetap jalan saat layar AR aktif. *(turunan)*
- [ ] Timer tetap akurat saat aplikasi di background. *(turunan)*

---

## 4.5 Star Catcher (Penangkap Bintang)

**Ditambahkan 14 November 2026, di luar PRD awal.** Dicatat terpisah supaya
jelas bahwa ini permintaan baru, bukan tafsir bebas atas dokumen lama.

**Deskripsi:** Kamera dengan bidikan di tengah layar. Arahkan ke sebuah bintang,
bidikan mengunci, lalu kartu datanya meluncur masuk.

### Kenapa ini cocok

Prinsip desain nomor satu di [01-product-vision.md](01-product-vision.md)
berbunyi *"Dunia nyata adalah kanvas."* Fitur ini mengambil bintang yang
benar-benar ada di atas pengguna dan memberinya nama. Visi produk juga sudah
menempatkan Constella sebagai *stargazing app* — "tetapi tidak berhenti di data
astronomi". Penangkap bintang mengisi sisi itu tanpa menggeser inti AR-nya.

### Mekanik & UI
- Bidikan melingkar di tengah layar kamera, berubah warna dan mengecil saat
  mengunci sebuah bintang, disertai haptic ringan.
- Pembacaan kompas kecil di atas layar: arah mata angin, azimut, dan ketinggian.
- Kartu kaca di bawah: nama bintang, rasi, jarak dalam tahun cahaya, magnitudo,
  tipe spektral, dan ketinggiannya di atas ufuk.
- Jarak sudut dari titik bidik ditampilkan, supaya pengguna tahu seberapa tepat
  bidikannya.

### Dari mana datanya

**Bukan dari API NASA.** Tidak ada layanan NASA yang bisa ditanya "bintang apa
yang sedang saya tunjuk" — identifikasi bintang memakai katalog statis. Constella
membundel 1.637 bintang sampai magnitudo 5,0, disaring dari
[HYG Database](https://github.com/astronexus/HYG-Database) yang berbasis
Hipparcos, Yale Bright Star, dan Gliese. Ukurannya 69 KB.

Dibundel, bukan diambil dari jaringan, karena fitur ini dipakai di atap pada
malam hari: sinyal sering buruk dan jawabannya harus seketika.

### Acceptance Criteria
- [x] Bidikan di tengah layar kamera mengunci bintang terdekat dari arah bidik.
- [x] Kartu data muncul dengan transisi meluncur, bukan berkedip.
- [x] Nama, rasi, jarak, magnitudo, dan tipe spektral ditampilkan.
- [x] Seluruhnya bekerja tanpa jaringan.
- [x] Izin yang diminta hanya lokasi **perkiraan**, bukan presisi.
- [x] Perangkat tanpa magnetometer mendapat penjelasan, bukan layar kosong.
- [x] Layar menjelaskan dirinya sendiri saat belum mengunci bintang.
- [ ] Penanda posisi bintang digambar di layar, bukan hanya jarak sudutnya.
- [ ] Planet ikut dikenali, bukan hanya bintang.

### Batas yang diketahui

| Batas | Akibatnya |
|---|---|
| Utara magnetik, bukan utara sejati | Deklinasi magnetik belum dikoreksi. Di Indonesia selisihnya sekitar 1 derajat sehingga tak terasa; di sebagian Amerika Utara bisa belasan derajat |
| Ketelitian kompas ponsel | Magnetometer ponsel mudah terganggu logam dan speaker. Bidikan meleset beberapa derajat adalah hal biasa |
| Presesi diabaikan | Katalog berpatokan J2000; pergeserannya sekitar 0,4 derajat untuk 2026, jauh di bawah derau kompas |
| Hanya bintang | Planet bergerak terhadap bintang, jadi perlu perhitungan terpisah yang belum dibangun |


---

## 4.6 Deteksi sumber cahaya

**Ditambahkan 14 November 2026.** Setengah jalan menuju kriteria 4.2 "node
otomatis pada sumber cahaya ekstrem", yang sebelumnya **Belum** sepenuhnya.

**Deskripsi:** selama portal terbuka, aplikasi membaca bidang kecerahan tiap
bingkai kamera dan mencari titik paling terang. Bulan, lampu jalan, atau jendela
menyala ditandai halo berdenyut dengan empat sinar. Sekali ketuk menaruh node
tepat di sana.

### Cara kerjanya

Format YUV420 menaruh kecerahan di bidang pertama, satu byte per piksel, jadi
tidak ada penguraian warna sama sekali. Pencariannya **mencuplik**: bingkai
1080p berisi dua juta piksel, dan membacanya tiga puluh kali per detik akan
menghabiskan anggaran frame. Yang dibaca dibatasi sekitar 3.600 piksel berapa
pun resolusinya, dan hanya empat kali sedetik.

### Ambangnya diukur, bukan ditebak

Satu titik dianggap sumber cahaya kalau kecerahannya di atas 232 **dan**
selisihnya terhadap rata-rata bingkai di atas 90.

Syarat kedua yang penting. Tanpanya, langit siang akan dianggap satu lampu
raksasa. Angkanya diambil dari pengukuran di perangkat:

| Keadaan | Kontras terukur | Hasil |
|---|---|---|
| Adegan uji emulator, terang merata | 51 | Ditolak |
| Pemandangan siang hari | sekitar 60 sampai 90 | Ditolak |
| Lampu jalan atau bulan di langit malam | 150 ke atas | Diterima |

### Acceptance Criteria
- [x] Titik cahaya paling terang ditemukan tanpa membaca seluruh piksel.
- [x] Bingkai terang merata ditolak, bukan dianggap satu sumber cahaya.
- [x] Koordinat sensor dipetakan benar ke layar untuk keempat orientasi.
- [x] Sekali ketuk menaruh node tepat di titik itu.
- [ ] Node muncul sendiri tanpa diketuk, seperti bunyi PRD aslinya.
- [ ] Lebih dari satu sumber cahaya ditandai sekaligus.
