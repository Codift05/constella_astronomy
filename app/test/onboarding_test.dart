import 'package:constella_app/data/app_database.dart';
import 'package:constella_app/data/app_settings.dart';
import 'package:constella_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  group('AppSettings', () {
    late AppSettings settings;

    setUp(() async {
      await databaseFactoryFfi.deleteDatabase(inMemoryDatabasePath);
      final db = await AppDatabase.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      settings = AppSettings(db);
      await settings.load();
    });

    test('peluncuran pertama belum pernah onboarding', () {
      expect(settings.onboardingDone, isFalse);
    });

    test('menyelesaikan onboarding bertahan setelah dimuat ulang', () async {
      await settings.completeOnboarding();
      expect(settings.onboardingDone, isTrue);

      final db = await AppDatabase.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      final reloaded = AppSettings(db);
      await reloaded.load();
      expect(reloaded.onboardingDone, isTrue);
    });

    test('memanggil dua kali aman', () async {
      await settings.completeOnboarding();
      await settings.completeOnboarding();
      expect(settings.onboardingDone, isTrue);
    });
  });

  group('Alur onboarding', () {
    late ConstellaApp app;

    setUp(() async {
      app = await ConstellaApp.inMemory(
        factory: databaseFactoryFfi,
        skipOnboarding: false,
      );
    });

    testWidgets('pengguna baru melihat onboarding, bukan tab bar', (
      tester,
    ) async {
      await tester.pumpWidget(app);
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Hello, I am Nova'), findsOneWidget);
      expect(find.text('Sky'), findsNothing);
    });

    testWidgets('Lewati langsung membuka aplikasi', (tester) async {
      await tester.pumpWidget(app);
      await tester.pump(const Duration(milliseconds: 600));

      await tester.runAsync(() async {
        await tester.tap(find.text('Skip'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await tester.pump();
      });
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Sky'), findsOneWidget);
    });

    testWidgets('langkah terakhir menjelaskan kamera sebelum izin diminta', (
      tester,
    ) async {
      await tester.pumpWidget(app);
      await tester.pump(const Duration(milliseconds: 600));

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        // Animasi PageView 420 ms; beri dua pump supaya benar-benar mendarat
        // sebelum ketukan berikutnya.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));
      }
      expect(find.text('Constella needs your camera'), findsOneWidget);
      expect(find.text("Let's go"), findsOneWidget);
    });
  });
}
