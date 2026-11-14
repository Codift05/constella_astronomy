import 'dart:async';
import 'dart:math' as math;

import 'package:constella_app/l10n/app_localizations.dart';
import 'package:constella_app/screens/star_catcher_screen.dart';
import 'package:constella_app/sky/observer_location.dart';
import 'package:constella_app/sky/sky_math.dart';
import 'package:constella_app/sky/sky_orientation.dart';
import 'package:constella_app/sky/star_catalog.dart';
import 'package:constella_app/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Manado, tempat video pengujian direkam.
const lat = 1.474, lon = 124.845;

const sirius = Star(
  raHours: 6.75248,
  decDeg: -16.71612,
  magnitude: -1.44,
  proper: 'Sirius',
  bayer: 'α',
  constellation: 'CMa',
  spectral: 'A0m...',
  lightYears: 8.6,
);

double _rad(double d) => d * math.pi / 180;

/// Nilai akselerometer dan magnetometer yang membuat kamera belakang
/// membidik tepat ke ([altDeg], [azDeg]).
///
/// Arah atas di koordinat perangkat untuk ponsel tanpa miring samping adalah
/// (0, cos A, -sin A). Arah utara adalah (-sin Z, -sin A cos Z, -cos A cos Z),
/// yang tegak lurus terhadap arah atas, jadi kompensasi kemiringan tidak
/// mengubahnya.
({List<double> accel, List<double> mag}) sensorsAiming(
  double altDeg,
  double azDeg,
) {
  const g = 9.81;
  final a = _rad(altDeg), z = _rad(azDeg);
  return (
    accel: [0, g * math.cos(a), -g * math.sin(a)],
    mag: [-math.sin(z), -math.sin(a) * math.cos(z), -math.cos(a) * math.cos(z)],
  );
}

/// Bintang buatan yang **dijamin** berada 60 derajat di atas ufuk, tepat di
/// selatan, pada saat tes berjalan.
///
/// Memakai Sirius sungguhan membuat tes bergantung jam: dari Manado ia baru
/// terbit menjelang tengah malam, jadi tes yang lewat siang hari akan gagal
/// padahal kodenya benar.
({Star star, double altitude, double azimuth}) starOverhead() {
  final lst = localSiderealDegrees(DateTime.now().toUtc(), lon);
  return (
    star: Star(
      raHours: lst / 15, // sudut jam nol: tepat di meridian
      decDeg: lat - 30,
      magnitude: -1.44,
      proper: 'Sirius',
      bayer: 'α',
      constellation: 'CMa',
      spectral: 'A0m...',
      lightYears: 8.6,
    ),
    altitude: 60,
    azimuth: 180,
  );
}

void main() {
  late StreamController<AccelerometerEvent> accel;
  late StreamController<MagnetometerEvent> mag;
  late SkyOrientation orientation;

  setUp(() {
    accel = StreamController<AccelerometerEvent>.broadcast();
    mag = StreamController<MagnetometerEvent>.broadcast();
    orientation = SkyOrientation(
      accelerometer: accel.stream,
      magnetometer: mag.stream,
      settleTimeout: const Duration(milliseconds: 50),
    );
  });

  tearDown(() async {
    await accel.close();
    await mag.close();
  });

  Future<void> aim(WidgetTester tester, double alt, double az) async {
    final s = sensorsAiming(alt, az);
    final now = DateTime.now();
    // Dikirim beberapa kali: pembacaan pertama dipakai utuh, sisanya
    // dilicinkan low-pass sampai mendekati nilai sebenarnya.
    for (var i = 0; i < 40; i++) {
      accel.add(AccelerometerEvent(s.accel[0], s.accel[1], s.accel[2], now));
      mag.add(MagnetometerEvent(s.mag[0], s.mag[1], s.mag[2], now));
      await tester.pump(const Duration(milliseconds: 8));
    }
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    ObserverLocation? location,
    StarCatalog? catalog,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        locale: const Locale('en'),
        home: StarCatcherScreen(
          orientation: orientation,
          location: location ?? ObserverLocation.at(lat, lon),
          catalog: catalog ?? const StarCatalog([sirius]),
          enableCamera: false,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'nilai sensor buatan benar-benar menghasilkan arah yang diminta',
    (tester) async {
      for (final (alt, az) in [(0.0, 0.0), (30.0, 90.0), (65.0, 215.0)]) {
        final s = sensorsAiming(alt, az);
        final look = lookDirection(
          ax: s.accel[0],
          ay: s.accel[1],
          az: s.accel[2],
          mx: s.mag[0],
          my: s.mag[1],
          mz: s.mag[2],
        )!;
        expect(look.altitude, closeTo(alt, 1e-6), reason: 'ketinggian $alt');
        expect(look.azimuth, closeTo(az, 1e-6), reason: 'azimut $az');
      }
    },
  );

  testWidgets('membidik Sirius menampilkan nama, rasi, dan jaraknya', (
    tester,
  ) async {
    final s = starOverhead();
    await pumpScreen(tester, catalog: StarCatalog([s.star]));
    await aim(tester, s.altitude, s.azimuth);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Sirius'), findsOneWidget);
    expect(find.text('Canis Major'), findsOneWidget);
    expect(find.textContaining('8.6'), findsOneWidget);
    expect(find.textContaining('-1.44'), findsOneWidget);
  });

  testWidgets('membidik langit kosong mengatakan tidak ada bintang terang', (
    tester,
  ) async {
    final s = starOverhead();
    await pumpScreen(tester, catalog: StarCatalog([s.star]));
    // 60 derajat jauhnya dari satu-satunya bintang di katalog.
    await aim(tester, s.altitude, (s.azimuth + 60) % 360);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Sirius'), findsNothing);
    expect(find.textContaining('No bright star'), findsOneWidget);
  });

  testWidgets('pembacaan kompas menunjukkan arah mata angin', (tester) async {
    await pumpScreen(tester);
    await aim(tester, 10, 90);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('E'), findsWidgets);
  });

  testWidgets('tanpa posisi, layar menjelaskan dan menawarkan izin', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      location: ObserverLocation(timeout: Duration.zero),
    );
    // Kompasnya harus hidup lebih dulu: kalau tidak, panel "tak punya kompas"
    // yang muncul — dan itu memang urutan yang benar, karena hal itu tidak
    // bisa diperbaiki pengguna sementara izin lokasi bisa.
    await aim(tester, 20, 100);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('rough location'), findsOneWidget);
    expect(find.text('Sirius'), findsNothing);
  });

  testWidgets('tanpa magnetometer, layar mengatakan ponsel tak punya kompas', (
    tester,
  ) async {
    await pumpScreen(tester);
    // Hanya akselerometer yang melapor; magnetometer diam.
    accel.add(AccelerometerEvent(0, 9.81, 0, DateTime.now()));
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.textContaining('no compass'), findsOneWidget);
  });

  testWidgets('bintang paling terang menang saat dua bintang berdekatan', (
    tester,
  ) async {
    final s = starOverhead();
    final redup = Star(
      raHours: s.star.raHours + 0.12,
      decDeg: s.star.decDeg + 1.5,
      magnitude: 4.8,
      proper: 'Redup',
      bayer: 'ι',
      constellation: 'CMa',
      spectral: 'B3',
      lightYears: 300,
    );
    await pumpScreen(tester, catalog: StarCatalog([s.star, redup]));
    await aim(tester, s.altitude, s.azimuth);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Sirius'), findsOneWidget);
    expect(find.text('Redup'), findsNothing);
  });
}
