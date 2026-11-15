# Constella

Aplikasi eksplorasi Augmented Reality yang menggabungkan lanskap tata surya dengan estetika urban perkotaan.

- **Platform:** Mobile (iOS & Android)
- **Stack:** Flutter (frontend) + Golang (backend) + Supabase/PostgreSQL
- **Design System:** Spatial Soft UI — Playful Modern Minimalism di atas standar Apple HIG, palet teal-mint dengan putih dominan
- **Status:** Berjalan di perangkat. Malam Kosmik menunjukkan langit yang benar-benar ada di atas pengamat, penangkap bintang menamai bintang yang dibidik, rasi kota bisa digambar, dan potret kosmik bisa dibagikan. Yang belum: posisi planet, garis rasi, dan world tracking AR sungguhan — lihat [`docs/07-gap-analysis.md`](docs/07-gap-analysis.md)
- **Pengujian:** 261 tes, `flutter analyze` bersih, 40 pemeriksaan kontras WCAG di kedua tema

## Struktur Folder

```
constella/
├── README.md                    # Dokumen ini — titik masuk
├── app/                         # Aplikasi Flutter (lihat app/README.md)
├── docs/
│   ├── 00-prd-index.md          # Ringkasan PRD + daftar isi
│   ├── 01-product-vision.md     # Visi produk, target pengalaman, prinsip
│   ├── 02-tech-stack.md         # Stack teknis & environment
│   ├── 03-design-system.md      # Spatial Soft UI: warna, tipografi, komponen, interaksi
│   ├── 04-features-mvp.md       # 4 fitur inti MVP + acceptance criteria
│   ├── 05-data-models.md        # Skema Supabase/PostgreSQL
│   ├── 06-open-questions.md     # Hal yang belum diputuskan sebelum coding
│   └── 07-gap-analysis.md       # PRD vs kode: 27 kriteria, status tiap satunya
└── references/
    ├── README.md                # Catatan tiap file referensi
    ├── ref-01-foku-soft-ui-mascot.png
    └── ref-02-eco-camping-illustrated-cards.png
```

## Baca Mulai Dari Mana

| Peran | Mulai dari |
|---|---|
| Product / stakeholder | `docs/01-product-vision.md` → `docs/04-features-mvp.md` |
| Designer | `docs/03-design-system.md` → `references/` |
| Flutter developer | `docs/02-tech-stack.md` → `docs/03-design-system.md` → `app/README.md` |
| Backend developer | `docs/02-tech-stack.md` → `docs/05-data-models.md` |
