import 'package:constella_app/sky/star_catalog.dart';
import 'package:constella_app/sky/view_description.dart';
import 'package:flutter_test/flutter_test.dart';

const sirius = Star(
  raHours: 6.75, decDeg: -16.7, magnitude: -1.44, proper: 'Sirius',
  bayer: 'α', constellation: 'CMa', spectral: 'A0m', lightYears: 8.6,
);
const redup = Star(
  raHours: 5.9, decDeg: -17.8, magnitude: 4.2, proper: 'Redup',
  bayer: 'ι', constellation: 'Ori', spectral: 'B3', lightYears: 300,
);

void main() {
  group('arah mata angin', () {
    test('memetakan sudut ke delapan arah', () {
      expect(compassPointFor(0), 'N');
      expect(compassPointFor(45), 'NE');
      expect(compassPointFor(90), 'E');
      expect(compassPointFor(180), 'S');
      expect(compassPointFor(270), 'W');
      expect(compassPointFor(315), 'NW');
    });

    test('membulat ke arah terdekat', () {
      expect(compassPointFor(22), 'N');
      expect(compassPointFor(23), 'NE');
      expect(compassPointFor(359), 'N');
    });

    test('tahan terhadap sudut di luar 0 sampai 360', () {
      expect(compassPointFor(360), 'N');
      expect(compassPointFor(-90), 'W');
      expect(compassPointFor(450), 'E');
    });
  });

  group('keterangan arah pandang', () {
    test('menyebut bintang paling terang di dalam bingkai', () {
      final d = describeView(
        look: (altitude: 40.0, azimuth: 120.0),
        sky: [
          (star: sirius, point: (altitude: 42.0, azimuth: 122.0)),
          (star: redup, point: (altitude: 38.0, azimuth: 118.0)),
        ],
      );
      expect(d.brightest?.proper, 'Sirius');
      expect(d.constellation, 'Canis Major');
    });

    test('mengabaikan bintang di luar bidang pandang', () {
      final d = describeView(
        look: (altitude: 40.0, azimuth: 120.0),
        // Sirius 80 derajat jauhnya: tidak mungkin ada di foto.
        sky: [(star: sirius, point: (altitude: 40.0, azimuth: 200.0))],
      );
      expect(d.brightest, isNull);
      expect(d.constellation, isNull);
    });

    test('mengabaikan bintang di bawah ufuk', () {
      final d = describeView(
        look: (altitude: -5.0, azimuth: 120.0),
        sky: [(star: sirius, point: (altitude: -3.0, azimuth: 120.0))],
      );
      expect(d.brightest, isNull);
    });

    test('langit kosong tetap memberi arah dan ketinggian', () {
      final d = describeView(
        look: (altitude: 12.0, azimuth: 95.0),
        sky: const [],
      );
      expect(d.brightest, isNull);
      expect(d.compassPoint, 'E');
      expect(d.altitude, 12);
      expect(d.aboveHorizon, isTrue);
    });

    test('menunduk di bawah ufuk ditandai', () {
      final d = describeView(
        look: (altitude: -20.0, azimuth: 0.0),
        sky: const [],
      );
      expect(d.aboveHorizon, isFalse);
    });

    test('azimut dinormalkan ke 0 sampai 360', () {
      final d = describeView(
        look: (altitude: 0.0, azimuth: 400.0),
        sky: const [],
      );
      expect(d.azimuth, closeTo(40, 1e-9));
    });

    test('bidang pandang sempit menyingkirkan bintang di tepi', () {
      final sky = [(star: sirius, point: (altitude: 40.0, azimuth: 135.0))];
      expect(
        describeView(
          look: (altitude: 40.0, azimuth: 120.0),
          sky: sky,
          fovDeg: 45,
        ).brightest,
        isNotNull,
      );
      expect(
        describeView(
          look: (altitude: 40.0, azimuth: 120.0),
          sky: sky,
          fovDeg: 20,
        ).brightest,
        isNull,
      );
    });
  });
}
