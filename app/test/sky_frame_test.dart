import 'dart:ui' show Size;

import 'package:constella_app/sky/sky_math.dart';
import 'package:constella_app/sky/sky_projection.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pembacaan sensor untuk ponsel yang ditegakkan, layar menghadap pengguna,
/// sisi atas ke atas, dan kamera belakang menghadap utara mendatar.
///
/// Dalam keadaan itu arah atas dunia jatuh di sumbu +y perangkat, dan utara
/// dunia di sumbu -z perangkat.
SkyFrame get _tegakMenghadapUtara => lookFrame(
  ax: 0, ay: 9.81, az: 0,
  mx: 0, my: 0, mz: -25,
)!;

void main() {
  group('lookFrame', () {
    test('ponsel telentang di meja memandang ke bawah', () {
      // Layar menghadap langit: atas dunia di +z perangkat, utara di +y.
      final f = lookFrame(ax: 0, ay: 0, az: 9.81, mx: 0, my: 25, mz: 0)!;

      expect(f.forward.u, closeTo(-1, 1e-9), reason: 'kamera menghadap meja');
      expect(f.right.e, closeTo(1, 1e-9), reason: 'kanan layar ke timur');
      expect(f.up.n, closeTo(1, 1e-9), reason: 'atas layar ke utara');
    });

    test('ponsel tegak menghadap utara', () {
      final f = _tegakMenghadapUtara;

      expect(f.forward.n, closeTo(1, 1e-9));
      expect(f.right.e, closeTo(1, 1e-9));
      expect(f.up.u, closeTo(1, 1e-9));
    });

    test('ketiga sumbunya ortonormal', () {
      final f = lookFrame(ax: 1.4, ay: 7.2, az: 6.1, mx: -12, my: 30, mz: 8)!;

      for (final v in [f.forward, f.right, f.up]) {
        expect(dot(v, v), closeTo(1, 1e-9), reason: 'panjangnya satu');
      }
      expect(dot(f.forward, f.right), closeTo(0, 1e-9));
      expect(dot(f.forward, f.up), closeTo(0, 1e-9));
      expect(dot(f.right, f.up), closeTo(0, 1e-9));
    });

    test('jatuh bebas tidak memberi kerangka', () {
      expect(lookFrame(ax: 0, ay: 0, az: 0, mx: 0, my: 25, mz: 0), isNull);
    });

    test('magnet sejajar gravitasi tidak memberi kerangka', () {
      expect(lookFrame(ax: 0, ay: 0, az: 9.81, mx: 0, my: 0, mz: 40), isNull);
    });

    test('sepakat dengan lookDirection soal arah bidikan', () {
      const a = (x: 1.4, y: 7.2, z: 6.1), m = (x: -12.0, y: 30.0, z: 8.0);
      final f = lookFrame(ax: a.x, ay: a.y, az: a.z, mx: m.x, my: m.y, mz: m.z)!;
      final d = lookDirection(
        ax: a.x, ay: a.y, az: a.z, mx: m.x, my: m.y, mz: m.z,
      )!;

      // Vektor maju kerangka harus menunjuk ke arah yang sama dengan arah
      // bidikan; kalau keduanya berbeda, gambar langit akan meleset dari nama
      // bintang yang disebut layar.
      expect(dot(f.forward, unitFromHorizontal(d)), closeTo(1, 1e-9));
    });
  });

  group('unitFromHorizontal', () {
    test('utara, timur, dan zenit jatuh di sumbunya masing-masing', () {
      expect(unitFromHorizontal((altitude: 0, azimuth: 0)).n, closeTo(1, 1e-9));
      expect(unitFromHorizontal((altitude: 0, azimuth: 90)).e, closeTo(1, 1e-9));
      expect(unitFromHorizontal((altitude: 90, azimuth: 0)).u, closeTo(1, 1e-9));
    });
  });

  group('projectToScreen', () {
    const size = Size(400, 800);
    final focal = focalFor(size);

    test('arah tepat di bidikan jatuh di tengah layar', () {
      final p = projectToScreen(
        direction: unitFromHorizontal((altitude: 0, azimuth: 0)),
        frame: _tegakMenghadapUtara,
        size: size,
        focal: focal,
      )!;

      expect(p.dx, closeTo(200, 1e-6));
      expect(p.dy, closeTo(400, 1e-6));
    });

    test('setengah bidang pandang jatuh tepat di tepi layar', () {
      final p = projectToScreen(
        direction: unitFromHorizontal(
          (altitude: 0, azimuth: defaultHorizontalFovDeg / 2),
        ),
        frame: _tegakMenghadapUtara,
        size: size,
        focal: focal,
      )!;

      expect(p.dx, closeTo(400, 1e-6), reason: 'tepi kanan');
      expect(p.dy, closeTo(400, 1e-6));
    });

    test('yang lebih tinggi digambar lebih ke atas layar', () {
      final atas = projectToScreen(
        direction: unitFromHorizontal((altitude: 20, azimuth: 0)),
        frame: _tegakMenghadapUtara,
        size: size,
        focal: focal,
      )!;

      expect(atas.dy, lessThan(400));
      expect(atas.dx, closeTo(200, 1e-6));
    });

    test('timur ada di kanan saat menghadap utara', () {
      final timur = projectToScreen(
        direction: unitFromHorizontal((altitude: 0, azimuth: 20)),
        frame: _tegakMenghadapUtara,
        size: size,
        focal: focal,
      )!;

      expect(timur.dx, greaterThan(200));
    });

    test('yang di belakang punggung tidak digambar', () {
      final belakang = projectToScreen(
        direction: unitFromHorizontal((altitude: 0, azimuth: 180)),
        frame: _tegakMenghadapUtara,
        size: size,
        focal: focal,
      );

      expect(belakang, isNull);
    });
  });

  group('starRadiusFor', () {
    test('makin terang makin besar', () {
      expect(starRadiusFor(-1.44), greaterThan(starRadiusFor(1.0)));
      expect(starRadiusFor(1.0), greaterThan(starRadiusFor(4.0)));
    });

    test('berbatas di kedua ujungnya', () {
      expect(starRadiusFor(-30), lessThanOrEqualTo(starRadiusFor(-1.5)));
      expect(starRadiusFor(30), greaterThanOrEqualTo(0.7));
    });
  });
}
