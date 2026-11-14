# Tindak lanjut Audit 001 — 14 November 2026

Seluruh 13 temuan dikerjakan. Ditambah tiga permintaan baru di luar audit:
animasi deteksi cahaya, transisi antar tab, dan keterangan fungsi.

## Temuan yang diperbaiki

| # | Temuan | Yang dikerjakan |
|---|---|---|
| 1 | Izin gerak iOS hilang | `NSMotionUsageDescription` ditambahkan ke `ios/Runner/Info.plist` dengan kalimat yang menjelaskan alasannya |
| 2 | Kurangi Gerak diabaikan | `lib/theme/motion.dart`: `context.calm()`, `context.calmCurve()`, `springTo()`, `holdOrRepeat()`. Sebelas durasi animasi dan ketiga spring dialirkan lewatnya |
| 3 | Animasi tanpa akhir | Napas maskot dan denyut orb berhenti di satu pose saat setelan itu menyala |
| 4 | Portal mengunci jari | Ambang `_canDraw` turun dari 0,995 plus `!isAnimating` menjadi 0,6 saja |
| 5 | Tiga kaca tanpa BackdropGroup | Layar penangkap bintang dibungkus `BackdropGroup`, ketiga kacanya `grouped: true` |
| 6 | Pelukis langit menggambar ulang terus | Cakrawala dibekukan selama `_portal.isAnimating` |
| 7 | Malam Kosmik tak dijelaskan | Kalimat tujuan di bawah tombol, menyebut polusi cahaya kota |
| 8 | Tab Bintang tak dijelaskan | Keadaan kosong kini menjelaskan fiturnya |
| 9 | Kolom label dipatok 110 pt | `IntrinsicWidth` berbatas, dan label pindah ke atas nilainya di atas skala teks 1,3x |
| 10 | Maskot tiga ukuran | `kMascotHero` 160 dan `kMascotInline` 140, masing-masing beralasan |
| 11 | `fontSize: 18` empat tempat | Kembali ke skala Dynamic Type iOS |
| 12 | Label tab "Shapes" | Menjadi "Constellations" |
| 13 | Ruang mati onboarding | Isi halaman dipusatkan |

## Yang ditambahkan di luar audit

**Deteksi sumber cahaya.** `lib/ar/light_finder.dart` membaca bidang kecerahan
tiap bingkai kamera dan mencari titik paling terang. Pencariannya mencuplik,
bukan membaca semua piksel: bingkai 4K pun selesai di bawah 80 ms, dan hanya
diperiksa empat kali sedetik.

Ambang kontrasnya **diukur, bukan ditebak**. Adegan uji emulator yang terang
merata memberi kontras 51 dan pemandangan siang hari berhenti sekitar 60 sampai
90, sementara lampu jalan di langit malam menghasilkan 150 ke atas. Ambang 90
memisahkan keduanya dengan jarak aman.

Titik yang ditemukan ditandai halo berdenyut dengan empat sinar, dan sekali
ketuk menaruh node tepat di sana. Ini setengah jalan menuju kriteria PRD 4.2
"node otomatis pada sumber cahaya ekstrem": titiknya sudah ditemukan mesin,
penempatannya masih diketuk orang.

**Sapuan bintang antar tab.** Bintang terbang mengikuti arah perpindahan, jadi
ia memberi tahu kamu bergerak ke kiri atau ke kanan, bukan sekadar bahwa layar
berganti (R-19 terpenuhi: gerak punya alasan). Diam total saat Kurangi Gerak
menyala.

## Delivery Gate

### Blok 1 — Hard Gate

| Aturan | Status | Bukti |
|---|---|---|
| R-02 tanda pisah em | PASS | `grep` atas seluruh ARB: nol kemunculan di teks antarmuka |
| R-03 responsif | PASS | Tes overflow pada 320x568 dan Dynamic Type 200% lolos; kolom label kartu bintang kini ikut skala teks |
| R-17 angka tanpa sumber | PASS | Setiap angka berasal dari SQLite atau katalog HYG |
| R-18 testimoni palsu | PASS | Tidak ada bagian testimoni |
| R-23 aset tanpa konfirmasi | PASS | Maskot `CustomPainter` ditandai penanda sementara di dokumen; katalog bintang bersumber HYG dan disebutkan |
| R-24 tautan mati | PASS | Tiga tab semuanya punya layar; tidak ada menu lain |
| R-25 kontras | PASS | 41 pasangan dihitung ulang terhadap WCAG AA tiap `flutter test` |
| R-26 kontrol mati | PASS | Click-through di emulator: ketiga tab, pemutar tema, pintu sesi fokus, portal AR, tombol tutup. Nol galat di logcat |
| R-27 keadaan UI | PASS | Penangkap bintang punya keadaan memuat, kosong, tanpa kompas, tanpa izin, dan galat kamera |
| R-28 FAQ generik | PASS | Tidak ada FAQ |
| R-32 keyboard | N/A | Aplikasi sentuh; tidak ada target desktop |
| R-33 tambalan skrip | PASS | Semua perubahan ditulis di sumber |
| R-34 kedua tema | PASS | Terang dan gelap dipakai di emulator, keduanya utuh |
| R-35 dijalankan | PASS | Dibangun, dipasang, diketuk satu per satu. 211 tes lolos, `flutter analyze` bersih |
| R-36 klaim karangan | PASS | Tidak ada klaim keamanan, kepatuhan, maupun performa |
| R-37 arah desain | PASS | `docs/03-design-system.md` jadi arahnya sejak awal |
| R-38 isi karangan | PASS | Batas yang diketahui ditulis terbuka di `docs/04-features-mvp.md` §4.5 |
| R-39 semantik & gerak | PASS | Halo cahaya punya `Semantics` berlabel; Kurangi Gerak kini dihormati dan menghentikan kedua animasi tanpa akhir |
| R-40 performa | PASS | Tidak ada angka performa yang dilaporkan tanpa diukur. Yang diukur disebut angkanya |

### Blok 2 — Purpose-Gate

| Aturan | Status | Alasan tertulis |
|---|---|---|
| R-01 gradasi | PASS | Gradasi hanya di halo maskot dan langit portal, keduanya memisahkan lapisan |
| R-04 ikon | PASS | Ikon menyebut isinya: bulan, bidikan, simpul |
| R-06 tipografi | PASS | Satu skala Dynamic Type iOS; `fontSize: 18` di luar skala sudah dihapus |
| R-07 latar berpola | PASS | Tidak ada pola latar |
| R-08 panah tombol | PASS | Tidak ada panah hias |
| R-09 lencana kapsul | PASS | Tidak ada lencana |
| R-10 glassmorphism | PASS | Kaca hanya melayang di atas umpan kamera, dan kini berbagi satu lintasan backdrop |
| R-12 bayangan | PASS | Bayangan menandai ketinggian kartu; di tema gelap digantikan tepi rambut |
| R-13 glow | PASS | Hanya pada orb dan halo cahaya, keduanya penanda target sentuh |
| R-14 kartu seragam | PASS | Kartu berbeda menurut isinya |
| R-19 animasi | PASS | Sapuan bintang menunjukkan arah perpindahan; halo menandai sumber cahaya |
| R-22 ilustrasi | PASS | Hanya maskot, yang memang karakter produk |

### Blok 3 — Liveliness

Dial: **ENERGY 2 / RHYTHM 2 / MOTION 2**, diturunkan dari
`docs/01-product-vision.md` yang meminta pengalaman menenangkan, megah, dan
interaktif.

| Butir | Status |
|---|---|
| Dial ditetapkan | YA |
| Keluaran sesuai dial | YA, gerak terasa tapi tidak pernah menghalangi |
| Satu titik fokus per layar | YA, tombol portal di Langit, bidikan di Bintang |
| Ruang kosong struktural | YA |
| Satu aksen disengaja | YA, biru pastel satu-satunya warna aksen |
| Motif identitas | YA, bintang: di sapuan tab, di halo cahaya, di bidikan |
| Design Read dinyatakan | YA, di dokumen sistem desain |

### Blok 4 — Craftsmanship

| Butir | Status |
|---|---|
| C-1 niat | PASS, setiap keputusan punya satu baris alasan di komentar kode |
| C-2 kelengkapan fungsi | PASS, click-through membuktikannya |
| C-3 komposisi dari isi | PASS, tiga tab, tiga tujuan nyata |
| C-4 ketahanan | PASS, kedua tema, teks 200%, layar 320 px, tanpa kompas, tanpa izin |
| C-5 bukti di atas klaim | PASS |

**Hasil: tidak ada FAIL. Layak dikirim.**
