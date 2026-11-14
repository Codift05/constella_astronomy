# Constella

Aplikasi eksplorasi Augmented Reality yang menggabungkan lanskap tata surya dengan estetika urban perkotaan.

- **Platform:** Mobile (iOS & Android)
- **Stack:** Flutter (frontend) + Golang (backend) + Supabase/PostgreSQL
- **Design System:** Spatial Soft UI — Playful Modern Minimalism di atas standar Apple HIG
- **Status:** Slice pertama jalan — design system + Home + Focus Session. Fitur AR belum (lihat `docs/06-open-questions.md`)

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
    └── ref-01-foku-soft-ui-mascot.png
```

## Baca Mulai Dari Mana

| Peran | Mulai dari |
|---|---|
| Product / stakeholder | `docs/01-product-vision.md` → `docs/04-features-mvp.md` |
| Designer | `docs/03-design-system.md` → `references/` |
| Flutter developer | `docs/02-tech-stack.md` → `docs/03-design-system.md` → `app/README.md` |
| Backend developer | `docs/02-tech-stack.md` → `docs/05-data-models.md` |
