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
