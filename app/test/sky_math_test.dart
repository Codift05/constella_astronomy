import 'dart:math' as math;

import 'package:constella_app/sky/sky_math.dart';
import 'package:flutter_test/flutter_test.dart';

/// Waktu acuan yang dipakai beberapa tes; nilainya tidak istimewa.
final _t = DateTime.utc(2026, 11, 14, 11, 30);

void main() {
  group('julianDay', () {
    test('epoch J2000 tepat 2451545.0', () {
      expect(julianDay(DateTime.utc(2000, 1, 1, 12)), closeTo(2451545.0, 1e-9));
    });

    test('tengah malam setengah hari sebelum tengah hari', () {
      expect(julianDay(DateTime.utc(2000, 1, 1)), closeTo(2451544.5, 1e-9));
    });

    test('maju tepat satu per hari', () {
      final a = julianDay(DateTime.utc(2026, 3, 1, 7));
      final b = julianDay(DateTime.utc(2026, 3, 2, 7));
      expect(b - a, closeTo(1.0, 1e-9));
    });

    test('tahun kabisat tidak membuat lompatan', () {
      final a = julianDay(DateTime.utc(2024, 2, 28, 12));
      final b = julianDay(DateTime.utc(2024, 2, 29, 12));
      final c = julianDay(DateTime.utc(2024, 3, 1, 12));
      expect(b - a, closeTo(1.0, 1e-9));
      expect(c - b, closeTo(1.0, 1e-9));
    });

    test('waktu lokal dikonversi ke UTC lebih dulu', () {
      final utc = DateTime.utc(2026, 5, 4, 3);
      expect(julianDay(utc.toLocal()), closeTo(julianDay(utc), 1e-9));
    });
  });

  group('waktu sideris', () {
    test('satu hari sideris lebih pendek dari hari matahari', () {
      // Langit kembali ke posisi semula setelah 23 jam 56 menit 4 detik.
      final a = greenwichSiderealDegrees(_t);
      final b = greenwichSiderealDegrees(
        _t.add(const Duration(hours: 23, minutes: 56, seconds: 4)),
      );
      expect((b - a).abs() % 360, lessThan(0.05));
    });

    test('bertambah hampir 361 derajat per hari matahari', () {
      final a = greenwichSiderealDegrees(_t);
      final b = greenwichSiderealDegrees(_t.add(const Duration(days: 1)));
      expect(normalize360(b - a), closeTo(0.9856, 0.01));
    });

    test('bujur timur memajukan waktu sideris lokal', () {
      final g = greenwichSiderealDegrees(_t);
      expect(localSiderealDegrees(_t, 90), closeTo(normalize360(g + 90), 1e-9));
    });

    test('selalu berada di dalam 0 sampai 360', () {
      for (var h = 0; h < 48; h += 3) {
        final v = greenwichSiderealDegrees(_t.add(Duration(hours: h)));
        expect(v, inInclusiveRange(0, 360));
      }
    });
  });

  group('ekuatorial ke horizontal', () {
    /// Ketinggian kutub langit **selalu** sama dengan lintang pengamat.
    /// Inilah sebabnya Polaris tampak makin tinggi saat bergerak ke utara,
    /// dan ini invarian terkuat untuk memeriksa rumusnya.
    test('kutub langit berada setinggi lintang pengamat', () {
      for (final lat in [-60.0, -23.5, 0.0, 1.47, 45.0, 70.0]) {
        for (var h = 0; h < 24; h += 5) {
          final p = horizontalFromEquatorial(
            raHours: 0,
            decDeg: 90,
            latitudeDeg: lat,
            longitudeDeg: 124.84,
            utc: _t.add(Duration(hours: h)),
          );
          expect(p.altitude, closeTo(lat, 1e-6), reason: 'lintang $lat jam $h');
        }
      }
    });

    test(
      'di khatulistiwa, bintang di meridian dengan deklinasi negatif ada di selatan',
      () {
        const lat = 0.0, lon = 0.0;
        final lst = localSiderealDegrees(_t, lon);
        final p = horizontalFromEquatorial(
          raHours: lst / 15, // sudut jam nol: tepat di meridian
          decDeg: -30,
          latitudeDeg: lat,
          longitudeDeg: lon,
          utc: _t,
        );
        expect(p.azimuth, closeTo(180, 1e-4));
        expect(p.altitude, closeTo(60, 1e-4));
      },
    );

    test('di khatulistiwa, deklinasi positif di meridian ada di utara', () {
      const lon = 0.0;
      final lst = localSiderealDegrees(_t, lon);
      final p = horizontalFromEquatorial(
        raHours: lst / 15,
        decDeg: 30,
        latitudeDeg: 0,
        longitudeDeg: lon,
        utc: _t,
      );
      expect(p.azimuth, closeTo(0, 1e-4));
      expect(p.altitude, closeTo(60, 1e-4));
    });

    test('sudut jam enam jam menaruh bintang khatulistiwa di barat', () {
      const lon = 0.0;
      final lst = localSiderealDegrees(_t, lon);
      final p = horizontalFromEquatorial(
        raHours: (lst / 15 - 6 + 24) % 24, // bintang 6 jam di barat meridian
        decDeg: 0,
        latitudeDeg: 0,
        longitudeDeg: lon,
        utc: _t,
      );
      expect(p.azimuth, closeTo(270, 1e-4));
      expect(p.altitude, closeTo(0, 1e-4));
    });

    test(
      'bintang di meridian tepat di atas kepala saat deklinasi sama dengan lintang',
      () {
        const lat = 1.47; // Manado
        const lon = 124.84;
        final lst = localSiderealDegrees(_t, lon);
        final p = horizontalFromEquatorial(
          raHours: lst / 15,
          decDeg: lat,
          latitudeDeg: lat,
          longitudeDeg: lon,
          utc: _t,
        );
        expect(p.altitude, closeTo(90, 1e-4));
      },
    );

    test('hasilnya selalu di rentang yang sah', () {
      final rng = math.Random(7);
      for (var i = 0; i < 400; i++) {
        final p = horizontalFromEquatorial(
          raHours: rng.nextDouble() * 24,
          decDeg: rng.nextDouble() * 180 - 90,
          latitudeDeg: rng.nextDouble() * 180 - 90,
          longitudeDeg: rng.nextDouble() * 360 - 180,
          utc: _t.add(Duration(minutes: rng.nextInt(100000))),
        );
        expect(p.altitude, inInclusiveRange(-90, 90));
        expect(p.azimuth, inInclusiveRange(0, 360));
        expect(p.altitude.isFinite && p.azimuth.isFinite, isTrue);
      }
    });

    test('bintang terbit lebih awal setiap malam', () {
      // Pada waktu matahari yang sama esok hari, bintang sudah bergerak
      // ke barat sekitar satu derajat.
      const lat = 1.47, lon = 124.84;
      final a = horizontalFromEquatorial(
        raHours: 6.75,
        decDeg: -16.7,
        latitudeDeg: lat,
        longitudeDeg: lon,
        utc: _t,
      );
      final b = horizontalFromEquatorial(
        raHours: 6.75,
        decDeg: -16.7,
        latitudeDeg: lat,
        longitudeDeg: lon,
        utc: _t.add(const Duration(days: 1)),
      );
      expect(a.azimuth, isNot(closeTo(b.azimuth, 1e-6)));
    });
  });

  group('jarak sudut', () {
    test('titik yang sama berjarak nol', () {
      const p = (altitude: 42.0, azimuth: 137.0);
      expect(angularSeparation(p, p), closeTo(0, 1e-9));
    });

    test('zenit ke ufuk berjarak 90 derajat', () {
      expect(
        angularSeparation(
          (altitude: 90.0, azimuth: 0.0),
          (altitude: 0.0, azimuth: 211.0),
        ),
        closeTo(90, 1e-9),
      );
    });

    test('utara ke timur di ufuk berjarak 90 derajat', () {
      expect(
        angularSeparation(
          (altitude: 0.0, azimuth: 0.0),
          (altitude: 0.0, azimuth: 90.0),
        ),
        closeTo(90, 1e-9),
      );
    });

    test('azimut yang berputar penuh tidak mengubah jarak', () {
      expect(
        angularSeparation(
          (altitude: 10.0, azimuth: 5.0),
          (altitude: 10.0, azimuth: 365.0),
        ),
        closeTo(0, 1e-6),
      );
    });

    test('simetris', () {
      const a = (altitude: 12.0, azimuth: 30.0);
      const b = (altitude: -5.0, azimuth: 200.0);
      expect(angularSeparation(a, b), closeTo(angularSeparation(b, a), 1e-9));
    });
  });

  group('arah bidikan perangkat', () {
    const g = 9.81;

    test('tegak menghadap utara', () {
      // Medan magnet mendatar menuju utara: utara ada di arah -z perangkat.
      final p = lookDirection(ax: 0, ay: g, az: 0, mx: 0, my: 0, mz: -1);
      expect(p!.altitude, closeTo(0, 1e-6));
      expect(p.azimuth, closeTo(0, 1e-6));
    });

    test('tegak menghadap timur', () {
      // Menghadap timur, utara ada di sebelah kiri, yaitu -x perangkat.
      final p = lookDirection(ax: 0, ay: g, az: 0, mx: -1, my: 0, mz: 0);
      expect(p!.azimuth, closeTo(90, 1e-6));
    });

    test('tegak menghadap barat', () {
      final p = lookDirection(ax: 0, ay: g, az: 0, mx: 1, my: 0, mz: 0);
      expect(p!.azimuth, closeTo(270, 1e-6));
    });

    test('menengadah 30 derajat', () {
      final c = g * math.cos(30 * math.pi / 180);
      final s = g * math.sin(30 * math.pi / 180);
      final p = lookDirection(ax: 0, ay: c, az: -s, mx: 0, my: 0, mz: -1);
      expect(p!.altitude, closeTo(30, 1e-6));
    });

    test('menunduk 45 derajat', () {
      final c = g * math.cos(45 * math.pi / 180);
      final p = lookDirection(ax: 0, ay: c, az: c, mx: 0, my: 0, mz: -1);
      expect(p!.altitude, closeTo(-45, 1e-6));
    });

    test('kemiringan medan magnet tidak menggeser azimut', () {
      // Di lintang menengah medan magnet menukik ke bawah. Kompas yang
      // dikompensasi kemiringan harus mengabaikan komponen itu.
      final tegak = lookDirection(ax: 0, ay: g, az: 0, mx: 0, my: 0, mz: -1)!;
      final menukik = lookDirection(
        ax: 0,
        ay: g,
        az: 0,
        mx: 0,
        my: -0.6,
        mz: -1,
      )!;
      expect(menukik.azimuth, closeTo(tegak.azimuth, 1e-6));
    });

    test('jatuh bebas tidak punya arah', () {
      expect(lookDirection(ax: 0, ay: 0, az: 0, mx: 0, my: 0, mz: -1), isNull);
    });

    test('magnet sejajar gravitasi tidak punya arah timur', () {
      expect(lookDirection(ax: 0, ay: g, az: 0, mx: 0, my: 5, mz: 0), isNull);
    });

    test('besar medan magnet tidak memengaruhi hasil', () {
      final a = lookDirection(ax: 0, ay: g, az: 0, mx: 0, my: 0, mz: -1)!;
      final b = lookDirection(ax: 0, ay: g, az: 0, mx: 0, my: 0, mz: -48)!;
      expect(b.azimuth, closeTo(a.azimuth, 1e-9));
    });
  });
}
