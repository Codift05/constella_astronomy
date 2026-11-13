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
