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
