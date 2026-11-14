import 'dart:typed_data';

import 'package:constella_app/ar/light_finder.dart';
import 'package:flutter_test/flutter_test.dart';

/// Membuat bidang luma dengan latar [background] dan satu titik terang
/// berukuran [blobSize] di ([spotX], [spotY]).
Uint8List frame({
  int width = 640,
  int height = 480,
  int background = 20,
  int? spotX,
  int? spotY,
  int spotValue = 255,
  int blobSize = 24,
}) {
  final data = Uint8List(width * height)
    ..fillRange(0, width * height, background);
  if (spotX != null && spotY != null) {
    for (var y = spotY - blobSize ~/ 2; y < spotY + blobSize ~/ 2; y++) {
      for (var x = spotX - blobSize ~/ 2; x < spotX + blobSize ~/ 2; x++) {
        if (x < 0 || y < 0 || x >= width || y >= height) continue;
        data[y * width + x] = spotValue;
      }
    }
  }
  return data;
}

void main() {
  group('mencari titik paling terang', () {
    test('menemukan bulan di langit gelap', () {
      final spot = brightestSpot(
        frame(spotX: 480, spotY: 120),
        width: 640,
        height: 480,
        bytesPerRow: 640,
      );
      expect(spot, isNotNull);
      // 480/640 = 0,75 dan 120/480 = 0,25, dengan toleransi langkah cuplikan.
      expect(spot!.position.dx, closeTo(0.75, 0.03));
      expect(spot.position.dy, closeTo(0.25, 0.03));
      expect(spot.intensity, closeTo(1.0, 0.01));
    });

    test('langit gelap tanpa cahaya tidak menghasilkan apa-apa', () {
      expect(
        brightestSpot(frame(), width: 640, height: 480, bytesPerRow: 640),
        isNull,
      );
    });

    test(
      'bingkai terang merata ditolak, bukan dianggap satu lampu raksasa',
      () {
        // Siang bolong: semuanya terang, jadi tidak ada satu sumber cahaya.
        final spot = brightestSpot(
          frame(background: 250, spotX: 300, spotY: 200, spotValue: 255),
          width: 640,
          height: 480,
          bytesPerRow: 640,
        );
        expect(spot, isNull, reason: 'kontrasnya terlalu kecil');
      },
    );

    test('pemandangan siang hari ditolak walau ada titik paling terang', () {
      // Terukur di emulator: latar terang merata memberi kontras sekitar 51,
      // dan siang hari berhenti di sekitar 60 sampai 90. Lampu malam jauh di
      // atas itu, jadi ambangnya memisahkan keduanya.
      final spot = brightestSpot(
        frame(background: 175, spotX: 300, spotY: 200, spotValue: 255),
        width: 640,
        height: 480,
        bytesPerRow: 640,
      );
      expect(spot, isNull, reason: 'kontras sekitar 80, di bawah ambang 90');
    });

    test('lampu jalan di langit malam tetap lolos', () {
      final spot = brightestSpot(
        frame(background: 28, spotX: 200, spotY: 300),
        width: 640,
        height: 480,
        bytesPerRow: 640,
      );
      expect(spot, isNotNull);
      expect(spot!.contrast * 255, greaterThan(150));
    });

    test('cahaya redup di bawah ambang diabaikan', () {
      expect(
        brightestSpot(
          frame(spotX: 300, spotY: 200, spotValue: 180),
          width: 640,
          height: 480,
          bytesPerRow: 640,
        ),
        isNull,
      );
    });

    test('menghormati bytesPerRow yang lebih lebar dari width', () {
      // Sebagian perangkat memberi baris berisi padding di belakang piksel.
      const w = 100, h = 80, stride = 128;
      final data = Uint8List(stride * h)..fillRange(0, stride * h, 10);
      for (var y = 38; y < 44; y++) {
        for (var x = 48; x < 54; x++) {
          data[y * stride + x] = 255;
        }
      }
      final spot = brightestSpot(
        data,
        width: w,
        height: h,
        bytesPerRow: stride,
        samples: 100000,
      );
      expect(spot, isNotNull);
      expect(spot!.position.dx, closeTo(0.5, 0.06));
      expect(spot.position.dy, closeTo(0.5, 0.06));
    });

    test('bingkai kosong tidak membuat crash', () {
      expect(
        brightestSpot(Uint8List(0), width: 0, height: 0, bytesPerRow: 0),
        isNull,
      );
    });

    test('jumlah piksel yang dibaca tidak ikut membengkak dengan resolusi', () {
      // Bukti bahwa pencariannya mencuplik: 4K diproses tanpa menunggu lama.
      final sw = Stopwatch()..start();
      brightestSpot(
        frame(width: 3840, height: 2160, spotX: 2000, spotY: 1000),
        width: 3840,
        height: 2160,
        bytesPerRow: 3840,
      );
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(80));
    });
  });

  group('memetakan sensor ke pratinjau', () {
    test('tanpa putaran, koordinatnya tetap', () {
      expect(
        sensorToPreview(const Offset(0.25, 0.75), sensorOrientation: 0),
        const Offset(0.25, 0.75),
      );
    });

    test(
      'putaran 90 derajat memindahkan kiri-atas sensor ke kanan-atas layar',
      () {
        final p = sensorToPreview(Offset.zero, sensorOrientation: 90);
        expect(p.dx, closeTo(1, 1e-9));
        expect(p.dy, closeTo(0, 1e-9));
      },
    );

    test('putaran 90 derajat, kanan-atas sensor jadi kanan-bawah layar', () {
      final p = sensorToPreview(const Offset(1, 0), sensorOrientation: 90);
      expect(p.dx, closeTo(1, 1e-9));
      expect(p.dy, closeTo(1, 1e-9));
    });

    test('putaran 270 derajat adalah kebalikan dari 90', () {
      const s = Offset(0.3, 0.8);
      final a = sensorToPreview(s, sensorOrientation: 90);
      final b = sensorToPreview(a, sensorOrientation: 270);
      expect(b.dx, closeTo(s.dx, 1e-9));
      expect(b.dy, closeTo(s.dy, 1e-9));
    });

    test('putaran 180 derajat membalik kedua sumbu', () {
      final p = sensorToPreview(const Offset(0.2, 0.3), sensorOrientation: 180);
      expect(p.dx, closeTo(0.8, 1e-9));
      expect(p.dy, closeTo(0.7, 1e-9));
    });

    test('kamera depan dicerminkan mendatar', () {
      final p = sensorToPreview(
        const Offset(0.25, 0.4),
        sensorOrientation: 0,
        mirrored: true,
      );
      expect(p.dx, closeTo(0.75, 1e-9));
      expect(p.dy, closeTo(0.4, 1e-9));
    });

    test('hasilnya selalu di dalam bingkai', () {
      for (final o in [0, 90, 180, 270]) {
        for (final s in [
          Offset.zero,
          const Offset(1, 1),
          const Offset(0.5, 0.5),
        ]) {
          final p = sensorToPreview(s, sensorOrientation: o);
          expect(p.dx, inInclusiveRange(0, 1));
          expect(p.dy, inInclusiveRange(0, 1));
        }
      }
    });
  });
}
