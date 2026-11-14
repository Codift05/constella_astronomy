# constella_app

Aplikasi Flutter untuk Constella. PRD ada di [`../docs/`](../docs/).

## Status

| Bagian | Status |
|---|---|
| Design system (Spatial Soft UI) | Terpasang — `lib/theme/tokens.dart`, `lib/widgets/soft_ui.dart` |
| Dua bahasa (EN/ID) | Terpasang — ARB di `lib/l10n/` |
| Sky launchpad (tab utama) | Jalan, data masih hardcode |
| AR Time-Bubble (4.1) | Portal jalan: kamera, orb, ekspansi spring, starfield. **Belum** sky replacement asli atau posisi planet asli — open questions #1, #2, #6 |
| Skyline Constellations (4.2) | Menggambar sampai tersimpan dan tampil di daftar berhalaman. **Belum** pelabuhan node otomatis ke sumber cahaya dan **belum** dikirim ke Supabase — open questions #3, #4 |
| Aksesibilitas | Semua pasangan warna lolos WCAG AA, target sentuh 44 pt, bertahan di Dynamic Type 200% |
| Pagination & cache | `ConstellationStore` cursor-based dengan cache per halaman; daftar memuat sendiri saat digulung |
| Astro-Transit (4.3) | Belum — open question #5 |
| Focus Session (4.4) | Pengatur durasi + hitung mundur di dalam Malam Kosmik, jeda, menyerah, Stardust bertambah saat selesai |
| Stardust Energy | Nyata, mulai dari 0, progress bar melengkung sesuai PRD |
| Cosmic Mascot | Placeholder 2D (CustomPainter), belum 3D |
| Lo-Fi player | Belum |
| Backend Golang & Supabase | Belum |

## Struktur

```
lib/
├── main.dart
├── l10n/                    # ARB + AppL10n hasil generate
├── theme/tokens.dart        # warna, tipografi, spring, shadow, radius
├── widgets/
│   ├── soft_ui.dart         # SpringTap, SoftCard, GlassCard, PillButton, SoftChip, ...
│   └── mascot.dart          # CosmicMascot + SpeechBubble
├── constellations/          # ConstellationDraft + ConstellationStore (murni, teruji)
├── focus/
│   ├── focus_options.dart   # pilihan durasi (murni, teruji)
│   └── focus_session.dart   # hitung mundur berbasis jam dinding (murni, teruji)
├── stardust/stardust_store.dart  # Stardust Energy (murni, teruji)
└── screens/
    ├── app_shell.dart            # tab bar: Langit, Rasi, Fokus
    ├── sky_launchpad_screen.dart # tab utama, pintu masuk AR
    ├── cosmic_night_screen.dart  # AR Time-Bubble (4.1) + menggambar rasi (4.2)
    ├── constellations_screen.dart
    └── focus_session_screen.dart
```

## Jalankan

```bash
flutter pub get
flutter run                 # debug — JIT, lambat, JANGAN dipakai menilai kemulusan
flutter run --release       # inilah kecepatan sebenarnya
flutter test
flutter analyze
```

## Mengukur kemulusan

```bash
flutter run --profile --dart-define=FRAME_REPORT=true
```

Tiap 120 frame tercetak p50/p90/p99 untuk **build** (kerja Dart) dan **raster** (kerja GPU).
Anggaran 60 fps adalah 16,6 ms per frame.

Hasil di emulator x86, 13 Nov 2026:

| Keadaan | build p50 | raster p50 | raster p99 |
|---|---|---|---|
| Blur backdrop di tab bar | 0,5 ms | 16,6 ms | **40,8 ms** |
| Tanpa blur di tab bar | 0,5 ms | 16,6 ms | 31,2 ms |
| Tanpa blur + backdrop AR digabung | 0,4 ms | 16,6 ms | **17,1–32,3 ms** |

Catatan penting: raster p50 16,6 ms itu **pacing vsync emulator**, bukan biaya app — di jendela
pengukuran yang tidak terikat vsync, p50 turun ke **1,7 ms**. Yang perlu diawasi adalah p99.
Sisa lonjakan ~30 ms hanya terjadi pada frame transisi antar tab.

## Catatan Implementasi

- Tab bar melayang menghitung jaraknya sendiri dari `MediaQuery.viewPaddingOf(context).bottom`. Layar di bawahnya **wajib** memakai `SafeArea(bottom: false)` dan menyisakan `kTabBarInset` di padding bawah — kalau `bottom` dibiarkan true, jarak bawah terhitung dua kali dan konten melayang jauh dari bar.
- Jangan memberi `alignment` pada container sebuah chip di dalam `Wrap`: `alignment` membuat container memuai memenuhi lebar yang tersedia, sehingga chip berubah jadi baris penuh. Tinggi minimum cukup lewat `constraints`.
- Jangan menambah elemen UI yang tidak bisa dilacak ke PRD. Kategori fokus, kartu "Tonight above you", dan tab Profile pernah masuk dari gambar referensi atau karangan, lalu dihapus pada 14 Nov 2026 — lihat `docs/07-gap-analysis.md` §7.6.
- `BackdropFilter` memaksa `saveLayer` atas seluruh konten di belakangnya pada setiap frame. Jangan taruh di elemen yang selalu tampil (tab bar) saat ada animasi berjalan di belakangnya. Kalau satu layar butuh beberapa kaca, bungkus dengan `BackdropGroup` dan pakai `GlassCard(grouped: true)` supaya jadi satu lintasan.
- `ConstellationScope` dipasang **di atas** `MaterialApp`, bukan di `home`. Kalau di `home`, rute yang di-push tidak bisa membacanya.
- Skala tipografi mengikuti iOS Dynamic Type ukuran Large: Body 17, Footnote 13, Large Title 34. Jangan pakai angka di luar skala itu.
- `AppColor.accentPrimary` hanya untuk permukaan. Untuk ikon bermakna dan isi progress bar pakai `AppColor.accentStrong` (3.25:1 di putih).
- Squircle memakai `RoundedSuperellipseBorder` dan `ClipRSuperellipse` bawaan Flutter 3.32+. Tidak ada dependency tambahan.
- Animasi idle maskot berulang tanpa henti, jadi `pumpAndSettle()` akan timeout di tes. Pakai `pump(Duration)`.
- String UI ada di `lib/l10n/app_en.arb` dan `app_id.arb`. Setelah mengubahnya, jalankan `flutter gen-l10n`.
- Emulator tanpa kamera belakang bikin init kamera menggantung, jadi ada timeout 8 detik. Untuk melihat portal di emulator, jalankan dengan `emulator -avd <nama> -camera-back emulated`.
- Font SF Pro hanya resolve di iOS. Android jatuh ke fallback sistem sampai open question #7 dijawab.
