import 'dart:math' as math;
import 'dart:typed_data';

import 'dart:ui' show Offset;

/// Satu titik cahaya terang yang ditemukan di bingkai kamera.
class LightSpot {
  const LightSpot({
    required this.position,
    required this.intensity,
    required this.contrast,
  });

  /// Letaknya dalam koordinat sensor ternormalisasi, 0..1.
  final Offset position;

  /// Kecerahan titik itu, 0..1.
  final double intensity;

  /// Selisih kecerahannya terhadap rata-rata bingkai, 0..1. Inilah yang
  /// membedakan bulan di langit gelap dari dinding putih di siang bolong.
  final double contrast;
}

/// Mencari titik paling terang di bidang luma sebuah bingkai kamera.
///
/// Format YUV420 menaruh kecerahan di bidang pertama, satu byte per piksel,
/// jadi tidak perlu mengurai warna sama sekali.
///
/// Pencariannya **mencuplik**, tidak membaca seluruh piksel: bingkai 1080p
/// berisi dua juta piksel, dan membacanya tiga puluh kali per detik akan
/// menghabiskan anggaran frame. [samples] membatasi jumlah piksel yang
/// benar-benar dibaca, berapa pun resolusi kameranya.
///
/// Mengembalikan null kalau tidak ada yang cukup terang, atau kalau seluruh
/// bingkai terang merata. Syarat kedua itu penting: tanpanya, langit siang
/// akan dianggap satu lampu raksasa.
///
/// Angka [minContrast] berasal dari pengukuran, bukan tebakan. Adegan uji
/// emulator yang terang merata menghasilkan kontras 51, dan pemandangan siang
/// hari biasanya berhenti di sekitar 60 sampai 90. Lampu jalan atau bulan di
/// langit malam menghasilkan 150 ke atas, jadi ambang 90 memisahkan keduanya
/// dengan jarak aman di kedua sisi.
LightSpot? brightestSpot(
  Uint8List luma, {
  required int width,
  required int height,
  required int bytesPerRow,
  int minLuma = 232,
  int minContrast = 90,
  int samples = 3600,
}) {
  if (width <= 0 || height <= 0 || luma.isEmpty) return null;

  // Langkah cuplikan dipilih supaya jumlah piksel yang dibaca mendekati
  // [samples], berapa pun ukuran bingkainya.
  final step = math.max(1, math.sqrt(width * height / samples).round());

  var best = -1;
  var bestX = 0, bestY = 0;
  var total = 0, counted = 0;

  for (var y = 0; y < height; y += step) {
    final row = y * bytesPerRow;
    for (var x = 0; x < width; x += step) {
      final i = row + x;
      if (i >= luma.length) break;
      final v = luma[i];
      total += v;
      counted++;
      if (v > best) {
        best = v;
        bestX = x;
        bestY = y;
      }
    }
  }

  if (counted == 0 || best < minLuma) return null;
  final mean = total / counted;
  final contrast = best - mean;
  if (contrast < minContrast) return null;

  return LightSpot(
    position: Offset(bestX / width, bestY / height),
    intensity: best / 255,
    contrast: (contrast / 255).clamp(0.0, 1.0),
  );
}

/// Memetakan koordinat sensor ke koordinat pratinjau yang terlihat di layar.
///
/// Sensor kamera ponsel dipasang menyamping, jadi bingkainya datang dalam
/// orientasi lanskap dan diputar sebelum ditampilkan. [sensorOrientation]
/// adalah sudut putaran itu, nilainya dilaporkan paket kamera.
///
/// [mirrored] untuk kamera depan, yang gambarnya dibalik secara mendatar.
Offset sensorToPreview(
  Offset sensor, {
  required int sensorOrientation,
  bool mirrored = false,
}) {
  final x = sensor.dx, y = sensor.dy;
  final rotated = switch (sensorOrientation % 360) {
    90 => Offset(1 - y, x),
    180 => Offset(1 - x, 1 - y),
    270 => Offset(y, 1 - x),
    _ => Offset(x, y),
  };
  return mirrored ? Offset(1 - rotated.dx, rotated.dy) : rotated;
}
