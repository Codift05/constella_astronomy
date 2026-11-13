# 3. Design System: Spatial Soft UI

Desain harus terasa sangat "Apple-Native": elegan, bersih, namun tetap playful dan ramah.

Referensi visual: [`../references/ref-01-foku-soft-ui-mascot.png`](../references/ref-01-foku-soft-ui-mascot.png)

## 3.1 Color Palette

| Token | Nilai | Pemakaian |
|---|---|---|
| `background/primary` | `#FFFFFF` Clean White | Latar utama layar |
| `background/secondary` | `#F4F6F8` Soft Cloud Gray | Latar alternatif, kesan modern dan bersih |
| `accent/primary` | Pastel Blue | Header latar, chip terpilih |
| `accent/secondary` | Soft Lavender | Elemen non-aktif, gradient pendamping |
| `action/primary` | `#0A192F` Deep Navy | Tombol pemicu utama, kontras maksimal |
| `action/primary-alt` | Midnight Blue | Varian tombol aksi |

Aturan: warna aksi gelap hanya untuk satu tombol utama per layar. Semua tombol sekunder memakai pastel.

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
| `backgroundSecondary` | `#F4F6F8` | `#070D18` | Latar layar |
| `backgroundPrimary` | `#FFFFFF` | `#131C2E` | Permukaan kartu |
| `controlSurface` | `#F4F6F8` | `#1F2C47` | Tombol bulat stepper, jalur progress bar |
| `accentWash` | `#E8F0FF` | `#1C2942` | Chip non-aktif, indikator tab bar |
| `textPrimary` | `#0A192F` | `#E9EEF8` | Teks utama |
| `textSecondary` | `#5A6880` | `#9AA8C0` | Teks sekunder, label tab non-aktif |
| `accentStrong` | `#5687DC` | `#93C0FF` | Ikon bermakna, isi progress bar |
| `actionPrimary` | `#0A192F` | `#8FB8FF` | Latar tombol utama |
| `onAction` | `#FFFFFF` | `#08101F` | Label di atas tombol utama |
| `chipSelectedBg` / `…Text` | `#8FB8FF` / `#0A192F` | `#2E4878` / `#E9EEF8` | Chip terpilih |
| `cardBorder` | — | `#FFFFFF` 12% | Tepi kartu |

Tiga hal yang **berbalik**, bukan sekadar digelapkan:

1. **Tombol utama.** Di tema terang ia Deep Navy berteks putih. Di tema gelap Navy akan lenyap di
   atas latar nyaris hitam, jadi ia menjadi kapsul biru terang berteks gelap — konvensi tinted
   button iOS. Rasionya 9,48:1.
2. **Pemisah kartu.** Tema terang memakai bayangan. Bayangan hitam tidak terlihat di atas
   `#070D18`, jadi tema gelap memakai tepi rambut putih 12% dan permukaan kartu yang **lebih
   terang** dari latar. Kartu naik, tidak tenggelam.
3. **Chip terpilih.** Pastel `#8FB8FF` tidak bisa dipakai bersama teks terang (1,1:1), jadi tema
   gelap memakai pasangan warnanya sendiri.

Permukaan yang **tidak** ikut tema: layar AR, lapisan gambar rasi, dan pesan galat kamera. Di sana
latarnya umpan kamera atau langit hitam, jadi warnanya diambil dari `AppNight` dan tetap apa pun
pilihan pengguna. Ikon status bar di layar AR dipaksa terang lewat `AnnotatedRegion`.

Default-nya **ikut sistem**, seperti yang diminta `dark-mode.md`; pilihan manual hanya tambahan,
diputar lewat tombol di header layar Langit dan tersimpan di kolom `profile.theme_mode`.

### Kontras dijaga tes, bukan ingatan

`app/test/palette_contrast_test.dart` menghitung rasio WCAG untuk 34 pasangan warna di kedua tema
setiap kali tes dijalankan. Tes ini langsung menangkap satu cacat di tema terang yang lolos dari
audit manual sebelumnya: `accentStrong` lama `#5C8EE6` hanya 2,997:1 di latar sekunder — gagal
ambang 3:1 pada ikon empty-state dan titik onboarding. Diganti `#5687DC` (3,29:1).

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
