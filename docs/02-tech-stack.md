# 2. Technical Stack & Environment

## Ringkasan

| Layer | Teknologi | Alasan |
|---|---|---|
| Frontend Mobile | Flutter (Dart) | Memfasilitasi UI khusus dengan custom border-radius, soft shadow, dan spring physics secara konsisten di dua platform |
| AR Engine (iOS) | `arkit_plugin` | Akses ARKit native untuk sky replacement dan anchor spasial |
| AR Engine (Android) | `arcore_flutter_plugin` | Padanan ARCore |
| Jembatan native | `MethodChannel` | Dipakai bila plugin tidak cukup presisi untuk pengenalan scene spasial |
| Backend API | Golang (Gin atau Fiber) | Menangani data real-time dengan latensi rendah, misalnya live tracking penerbangan |
| Database | PostgreSQL via Supabase | Menyimpan profil, sesi fokus, dan koordinat rasi bintang |
| Auth | Supabase Auth | Terpasang satu paket dengan database |

## Catatan Implementasi

### Flutter
Spring physics memakai `SpringSimulation` / `SpringDescription` bawaan Flutter atau paket animasi setara. Tidak ada `Curves.linear` di transisi yang terlihat pengguna.

### AR
Kemampuan AR tidak setara antara ARKit dan ARCore. Fitur yang bergantung pada *sky replacement* dan *scene semantics* perlu jalur fallback di Android. Lihat `06-open-questions.md`.

### Backend Golang
Peran backend di MVP:
1. Proxy dan cache untuk API radar penerbangan pihak ketiga (melindungi API key, menurunkan jumlah request).
2. Perhitungan posisi planet dan rasi bintang real-time berdasarkan koordinat dan waktu pengguna.
3. Endpoint sinkronisasi untuk data yang tidak cocok ditulis langsung dari klien ke Supabase.

Operasi CRUD sederhana (profil, sesi fokus, konstelasi) boleh langsung dari Flutter ke Supabase dengan Row Level Security, tanpa melewati Golang.

### Dependensi Eksternal
| Dependensi | Dipakai oleh | Risiko |
|---|---|---|
| API radar penerbangan pihak ketiga | 4.3 Astro-Transit | Berbayar, rate-limited, cakupan tidak merata per wilayah |
| Data ephemeris planet | 4.1 AR Time-Bubble | Perlu dipilih antara perhitungan lokal atau layanan |


## Tambahan 14 November 2026

| Paket | Versi | Untuk apa |
|---|---|---|
| `geolocator` | ^14.1.2 | Lokasi **perkiraan** pengamat, yang menentukan bintang mana sedang terbit. Akurasi rendah diminta dengan sengaja: meleset 50 km hanya menggeser langit setengah derajat, dan izinnya jadi "lokasi perkiraan", bukan presisi |
| `sensors_plus` | ^7.1.1 | Akselerometer **dan magnetometer**. Akselerometer menghitung sudut elevasi kamera sehingga langit malam hanya mengganti bagian di atas cakrawala. Bukan pengganti ARKit/ARCore: ia tidak mengenal arah mata angin |

`camera`, `sqflite`, `path`, dan `intl` tetap seperti sebelumnya. Belum ada paket audio maupun jaringan — keduanya menunggu keputusan di [06-open-questions.md](06-open-questions.md).
