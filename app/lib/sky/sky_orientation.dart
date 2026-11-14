import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'sky_math.dart';

/// Arah bidikan kamera belakang, digabung dari akselerometer dan magnetometer.
///
/// Akselerometer memberi arah atas, magnetometer memberi arah utara. Hanya
/// dengan keduanya sekaligus arah pandang bisa diketahui penuh — akselerometer
/// saja cukup untuk cakrawala, tapi tidak untuk tahu bintang mana yang dibidik.
///
/// Keterbatasan yang disengaja dan dicatat: utaranya **utara magnetik**.
/// Deklinasi magnetik di Indonesia sekitar satu derajat, jauh di bawah derau
/// kompas ponsel, jadi belum dikoreksi. Di belahan bumi lain selisihnya bisa
/// belasan derajat dan koreksinya akan terasa.
class SkyOrientation extends ChangeNotifier {
  SkyOrientation({
    Stream<AccelerometerEvent>? accelerometer,
    Stream<MagnetometerEvent>? magnetometer,
    this.settleTimeout = const Duration(seconds: 3),
  }) : _accel = accelerometer ?? accelerometerEventStream(),
       _mag = magnetometer ?? magnetometerEventStream();

  final Stream<AccelerometerEvent> _accel;
  final Stream<MagnetometerEvent> _mag;

  /// Kalau salah satu sensor tidak pernah melapor dalam rentang ini,
  /// perangkat dianggap tidak mampu dan layar menjelaskan itu.
  final Duration settleTimeout;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  Timer? _settle;

  double? _ax, _ay, _az;
  double? _mx, _my, _mz;

  SkyPoint? _direction;

  /// Arah bidikan sekarang, atau null kalau belum bisa ditentukan.
  SkyPoint? get direction => _direction;

  bool get available => _direction != null;

  bool _timedOut = false;

  /// True kalau sensornya tidak pernah menjawab sampai tenggat habis.
  /// Berbeda dari sekadar "belum siap": ini keadaan yang perlu dijelaskan
  /// ke pengguna, bukan ditunggu terus.
  bool get unsupported => _timedOut && _direction == null;

  /// Pelicin low-pass. Magnetometer ponsel berderau jauh lebih besar daripada
  /// akselerometer, jadi tetapannya lebih kecil.
  static const _accelSmoothing = 0.15;
  static const _magSmoothing = 0.08;

  /// Perubahan arah di bawah ambang ini tidak memberi tahu pendengar.
  static const _quantumDeg = 0.35;

  SkyPoint? _lastNotified;

  void start() {
    if (_accelSub != null) return;
    _settle = Timer(settleTimeout, () {
      if (_direction == null) {
        _timedOut = true;
        notifyListeners();
      }
    });
    _accelSub = _accel.listen((e) {
      _ax = _blend(_ax, e.x, _accelSmoothing);
      _ay = _blend(_ay, e.y, _accelSmoothing);
      _az = _blend(_az, e.z, _accelSmoothing);
      _recompute();
    }, onError: (_) {});
    _magSub = _mag.listen((e) {
      _mx = _blend(_mx, e.x, _magSmoothing);
      _my = _blend(_my, e.y, _magSmoothing);
      _mz = _blend(_mz, e.z, _magSmoothing);
      _recompute();
    }, onError: (_) {});
  }

  static double _blend(double? current, double next, double factor) =>
      current == null ? next : current + (next - current) * factor;

  void _recompute() {
    final ax = _ax, ay = _ay, az = _az, mx = _mx, my = _my, mz = _mz;
    if (ax == null || ay == null || az == null) return;
    if (mx == null || my == null || mz == null) return;

    final next = lookDirection(ax: ax, ay: ay, az: az, mx: mx, my: my, mz: mz);
    if (next == null) return;

    final first = _direction == null;
    _direction = next;
    if (first) {
      _settle?.cancel();
      _timedOut = false;
      _lastNotified = next;
      notifyListeners();
      return;
    }
    final last = _lastNotified;
    if (last == null || angularSeparation(last, next) >= _quantumDeg) {
      _lastNotified = next;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _settle?.cancel();
    _accelSub?.cancel();
    _magSub?.cancel();
    super.dispose();
  }
}
