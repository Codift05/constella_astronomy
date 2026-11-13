# 5. Data Models (Supabase / PostgreSQL)

Referensi untuk inisiasi database.

## 5.1 Tabel

### `users`
| Kolom | Tipe | Catatan |
|---|---|---|
| `id` | UUID | Primary key, terhubung ke `auth.users` Supabase |
| `username` | text | Unik |
| `stardust_energy` | int | Poin eksplorasi, default 0 |
| `created_at` | timestamptz | Default `now()` |

### `constellations`
| Kolom | Tipe | Catatan |
|---|---|---|
| `id` | UUID | Primary key |
| `user_id` | UUID | Foreign key ke `users.id` |
| `name` | text | Nama rasi bintang buatan pengguna |
| `node_coordinates` | JSONB | Array koordinat node |
| `created_at` | timestamptz | Default `now()` |

### `focus_sessions`
| Kolom | Tipe | Catatan |
|---|---|---|
| `id` | UUID | Primary key |
| `user_id` | UUID | Foreign key ke `users.id` |
| `duration_minutes` | int | Durasi yang dipilih |
| `completed_at` | timestamptz | Diisi hanya saat sesi benar-benar selesai |

## 5.2 Contoh Struktur `node_coordinates`

```json
[
  { "id": 0, "x": 0.12, "y": 1.84, "z": -4.20, "label": "Jembatan Kota" },
  { "id": 1, "x": 0.95, "y": 2.10, "z": -4.55, "label": null }
]
```

Koordinat disimpan relatif terhadap origin sesi AR. Sistem referensi (world-space AR, atau azimuth/altitude langit) belum ditetapkan — lihat `06-open-questions.md`.

Koneksi antar node perlu disimpan juga agar bentuk bisa dimuat ulang. Opsi: tambahkan field `edges` berisi pasangan id, atau anggap array `node_coordinates` sebagai polyline berurutan. Keputusan ini masih terbuka.

## 5.3 Row Level Security

Setiap tabel aktifkan RLS.

| Tabel | Kebijakan |
|---|---|
| `users` | Pengguna hanya bisa membaca dan mengubah barisnya sendiri |
| `constellations` | Pengguna hanya bisa CRUD barisnya sendiri |
| `focus_sessions` | Pengguna hanya bisa membaca dan menulis barisnya sendiri |

`stardust_energy` tidak boleh ditulis langsung dari klien. Nilainya diubah lewat fungsi database atau endpoint Golang supaya poin tidak bisa dipalsukan.
