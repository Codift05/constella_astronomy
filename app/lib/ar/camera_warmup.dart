import 'dart:async';

import 'package:camera/camera.dart';

/// Menyiapkan kamera sebelum layar AR dibuka.
///
/// Membuka kamera pertama kali melewati dua tahap: menanyakan daftar kamera ke
/// sistem, lalu menyalakan sensornya. Tahap pertama memakai kanal platform dan
/// bisa memakan ratusan milidetik pada panggilan pertama, dan itulah sebagian
/// jeda hitam yang terlihat saat Malam Kosmik dibuka.
///
/// Yang dihangatkan di sini **hanya tahap pertama**. Sensornya sengaja tidak
/// dinyalakan di latar belakang: itu akan menyalakan lampu indikator kamera
/// sejak aplikasi dibuka, menguras baterai, dan membuat aplikasi terlihat
/// mengintip padahal pengguna belum meminta apa pun. Jeda yang tersisa dijawab
/// dengan indikator memuat yang muncul seketika, bukan dengan menyalakan
/// kamera lebih awal.
abstract final class CameraWarmup {
  static Future<List<CameraDescription>>? _pending;
  static List<CameraDescription>? _cached;

  /// Dipanggil sekali saat aplikasi mulai. Kegagalan diabaikan: layar AR
  /// tetap menanyakan sendiri dan menangani galatnya di sana.
  static void start() {
    _pending ??= availableCameras()
        .then((list) {
          _cached = list;
          return list;
        })
        .catchError((Object _) => <CameraDescription>[]);
  }

  /// Daftar kamera, dari hasil yang sudah hangat kalau ada.
  static Future<List<CameraDescription>> cameras() {
    final cached = _cached;
    if (cached != null) return Future.value(cached);
    return _pending ??= availableCameras();
  }

  /// Hanya untuk tes.
  static void resetForTest() {
    _pending = null;
    _cached = null;
  }
}
