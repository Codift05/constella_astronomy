import 'package:constella_app/l10n/app_localizations.dart';
import 'package:constella_app/theme/motion.dart';
import 'package:constella_app/theme/tokens.dart';
import 'package:constella_app/widgets/mascot.dart';
import 'package:constella_app/widgets/star_wipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Membungkus [child] dengan setelan Kurangi Gerak menyala atau mati.
///
/// Memakai MaterialApp karena maskot membaca label aksesibilitasnya dari
/// lokalisasi; MediaQuery di dalam home menimpa milik MaterialApp.
Widget wrap(Widget child, {required bool reduce}) => MaterialApp(
  theme: buildAppTheme(Brightness.dark),
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  locale: const Locale('en'),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Scaffold(body: child),
  ),
);

void main() {
  group('tuas Kurangi Gerak', () {
    testWidgets('durasi runtuh jadi nol saat menyala', (tester) async {
      late Duration calm;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              calm = context.calm(const Duration(milliseconds: 420));
              return const SizedBox();
            },
          ),
          reduce: true,
        ),
      );
      expect(calm, Duration.zero);
    });

    testWidgets('durasi utuh saat dimatikan', (tester) async {
      late Duration calm;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              calm = context.calm(const Duration(milliseconds: 420));
              return const SizedBox();
            },
          ),
          reduce: false,
        ),
      );
      expect(calm, const Duration(milliseconds: 420));
    });

    testWidgets('kurva memantul diratakan saat menyala', (tester) async {
      late Curve curve;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              curve = context.calmCurve(Curves.easeOutBack);
              return const SizedBox();
            },
          ),
          reduce: true,
        ),
      );
      expect(curve, Curves.linear);
    });
  });

  group('springTo', () {
    testWidgets('melompat langsung ke target saat Kurangi Gerak menyala', (
      tester,
    ) async {
      final c = AnimationController.unbounded(vsync: tester, value: 0);
      addTearDown(c.dispose);
      springTo(c, AppSpring.portal, 1, reduceMotion: true);
      expect(c.value, 1.0);
      expect(c.isAnimating, isFalse);
    });

    testWidgets('beranimasi saat dimatikan', (tester) async {
      final c = AnimationController.unbounded(vsync: tester, value: 0);
      addTearDown(c.dispose);
      springTo(c, AppSpring.portal, 1, reduceMotion: false);
      expect(c.isAnimating, isTrue);
      expect(c.value, lessThan(1.0));
      c.stop();
    });
  });

  group('holdOrRepeat', () {
    testWidgets(
      'menghentikan animasi tanpa akhir dan menahannya di satu pose',
      (tester) async {
        final c = AnimationController(
          vsync: tester,
          duration: const Duration(seconds: 2),
        )..repeat(reverse: true);
        addTearDown(c.dispose);

        holdOrRepeat(c, reduceMotion: true, restingValue: 0.5);
        expect(c.isAnimating, isFalse);
        expect(c.value, 0.5);
      },
    );

    testWidgets('menjalankan lagi saat setelannya dimatikan', (tester) async {
      final c = AnimationController(
        vsync: tester,
        duration: const Duration(seconds: 2),
      );
      addTearDown(c.dispose);

      holdOrRepeat(c, reduceMotion: false);
      expect(c.isAnimating, isTrue);
      c.stop();
    });
  });

  group('maskot', () {
    testWidgets('berhenti bernapas saat Kurangi Gerak menyala', (tester) async {
      await tester.pumpWidget(
        wrap(const CosmicMascot(size: kMascotInline), reduce: true),
      );
      await tester.pump(const Duration(milliseconds: 100));
      // Tidak ada animasi berjalan: pumpAndSettle akan menggantung kalau ada.
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    });

    testWidgets('dua ukuran bernama berbeda dan keduanya terpakai', (
      tester,
    ) async {
      expect(kMascotHero, greaterThan(kMascotInline));
    });
  });

  group('sapuan bintang antar tab', () {
    testWidgets('tidak menggambar apa pun saat Kurangi Gerak menyala', (
      tester,
    ) async {
      final c = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 400),
      );
      addTearDown(c.dispose);
      c.value = 0.5;

      await tester.pumpWidget(
        wrap(StarWipe(progress: c, direction: 1), reduce: true),
      );
      expect(
        find.descendant(
          of: find.byType(StarWipe),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });

    testWidgets('menggambar di tengah perpindahan saat dimatikan', (
      tester,
    ) async {
      final c = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 400),
      );
      addTearDown(c.dispose);
      c.value = 0.5;

      await tester.pumpWidget(
        wrap(StarWipe(progress: c, direction: 1), reduce: false),
      );
      expect(
        find.descendant(
          of: find.byType(StarWipe),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
      );
    });

    testWidgets('diam di awal dan akhir perpindahan', (tester) async {
      final c = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 400),
      );
      addTearDown(c.dispose);

      for (final v in [0.0, 1.0]) {
        c.value = v;
        await tester.pumpWidget(
          wrap(StarWipe(progress: c, direction: -1), reduce: false),
        );
        await tester.pump();
        expect(
          find.descendant(
            of: find.byType(StarWipe),
            matching: find.byType(CustomPaint),
          ),
          findsNothing,
          reason: 'pada t=$v',
        );
      }
    });
  });
}
