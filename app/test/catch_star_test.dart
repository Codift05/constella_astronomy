import 'dart:async';
import 'dart:math' as math;

import 'package:constella_app/data/app_database.dart';
import 'package:constella_app/l10n/app_localizations.dart';
import 'package:constella_app/screens/star_catcher_screen.dart';
import 'package:constella_app/sky/caught_stars_store.dart';
import 'package:constella_app/sky/observer_location.dart';
import 'package:constella_app/sky/sky_math.dart';
import 'package:constella_app/sky/sky_orientation.dart';
import 'package:constella_app/sky/star_catalog.dart';
import 'package:constella_app/stardust/stardust_rules.dart';
import 'package:constella_app/stardust/stardust_store.dart';
import 'package:constella_app/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const lat = 1.474, lon = 124.845;

double _rad(double d) => d * math.pi / 180;

/// Bintang yang dijamin 60 derajat di atas ufuk, tepat di selatan, saat tes
/// berjalan. Memakai posisi Sirius sungguhan membuat tes bergantung jam.
({Star star, double altitude, double azimuth}) starOverhead() {
  final lst = localSiderealDegrees(DateTime.now().toUtc(), lon);
  return (
    star: Star(
      raHours: lst / 15,
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

({List<double> accel, List<double> mag}) sensorsAiming(double alt, double az) {
  const g = 9.81;
  final a = _rad(alt), z = _rad(az);
  return (
    accel: [0, g * math.cos(a), -g * math.sin(a)],
    mag: [
      -math.sin(z),
      -math.sin(a) * math.cos(z),
      -math.cos(a) * math.cos(z),
    ],
  );
}

void main() {
  sqfliteFfiInit();

  late Database db;
  late CaughtStarsStore caught;
  late StardustStore stardust;
  late StreamController<AccelerometerEvent> accel;
  late StreamController<MagnetometerEvent> mag;
  late SkyOrientation orientation;

  setUp(() async {
    await databaseFactoryFfi.deleteDatabase(inMemoryDatabasePath);
    db = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    caught = CaughtStarsStore(db);
    stardust = StardustStore(db);
    await Future.wait([caught.load(), stardust.load()]);

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
    for (var i = 0; i < 40; i++) {
      accel.add(AccelerometerEvent(s.accel[0], s.accel[1], s.accel[2], now));
      mag.add(MagnetometerEvent(s.mag[0], s.mag[1], s.mag[2], now));
      await tester.pump(const Duration(milliseconds: 8));
    }
  }

  Future<void> pumpScreen(WidgetTester tester, Star star) async {
    await tester.pumpWidget(
      CaughtStarsScope(
        notifier: caught,
        child: StardustScope(
          notifier: stardust,
          child: MaterialApp(
            theme: buildAppTheme(Brightness.dark),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            locale: const Locale('en'),
            home: StarCatcherScreen(
              orientation: orientation,
              location: ObserverLocation.at(lat, lon),
              catalog: StarCatalog([star]),
              enableCamera: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> tapCatch(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.tap(find.text('Catch this star'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await tester.pump();
    });
    await tester.pump(const Duration(milliseconds: 700));
  }

  group('menangkap bintang', () {
    testWidgets('mengarahkan saja belum menangkap apa pun', (tester) async {
      final s = starOverhead();
      await pumpScreen(tester, s.star);
      await aim(tester, s.altitude, s.azimuth);
      await tester.pump(const Duration(milliseconds: 400));

      // Kartu pratinjau muncul, tapi perayaan belum.
      expect(find.text('Catch this star'), findsOneWidget);
      expect(find.text('Caught!'), findsNothing);
      expect(caught.count, 0);
      expect(stardust.energy, 0);
    });

    testWidgets('mengetuk tangkap memunculkan perayaan dan memberi Stardust', (
      tester,
    ) async {
      final s = starOverhead();
      await pumpScreen(tester, s.star);
      await aim(tester, s.altitude, s.azimuth);
      await tester.pump(const Duration(milliseconds: 400));
      await tapCatch(tester);

      expect(find.text('Caught!'), findsOneWidget);
      expect(find.textContaining('Claim'), findsOneWidget);
      expect(caught.count, 1);
      expect(caught.has('Sirius'), isTrue);
      expect(stardust.energy, StardustRules.perStarCaught(-1.44));
    });

    testWidgets('perayaan menampilkan ketiga kartu data', (tester) async {
      final s = starOverhead();
      await pumpScreen(tester, s.star);
      await aim(tester, s.altitude, s.azimuth);
      await tester.pump(const Duration(milliseconds: 400));
      await tapCatch(tester);

      expect(find.text('DISTANCE'), findsOneWidget);
      expect(find.text('BRIGHTNESS'), findsOneWidget);
      expect(find.text('CONSTELLATION'), findsOneWidget);
      expect(find.textContaining('8.6'), findsOneWidget);
    });

    testWidgets('bintang yang sama tidak memberi Stardust dua kali', (
      tester,
    ) async {
      final s = starOverhead();
      // I/O sqflite sungguhan hanya selesai di luar zona FakeAsync.
      await tester.runAsync(() => caught.catchStar(s.star));
      await pumpScreen(tester, s.star);
      await aim(tester, s.altitude, s.azimuth);
      await tester.pump(const Duration(milliseconds: 400));

      // Tombolnya berubah jadi keterangan, bukan ajakan.
      expect(find.text('Already in your collection'), findsWidgets);
      await tester.runAsync(() async {
        await tester.tap(find.text('Already in your collection').first);
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 120));
        await tester.pump();
      });
      await tester.pump(const Duration(milliseconds: 700));

      expect(stardust.energy, 0, reason: 'tidak ada hadiah ulangan');
      expect(caught.count, 1, reason: 'tidak ada duplikat di koleksi');
    });

    testWidgets('menutup perayaan mengembalikan bidikan', (tester) async {
      final s = starOverhead();
      await pumpScreen(tester, s.star);
      await aim(tester, s.altitude, s.azimuth);
      await tester.pump(const Duration(milliseconds: 400));
      await tapCatch(tester);
      expect(find.text('Caught!'), findsOneWidget);

      await tester.tap(find.textContaining('Claim'));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Caught!'), findsNothing);
      expect(find.text('Already in your collection'), findsWidgets);
    });
  });

  group('koleksi bertahan', () {
    test('bintang tersimpan terbaca lagi setelah dimuat ulang', () async {
      final s = starOverhead();
      await caught.catchStar(s.star);

      final reopened = CaughtStarsStore(db);
      await reopened.load();
      expect(reopened.has('Sirius'), isTrue);
      expect(reopened.count, 1);
    });

    test('menangkap dua kali hanya menyimpan satu baris', () async {
      final s = starOverhead();
      expect(await caught.catchStar(s.star), CatchOutcome.caught);
      expect(await caught.catchStar(s.star), CatchOutcome.alreadyHad);
      expect(caught.count, 1);
      expect((await caught.all()).length, 1);
    });

    test('koleksi mengembalikan data lengkap bintangnya', () async {
      await caught.catchStar(starOverhead().star);
      final all = await caught.all();
      expect(all.single.name, 'Sirius');
      expect(all.single.constellation, 'CMa');
      expect(all.single.lightYears, closeTo(8.6, 0.01));
    });
  });
}
