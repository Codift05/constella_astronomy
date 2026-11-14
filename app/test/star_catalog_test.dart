import 'dart:io';

import 'package:constella_app/sky/sky_math.dart';
import 'package:constella_app/sky/star_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// Katalog diurai dari berkas aset yang sama yang dibundel ke aplikasi,
/// dibaca lewat dart:io supaya tes ini tidak bergantung pada rootBundle.
late StarCatalog catalog;

Star byName(String name) => catalog.stars.firstWhere((s) => s.proper == name);

void main() {
  setUpAll(() {
    catalog = StarCatalog(
      StarCatalog.parse(File(StarCatalog.assetPath).readAsStringSync()),
    );
  });

  group('katalog', () {
    test('memuat ribuan bintang', () {
      expect(catalog.stars.length, greaterThan(1500));
    });

    test('Sirius ada dan nilainya benar', () {
      final s = byName('Sirius');
      expect(s.raHours, closeTo(6.7525, 0.001));
      expect(s.decDeg, closeTo(-16.716, 0.001));
      expect(s.magnitude, closeTo(-1.44, 0.01));
      expect(s.lightYears, closeTo(8.6, 0.1));
      expect(s.constellation, 'CMa');
      expect(s.constellationName, 'Canis Major');
    });

    test('Sirius adalah bintang paling terang di katalog', () {
      final brightest = catalog.stars.reduce(
        (a, b) => a.magnitude <= b.magnitude ? a : b,
      );
      expect(brightest.proper, 'Sirius');
    });

    test('bintang terkenal lain ikut terbawa', () {
      for (final n in ['Canopus', 'Vega', 'Betelgeuse', 'Rigel', 'Polaris']) {
        expect(
          catalog.stars.any((s) => s.proper == n),
          isTrue,
          reason: '$n tidak ada di katalog',
        );
      }
    });

    test('semua nilainya berada di rentang yang sah', () {
      for (final s in catalog.stars) {
        expect(s.raHours, inInclusiveRange(0, 24));
        expect(s.decDeg, inInclusiveRange(-90, 90));
        expect(s.magnitude, lessThanOrEqualTo(5.0));
        expect(s.lightYears, greaterThanOrEqualTo(0));
      }
    });

    test('nama tampilan jatuh ke sebutan Bayer saat tanpa nama diri', () {
      final tanpaNama = catalog.stars.firstWhere(
        (s) => s.proper.isEmpty && s.bayer.isNotEmpty,
      );
      expect(tanpaNama.displayName, contains(tanpaNama.bayer));
      expect(tanpaNama.displayName, contains(tanpaNama.constellation));
    });

    test('baris rusak dilewati, bukan menggagalkan seluruh pemuatan', () {
      final stars = StarCatalog.parse(
        'ra,dec,mag,proper,bayer,con,spect,ly\n'
        'bukan angka,0,0,X,,Ori,A0,1\n'
        '\n'
        'terlalu,sedikit,kolom\n'
        '6.75,-16.7,-1.44,Sirius,α,CMa,A0m,8.6\n',
      );
      expect(stars.length, 1);
      expect(stars.single.proper, 'Sirius');
    });
  });

  group('Sirius dilihat dari Manado', () {
    const lat = 1.47, lon = 124.84;

    test('puncak ketinggiannya sesuai rumus 90 dikurangi beda lintang', () {
      // Ketinggian maksimum sebuah bintang = 90 - |lintang - deklinasi|.
      final s = byName('Sirius');
      final expected = 90 - (lat - s.decDeg).abs();
      var peak = -90.0;
      for (var m = 0; m < 24 * 60; m += 2) {
        final p = horizontalFromEquatorial(
          raHours: s.raHours,
          decDeg: s.decDeg,
          latitudeDeg: lat,
          longitudeDeg: lon,
          utc: DateTime.utc(2026, 11, 14).add(Duration(minutes: m)),
        );
        if (p.altitude > peak) peak = p.altitude;
      }
      expect(peak, closeTo(expected, 0.05));
    });

    test('terbit dan terbenam dalam satu hari', () {
      final s = byName('Sirius');
      var above = 0, below = 0;
      for (var m = 0; m < 24 * 60; m += 10) {
        final p = horizontalFromEquatorial(
          raHours: s.raHours,
          decDeg: s.decDeg,
          latitudeDeg: lat,
          longitudeDeg: lon,
          utc: DateTime.utc(2026, 11, 14).add(Duration(minutes: m)),
        );
        p.altitude > 0 ? above++ : below++;
      }
      expect(above, greaterThan(0));
      expect(below, greaterThan(0));
    });

    test('snapshot hanya memuat bintang yang di atas ufuk', () {
      final sky = catalog.snapshot(
        latitudeDeg: lat,
        longitudeDeg: lon,
        utc: DateTime.utc(2026, 11, 14, 14),
      );
      expect(sky, isNotEmpty);
      expect(sky.length, lessThan(catalog.stars.length));
      for (final s in sky) {
        expect(s.point.altitude, greaterThan(-3));
      }
    });
  });

  group('membidik bintang', () {
    const sirius = Star(
      raHours: 6.75,
      decDeg: -16.7,
      magnitude: -1.44,
      proper: 'Sirius',
      bayer: 'α',
      constellation: 'CMa',
      spectral: 'A0m',
      lightYears: 8.6,
    );
    const redup = Star(
      raHours: 6.8,
      decDeg: -16.0,
      magnitude: 4.9,
      proper: '',
      bayer: 'ι',
      constellation: 'CMa',
      spectral: 'B3',
      lightYears: 300,
    );

    test('membidik tepat ke bintang mengembalikan bintang itu', () {
      const p = (altitude: 40.0, azimuth: 120.0);
      final hit = nearestStar([(star: sirius, point: p)], p);
      expect(hit!.star.proper, 'Sirius');
    });

    test('membidik jauh dari semua bintang mengembalikan null', () {
      final hit = nearestStar(
        [(star: sirius, point: (altitude: 40.0, azimuth: 120.0))],
        (altitude: 40.0, azimuth: 180.0),
      );
      expect(hit, isNull);
    });

    test(
      'bintang terang menang tipis atas bintang redup yang sedikit lebih dekat',
      () {
        // Bintang redup sering tidak terlihat sama sekali dari kota, jadi
        // maksud pengguna hampir selalu yang terang.
        final sky = <SightedStar>[
          (star: sirius, point: (altitude: 40.0, azimuth: 123.0)),
          (star: redup, point: (altitude: 40.0, azimuth: 121.0)),
        ];
        final hit = nearestStar(sky, (altitude: 40.0, azimuth: 120.0));
        expect(hit!.star.proper, 'Sirius');
      },
    );

    test('tapi kedekatan tetap menang kalau selisihnya besar', () {
      final sky = <SightedStar>[
        (star: sirius, point: (altitude: 40.0, azimuth: 128.0)),
        (star: redup, point: (altitude: 40.0, azimuth: 120.2)),
      ];
      final hit = nearestStar(sky, (altitude: 40.0, azimuth: 120.0));
      expect(hit!.star.proper, isEmpty);
    });

    test('langit kosong mengembalikan null', () {
      expect(nearestStar([], (altitude: 10.0, azimuth: 10.0)), isNull);
    });
  });
}
