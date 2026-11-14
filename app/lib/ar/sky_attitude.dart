import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Sudut elevasi kamera di atas cakrawala, dibaca dari akselerometer.
///
/// **Apa yang ini bisa dan tidak bisa.** Akselerometer mengukur arah gravitasi,
/// jadi elevasi dan kemiringan bersifat **absolut dan tidak hanyut** — dia
/// selalu tahu di mana bawah. Yang ia tidak tahu adalah arah mata angin:
/// memutar badan ke kiri atau kanan tidak terbaca sama sekali. Untuk itu
/// dibutuhkan world tracking ARKit/ARCore ([#1–#4](../../docs/06-open-questions.md)),
/// dan integrasi giroskop bukan penggantinya: nilainya hanyut beberapa derajat
/// per menit, jadi bentuk rasi yang digambar akan merayap pelan dari tempatnya.
///
/// Karena itu kelas ini sengaja hanya menyediakan sumbu yang benar.
class SkyAttitude extends ChangeNotifier {
  SkyAttitude({
    Stream<AccelerometerEvent>? stream,
    this.settleTimeout = const Duration(seconds: 2),
  }) : _stream = stream ?? accelerometerEventStream();

  final Stream<AccelerometerEvent> _stream;

  /// Kalau tidak ada satu pun pembacaan dalam rentang ini, perangkat dianggap
  /// tidak punya akselerometer dan layar kembali ke perilaku lama.
  final Duration settleTimeout;

  StreamSubscription<AccelerometerEvent>? _sub;
  Timer? _settle;

  bool _available = false;

  /// False sampai pembacaan pertama tiba. Selama false, [elevation] bernilai 0
  /// dan pemanggil harus memperlakukan cakrawala sebagai tidak diketahui.
  bool get available => _available;

  double _elevation = 0;

  /// Radian. 0 = kamera menghadap cakrawala, +pi/2 = lurus ke zenit,
  /// -pi/2 = lurus ke tanah.
  double get elevation => _elevation;

  double _lastNotified = 0;

  /// Perubahan lebih kecil dari ini tidak memicu notifikasi. Tanpa ambang ini
  /// derau sensor memicu ~60 rebuild per detik dan membatalkan raster cache
  /// langit malam setiap frame, padahal pergeserannya tak terlihat mata.
  static const _quantum = 0.012; // ~0,7 derajat

  /// Pelicin low-pass. Akselerometer ponsel berderau; tanpa ini cakrawala
  /// bergetar walau ponsel diam di meja.
  static const _smoothing = 0.12;

  void start() {
    if (_sub != null) return;
    _settle = Timer(settleTimeout, () {
      if (!_available) {
        _elevation = 0;
        notifyListeners();
      }
    });
    _sub = _stream.listen(_onEvent, onError: (_) => _markUnavailable());
  }

  void _onEvent(AccelerometerEvent e) {
    final next = skyElevation(e.x, e.y, e.z);
    if (next == null) return; // jatuh bebas: arah bawah tidak terdefinisi
    _elevation = _available
        ? _elevation + (next - _elevation) * _smoothing
        : next;
    if (!_available) {
      _available = true;
      _settle?.cancel();
      _lastNotified = _elevation;
      notifyListeners();
      return;
    }
    if ((_elevation - _lastNotified).abs() >= _quantum) {
      _lastNotified = _elevation;
      notifyListeners();
    }
  }

  void _markUnavailable() {
    _available = false;
    _elevation = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _settle?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}

/// Elevasi kamera belakang di atas cakrawala, dari satu pembacaan
/// akselerometer dalam m/s^2.
///
/// Kamera belakang memandang ke arah -z perangkat. Saat diam, akselerometer
/// membaca lawan gravitasi, jadi vektor (x, y, z) menunjuk ke **atas**.
/// Elevasi arah pandang = asin(hasil kali titik arah pandang dengan atas)
/// = asin(-z / |a|).
///
/// Mengembalikan null kalau besarannya terlalu kecil untuk dipercaya —
/// perangkat sedang jatuh bebas atau diguncang keras, dan arah bawah tidak
/// terdefinisi.
double? skyElevation(double x, double y, double z) {
  final magnitude = math.sqrt(x * x + y * y + z * z);
  if (magnitude < 1.0) return null;
  return math.asin((-z / magnitude).clamp(-1.0, 1.0));
}

/// Posisi cakrawala pada layar, dalam piksel dari tepi atas.
///
/// Model pinhole: titik tengah bingkai berada pada [elevation], dan sebuah
/// titik pada elevasi 0 jatuh di `tengah + fokus * tan(elevation)`, dengan
/// `fokus = tengah / tan(fov/2)`.
///
/// Nilai yang dikembalikan sengaja **tidak** dibatasi ke dalam layar: nilai di
/// luar [height] berarti cakrawala ada di luar bingkai, dan pemanggil memakai
/// itu untuk menyimpulkan seluruh bingkai berisi langit atau tanah.
double horizonY({
  required double elevation,
  required double height,
  double verticalFov = _defaultVerticalFov,
}) {
  final half = height / 2;
  // Mendekati +-90 derajat tangennya meledak; dibatasi supaya tetap terhingga.
  const limit = math.pi / 2 - 0.02;
  final e = elevation.clamp(-limit, limit);
  final focal = half / math.tan(verticalFov / 2);
  return half + focal * math.tan(e);
}

/// Perkiraan bidang pandang vertikal kamera belakang ponsel dalam orientasi
/// potret. Nilai sebenarnya berbeda per perangkat; mengambilnya dari
/// `CameraController` adalah pekerjaan lanjutan kalau cakrawalanya terasa
/// meleset di perangkat tertentu.
const _defaultVerticalFov = 65 * math.pi / 180;
