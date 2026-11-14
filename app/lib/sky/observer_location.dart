import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Keadaan usaha menentukan posisi pengamat.
enum LocationState {
  /// Belum pernah dicoba.
  idle,
  resolving,
  ready,

  /// Ditolak kali ini. Masih bisa diminta lagi.
  denied,

  /// Ditolak permanen; hanya bisa dipulihkan lewat Setelan.
  deniedForever,

  /// Layanan lokasi perangkat dimatikan seluruhnya.
  serviceOff,

  /// Gagal karena sebab lain, termasuk kehabisan waktu.
  unavailable,
}

/// Posisi pengamat di bumi, yang menentukan bintang mana yang sedang terbit.
///
/// Sengaja meminta **akurasi rendah**. Untuk urusan langit, meleset beberapa
/// kilometer tidak terukur: bahkan selisih 50 km hanya menggeser bintang
/// sekitar setengah derajat, jauh di bawah ketelitian kompas ponsel. Akurasi
/// rendah lebih cepat, lebih hemat baterai, dan yang terpenting hanya meminta
/// izin "lokasi perkiraan" kepada pengguna.
class ObserverLocation extends ChangeNotifier {
  ObserverLocation({this.timeout = const Duration(seconds: 12)});

  /// Posisi yang sudah diketahui, tanpa menyentuh GPS sama sekali.
  /// Dipakai tes, dan nanti juga oleh pilihan "atur kota secara manual".
  ObserverLocation.at(double latitude, double longitude)
    : timeout = Duration.zero,
      _latitude = latitude,
      _longitude = longitude,
      _state = LocationState.ready;

  /// GPS bisa menggantung tanpa batas di dalam ruangan.
  final Duration timeout;

  LocationState _state = LocationState.idle;
  LocationState get state => _state;

  double? _latitude;
  double? _longitude;

  double? get latitude => _latitude;
  double? get longitude => _longitude;

  bool get hasFix => _state == LocationState.ready;

  void _set(LocationState s) {
    if (_state == s) return;
    _state = s;
    notifyListeners();
  }

  /// Meminta posisi, termasuk meminta izin kalau perlu.
  Future<void> resolve() async {
    if (_state == LocationState.resolving) return;
    _set(LocationState.resolving);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _set(LocationState.serviceOff);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _set(LocationState.deniedForever);
        return;
      }
      if (permission == LocationPermission.denied) {
        _set(LocationState.denied);
        return;
      }

      // Posisi terakhir yang diketahui dipakai lebih dulu kalau ada: langit
      // tidak peduli apakah datanya semenit atau sejam lalu.
      final cached = await Geolocator.getLastKnownPosition();
      if (cached != null) {
        _apply(cached);
      }

      final fresh = await _currentPosition();
      if (fresh != null) {
        _apply(fresh);
      } else if (_latitude == null) {
        // Posisi lama sudah cukup kalau sempat terbaca; kalau tidak ada
        // sama sekali, barulah keadaannya dianggap gagal.
        _set(LocationState.unavailable);
      }
    } catch (_) {
      if (_latitude == null) _set(LocationState.unavailable);
    }
  }

  /// Meminta posisi lewat penyedia bawaan, lalu — kalau itu tidak menjawab —
  /// lewat LocationManager Android secara langsung.
  ///
  /// Penyedia bawaan di Android adalah fused milik Google Play Services. Ia
  /// paling baik di ponsel biasa, tapi diam saja di perangkat tanpa Play
  /// Services yang lengkap, dan diam itu tidak pernah berubah jadi galat.
  /// Jalur kedua memakai LocationManager sistem, yang selalu ada.
  Future<Position?> _currentPosition() async {
    Future<Position?> attempt(LocationSettings settings) async {
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: settings,
        ).timeout(timeout);
      } on TimeoutException {
        return null;
      } catch (_) {
        return null;
      }
    }

    final fused = await attempt(
      const LocationSettings(accuracy: LocationAccuracy.low),
    );
    if (fused != null) return fused;

    if (defaultTargetPlatform != TargetPlatform.android) return null;
    return attempt(
      AndroidSettings(
        accuracy: LocationAccuracy.low,
        forceLocationManager: true,
      ),
    );
  }

  void _apply(Position p) {
    _latitude = p.latitude;
    _longitude = p.longitude;
    _state = LocationState.ready;
    notifyListeners();
  }

  /// Membuka halaman Setelan aplikasi, untuk kasus izin ditolak permanen.
  Future<bool> openSettings() => Geolocator.openAppSettings();
}
