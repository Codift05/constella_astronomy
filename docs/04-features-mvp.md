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
