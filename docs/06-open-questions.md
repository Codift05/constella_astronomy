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
