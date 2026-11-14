# 3. Design System: Spatial Soft UI

Desain harus terasa sangat "Apple-Native": elegan, bersih, namun tetap playful dan ramah.

Referensi visual: [`../references/ref-01-foku-soft-ui-mascot.png`](../references/ref-01-foku-soft-ui-mascot.png)

## 3.1 Color Palette

Palet diganti **15 November 2026** atas permintaan pemilik produk, dari keluarga
biru-navy ke keluarga teal-mint. Satu hal tidak berubah dan memang diminta tidak
berubah: **putih tetap dominan.** Teal dan mint adalah aksen; mereka menandai
hal yang bisa ditekan dan hal yang perlu dibaca, bukan mengecat halaman.

### Warna merek

Empat warna, dari palet yang dikirim pemilik produk:

| Nama | Nilai | Peran |
|---|---|---|
| Teal tua | `#287A74` | Tombol utama, ikon bermakna, teks aksen |
| Teal | `#55A9A0` | Varian tombol, gradien langit, badan maskot |
| Mint | `#AEEED3` | Permukaan pastel, chip terpilih, aksen tema gelap |
| Kuning pucat | `#FFF8B0` | Penanda kedua: sumber cahaya tertangkap, chip kecerahan |

Aturan yang bertahan dari palet lama: **warna aksi pekat hanya untuk satu tombol
utama per layar.** Tombol sekunder memakai pastel.

Kuning pucat sengaja diberi tugas yang sempit. Ia satu-satunya warna hangat di
palet ini, jadi ia menonjol di mana pun ditaruh; memakainya untuk lebih dari
satu jenis hal akan membuat keduanya saling melemahkan.

### Dua tema, satu sumber

Sejak 14 November 2026 seluruh warna hidup di satu kelas, `AppPalette`
(`app/lib/theme/palette.dart`), yang punya dua instance: `light` dan `dark`. Ia dipasang sebagai
`ThemeExtension`, jadi `MaterialApp` **menginterpolasi** warnanya saat tema berganti — perpindahannya
meluncur 360 ms, tidak berkedip.

Tidak ada lagi konstanta `AppColor`. Widget membaca `context.palette.textPrimary`; `CustomPainter`
yang tidak punya `BuildContext` menerima warnanya lewat konstruktor dan membandingkannya di
`shouldRepaint`.

| Token | Terang | Gelap | Pemakaian |
|---|---|---|---|
| `backgroundPrimary` | `#FFFFFF` | `#112523` | Permukaan kartu |
| `backgroundSecondary` | `#F2F7F5` | `#06100F` | Latar layar |
| `controlSurface` | `#F2F7F5` | `#1B3835` | Tombol bulat stepper, jalur progress bar |
| `accentWash` | `#E8F7F0` | `#16302C` | Chip non-aktif, indikator tab bar |
| `textPrimary` | `#0C2B28` | `#E6F2EF` | Teks utama |
| `textSecondary` | `#4E6B67` | `#93AFAA` | Teks sekunder, label tab non-aktif |
| `accentPrimary` | `#AEEED3` | `#AEEED3` | Permukaan pastel |
| `accentSecondary` | `#FFF8B0` | `#FFF8B0` | Pendamping hangat |
| `accentStrong` | `#287A74` | `#7FD6C3` | Ikon bermakna, isi progress bar |
| `actionPrimary` | `#287A74` | `#AEEED3` | Latar tombol utama |
| `onAction` | `#FFFFFF` | `#06231F` | Label di atas tombol utama |
| `chipSelectedBg` / `…Text` | `#AEEED3` / `#0C2B28` | `#1F4541` / `#E6F2EF` | Chip terpilih |
| `cardBorder` | — | `#FFFFFF` 12% | Tepi kartu |

Putih dominan dijaga oleh dua keputusan, bukan oleh niat baik:

1. `backgroundPrimary` tetap `#FFFFFF` murni. Kartu adalah permukaan yang paling
   sering dilihat, dan ia putih bersih.
2. `backgroundSecondary` hanya **bersemu** mint (`#F2F7F5`). Cukup untuk
   memisahkan latar layar dari kartu putih di atasnya, dan masih terbaca sebagai
   putih, bukan sebagai hijau muda.

Tiga hal yang **berbalik**, bukan sekadar digelapkan:

1. **Tombol utama.** Di tema terang ia teal tua berteks putih (5,09:1). Di tema
   gelap teal tua akan lenyap di atas latar nyaris hitam, jadi ia menjadi kapsul
   mint berteks gelap — konvensi tinted button iOS. Rasionya 12,60:1.
2. **Pemisah kartu.** Tema terang memakai bayangan. Bayangan hitam tidak terlihat di atas
   `#06100F`, jadi tema gelap memakai tepi rambut putih 12% dan permukaan kartu yang **lebih
   terang** dari latar. Kartu naik, tidak tenggelam.
3. **Chip terpilih.** Mint `#AEEED3` tidak bisa dipakai bersama teks terang, jadi
   tema gelap memakai pasangan warnanya sendiri.

### Lapisan AR: `AppNight`

Permukaan yang **tidak** ikut tema: layar AR, lapisan gambar rasi, dan pesan galat kamera. Di sana
latarnya umpan kamera atau langit hitam, jadi warnanya diambil dari `AppNight` dan tetap apa pun
pilihan pengguna. Ikon status bar di layar AR dipaksa terang lewat `AnnotatedRegion`.

| Token | Nilai | Pemakaian |
|---|---|---|
| `AppNight.accent` | `#AEEED3` | Tombol, nama rasi, halo bintang terang |
| `AppNight.neon` | `#FFF8B0` | Penanda sumber cahaya yang tertangkap kamera |
| `AppNight.surface` | `#12302C` | Kartu kaca di atas kamera |
| `AppNight.onAccent` | `#06231F` | Label di atas `accent`, 12,60:1 |

`neon` kuning bukan pilihan gaya: yang ditandainya memang lampu, dan lampu
memang kuning. Warnanya menyebut benda yang ditunjuk.

Dua warna di lapisan AR **bukan** warna merek dan tidak ikut diganti: selubung
malam `#040A1F` dan titik bintang putih. Keduanya warna langit, bukan warna
aplikasi — mewarnainya teal akan membuat langit berbohong.

### Kontras dijaga tes, bukan ingatan

`app/test/palette_contrast_test.dart` menghitung rasio WCAG untuk 20 pasangan warna di **tiap**
tema — 40 pemeriksaan — setiap kali tes dijalankan. Seluruh palet 15 November dipilih dengan
kalkulator kontras lebih dulu, bukan dipilih karena enak dipandang lalu diperiksa belakangan.
Pasangan paling ketat di tema terang adalah teal tua di atas `accentWash` (4,60:1); itulah yang
menentukan `accentWash` dibuat `#E8F7F0` dan bukan lebih gelap.

Tes ini pernah menangkap satu cacat yang lolos dari audit manual: `accentStrong` biru lama
`#5C8EE6` hanya 2,997:1 di latar sekunder — gagal ambang 3:1 pada ikon empty-state dan titik
onboarding.

## 3.2 Typography

| Peran | Typeface | Catatan |
|---|---|---|
| Large Titles | SF Pro Rounded | Memberi kesan ramah |
| Body & detail | SF Pro Display | Memberi kesan profesional |

Di Android, SF Pro tidak tersedia. Pilih padanan rounded (misalnya varian rounded dari keluarga grotesk yang lisensinya mengizinkan) dan kunci pilihannya di `06-open-questions.md`.

## 3.3 Komponen UI Core

### Frosted Glass (Vibrancy)
Semua kartu informasi, pop-up, dan bottom sheet memakai material transparan ultra-thin dengan blur di belakangnya.

Di Flutter: `BackdropFilter` + `ImageFilter.blur` di dalam `ClipRRect`, dengan lapisan warna semi-transparan di atasnya.

### Squircles & Pills
Tidak ada sudut kaku.

| Elemen | Bentuk |
|---|---|
| Kartu | Super-ellipse (lengkungan organik ala Apple), bukan `BorderRadius.circular` biasa |
| Tombol aksi | Kapsul (pill-shaped), radius = setengah tinggi |
| Chip menit | Kapsul kecil |

### Daftar Komponen MVP
| Komponen | Dipakai di |
|---|---|
| Glass Card | Label landmark, kartu statistik maskot, kartu Today's Focus |
| Pill Button (Navy) | "Start focus session", aksi utama |
| Chip Button (Pastel) | Pilihan durasi (5m, 10m, 15m, 25m, 30m, 45m, 60m) |
| Speech Bubble | Panduan onboarding dari maskot |
| Curved Progress Bar | Indikator Stardust Energy — busur 240 derajat, terbuka di bawah |
| Bottom Tab Bar | Langit (AR), Rasi, Fokus |
| Mini Audio Player | Lo-fi player di atas Home Indicator |

## 3.4 Interactions

### Haptic Feedback
Taptic Engine aktif pada setiap interaksi:

| Aksi | Jenis getaran |
|---|---|
| Menarik garis antar node rasi bintang | Ringan, berulang saat node tersambung |
| Menekan tombol kapsul | Medium impact |
| Interaksi maskot | Ringan |
| Portal terbuka penuh | Berat, sekali |

### Spring Animations
Seluruh transisi UI — buka portal, pop-up, scroll — wajib memakai spring physics. Tidak ada kurva linear.

| Transisi | Karakter |
|---|---|
| Buka portal AR | Lambat, overshoot terlihat, megah |
| Pop-up / bottom sheet | Cepat, overshoot kecil |
| Press tombol | Sangat cepat, scale turun lalu kembali |

## 3.5 Aturan Yang Tidak Boleh Dilanggar

1. Tidak ada sudut 90 derajat pada permukaan apa pun.
2. Tidak ada transisi linear yang terlihat pengguna.
3. Setiap interaksi membalas dengan gerakan atau haptic sebelum membalas dengan teks.
4. Teks di atas frosted glass harus tetap lolos kontras WCAG AA — blur bukan pengganti kontras.
5. Satu tombol Navy per layar.

## 3.6 Catatan Koreksi

**14 November 2026.** Dua baris di dokumen ini sempat mencantumkan "kategori fokus"
(Study / Work / Creative / Reading) sebagai komponen. Itu keliru: kategori tersebut berasal
dari gambar referensi Foku, bukan dari PRD. Baris itu sudah dihapus beserta kodenya.

Pelajarannya: gambar referensi menentukan **rupa**, PRD menentukan **fungsi**. Jangan menaikkan
elemen dari gambar menjadi spesifikasi.
