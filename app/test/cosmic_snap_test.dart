import 'dart:typed_data';

import 'package:constella_app/l10n/app_localizations.dart';
import 'package:constella_app/screens/cosmic_snap_screen.dart';
import 'package:constella_app/sky/star_catalog.dart';
import 'package:constella_app/sky/view_description.dart';
import 'package:constella_app/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const sirius = Star(
  raHours: 6.75, decDeg: -16.7, magnitude: -1.44, proper: 'Sirius',
  bayer: 'α', constellation: 'CMa', spectral: 'A0m', lightYears: 8.6,
);

/// PNG 1x1 yang sah, cukup untuk Image.memory.
final _tinyPng = Uint8List.fromList([
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, //
  0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, //
  0, 0, 0, 10, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1, //
  13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
]);

CosmicSnap snapWith(ViewDescription view, {double? lat, double? lon}) =>
    CosmicSnap(
      image: _tinyPng,
      takenAt: DateTime(2026, 11, 15, 21, 30),
      view: view,
      latitude: lat,
      longitude: lon,
    );

Future<String> captionOf(WidgetTester tester, CosmicSnap snap) async {
  late String result;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(Brightness.dark),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (context) {
          result = snapCaption(context, snap);
          return const SizedBox();
        },
      ),
    ),
  );
  return result;
}

void main() {
  group('keterangan potret kosmik', () {
    testWidgets('menyebut rasi dan bintang paling terang di bingkai', (
      tester,
    ) async {
      final caption = await captionOf(
        tester,
        snapWith(
          describeView(
            look: (altitude: 42.0, azimuth: 130.0),
            sky: [(star: sirius, point: (altitude: 43.0, azimuth: 131.0))],
          ),
        ),
      );
      expect(caption, contains('Canis Major'));
      expect(caption, contains('42'));
      expect(caption, contains('Sirius'));
      expect(caption, contains('8.6'));
    });

    testWidgets('tanpa bintang di bingkai, tetap menyebut arah mata angin', (
      tester,
    ) async {
      final caption = await captionOf(
        tester,
        snapWith(
          describeView(
            look: (altitude: 20.0, azimuth: 90.0),
            sky: const [],
          ),
        ),
      );
      expect(caption, contains('E'));
      expect(caption, contains('20'));
      expect(caption, contains('No catalogued star'));
    });

    testWidgets('menunduk di bawah ufuk dikatakan apa adanya', (tester) async {
      final caption = await captionOf(
        tester,
        snapWith(
          describeView(
            look: (altitude: -30.0, azimuth: 180.0),
            sky: const [],
          ),
        ),
      );
      expect(caption, contains('below the horizon'));
      expect(caption, isNot(contains('above the horizon')));
    });
  });

  group('koordinat', () {
    test('ditampilkan dengan arah mata angin, bukan tanda minus', () {
      final s = snapWith(
        describeView(look: (altitude: 0.0, azimuth: 0.0), sky: const []),
        lat: 1.474,
        lon: 124.845,
      );
      expect(s.coordinates, contains('1.47°N'));
      expect(s.coordinates, contains('124.84°E'));
    });

    test('lintang selatan dan bujur barat ditandai benar', () {
      final s = snapWith(
        describeView(look: (altitude: 0.0, azimuth: 0.0), sky: const []),
        lat: -33.87,
        lon: -70.67,
      );
      expect(s.coordinates, contains('33.87°S'));
      expect(s.coordinates, contains('70.67°W'));
    });

    test('tanpa posisi, koordinatnya null dan bingkai tetap jadi', () {
      final s = snapWith(
        describeView(look: (altitude: 0.0, azimuth: 0.0), sky: const []),
      );
      expect(s.hasLocation, isFalse);
      expect(s.coordinates, isNull);
    });
  });

  group('bingkai potret', () {
    testWidgets('menampilkan foto, waktu, dan keterangannya', (tester) async {
      final s = snapWith(
        describeView(
          look: (altitude: 42.0, azimuth: 130.0),
          sky: [(star: sirius, point: (altitude: 43.0, azimuth: 131.0))],
        ),
        lat: 1.474,
        lon: 124.845,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.dark),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          locale: const Locale('en'),
          home: CosmicSnapScreen(snap: s),
        ),
      );
      await tester.pump();

      expect(find.text('Cosmic Snap'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.textContaining('2026-11-15'), findsOneWidget);
      expect(find.textContaining('1.47°N'), findsOneWidget);
      expect(find.textContaining('Canis Major'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });
  });
}
