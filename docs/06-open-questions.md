# 6. Open Questions

Hal-hal yang belum diputuskan di PRD dan akan memblokir implementasi bila dibiarkan.

## Teknis

| # | Pertanyaan | Memblokir |
|---|---|---|
| 1 | Sky replacement: ARKit tidak menyediakannya secara langsung. Pakai segmentasi langit sendiri, atau dome 3D yang menutup viewport? | 4.1 |
| 2 | Padanan sky replacement di ARCore apa, dan fitur mana yang turun kualitas di Android? | 4.1 |
| 3 | Sistem koordinat `node_coordinates`: world-space AR per sesi, atau azimuth/altitude langit? World-space hilang begitu sesi berakhir. **Sementara** kode memakai koordinat layar dengan penanda `"space": "screen"`, yang hilang begitu kamera bergerak — ini harus diganti. | 4.2, 5.2 |
| 4 | ~~Koneksi antar node disimpan sebagai `edges` eksplisit atau polyline berurutan?~~ **Diputuskan 13 Nov 2026:** `edges` eksplisit berisi pasangan indeks, selalu urut kecil-ke-besar. Polyline tidak bisa menggambarkan bentuk bercabang. | 4.2, 5.2 |
| 5 | API radar penerbangan mana yang dipakai, berapa biayanya, dan bagaimana cakupannya di wilayah target? | 4.3 |
| 6 | Posisi planet dihitung lokal di perangkat atau diambil dari layanan? | 4.1 |
| 7 | Font pengganti SF Pro Rounded di Android apa, dan apakah lisensinya mengizinkan? | 3.2 |
| 8 | Dynamic Island memerlukan ActivityKit dan modul Swift terpisah — siapa yang menanganinya? | 4.3 |

## Produk

| # | Pertanyaan |
|---|---|
| 9 | ~~Tab "Shop" dan "Goals" ada di navigasi referensi, tetapi tidak ada di PRD.~~ **Diputuskan 13 Nov 2026:** navigasi mengikuti bobot fitur PRD, bukan gambar referensi. Tab menjadi Langit (AR), Rasi, Fokus, Profil. Shop dibuang dari MVP. |
| 10 | Stardust Energy didapat dari apa saja, dan berapa banyak per aksi? |
| 11 | Stardust Energy dipakai untuk apa? Tanpa sink, poin tidak punya arti. |
| 12 | Apa yang terjadi bila sesi fokus dibatalkan di tengah jalan? |
| 13 | Wilayah target peluncuran pertama di mana? Ini menentukan pilihan API radar. |
| 14 | Berapa versi iOS dan Android minimum? ARKit sky features membatasi perangkat. |

## Hukum & Privasi

| # | Pertanyaan |
|---|---|
| 15 | GPS dan kamera selalu aktif — bagaimana teks permission dan kebijakan privasinya? |
| 16 | Musik lo-fi: lisensi dari mana? |
| 17 | Nama "Foku" pada maskot referensi adalah milik produk lain. Maskot Constella perlu nama dan desain sendiri. |
