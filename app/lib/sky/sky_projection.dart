import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'sky_math.dart';

/// Lebar bidang pandang mendatar kamera belakang yang dianggap, dalam derajat.
///
/// **Ini anggapan, bukan hasil ukur.** Flutter tidak memberi tahu bidang
/// pandang kamera, dan nilainya berbeda antar ponsel; 62 derajat ada di tengah
/// rentang lensa utama ponsel masa kini. Kalau anggapan ini meleset, bintang
/// tetap muncul di sisi yang benar, hanya bergesernya lebih cepat atau lebih
/// lambat daripada pemandangan di belakangnya.
const defaultHorizontalFovDeg = 62.0;

/// Jarak fokus dalam piksel untuk sebuah layar dan bidang pandang.
double focalFor(Size size, {double horizontalFovDeg = defaultHorizontalFovDeg}) =>
    (size.width / 2) / math.tan(horizontalFovDeg * math.pi / 360);

/// Menaruh satu arah langit di atas layar.
///
/// Mengembalikan null kalau arah itu ada di belakang kamera, atau terlalu jauh
/// ke tepi sehingga proyeksinya meledak. Proyeksinya gnomonik: arah yang tepat
/// di tengah bidikan jatuh di tengah layar, dan garis lurus di langit tetap
/// lurus di layar — sama seperti yang dilakukan lensa kamera di belakangnya.
Offset? projectToScreen({
  required Vec3 direction,
  required SkyFrame frame,
  required Size size,
  required double focal,
}) {
  final depth = dot(direction, frame.forward);
  // Di bawah ini arahnya hampir tegak lurus sumbu kamera: di luar layar mana
  // pun, dan pembagiannya mulai tidak stabil.
  if (depth <= 0.17) return null;

  final x = dot(direction, frame.right) / depth * focal;
  final y = dot(direction, frame.up) / depth * focal;

  // Sumbu y layar menunjuk ke bawah, kebalikan dari atas dunia.
  return Offset(size.width / 2 + x, size.height / 2 - y);
}

/// Jari-jari titik bintang dalam piksel, dari magnitudo tampaknya.
///
/// Magnitudo adalah skala terbalik dan logaritmik: makin kecil angkanya makin
/// terang, dan tiap 5 angka berarti 100 kali. Pemetaan di sini sengaja tidak
/// mengikuti kecerahan sebenarnya — Sirius akan jadi bola raksasa dan bintang
/// magnitudo 5 hilang sama sekali. Yang dipakai pemetaan linier berbatas,
/// supaya bintang terang tetap menonjol tanpa menelan tetangganya.
double starRadiusFor(double magnitude) {
  const brightest = -1.5, faintest = 5.5;
  final t = ((faintest - magnitude) / (faintest - brightest)).clamp(0.0, 1.0);
  return 0.7 + 2.9 * t * t;
}
