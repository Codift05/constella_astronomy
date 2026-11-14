import 'package:constella_app/data/app_database.dart';
import 'package:constella_app/data/app_settings.dart';
import 'package:constella_app/main.dart';
import 'package:constella_app/theme/palette.dart';
import 'package:constella_app/widgets/theme_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  group('AppSettings.themeMode', () {
    late AppSettings settings;
    late Database db;

    setUp(() async {
      await databaseFactoryFfi.deleteDatabase(inMemoryDatabasePath);
      db = await AppDatabase.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      settings = AppSettings(db);
      await settings.load();
    });

    test('bawaan mengikuti sistem', () {
      expect(settings.themeMode, ThemeMode.system);
    });

    test('pilihan bertahan setelah dimuat ulang', () async {
      await settings.setThemeMode(ThemeMode.dark);

      // Instance baru di atas database yang sama: inilah yang terjadi saat
      // aplikasi dibuka ulang.
      final reopened = AppSettings(db);
      await reopened.load();
      expect(reopened.themeMode, ThemeMode.dark);
    });

    test('memutar ikut sistem -> terang -> gelap -> ikut sistem', () async {
      expect(settings.themeMode, ThemeMode.system);
      await settings.cycleThemeMode();
      expect(settings.themeMode, ThemeMode.light);
      await settings.cycleThemeMode();
      expect(settings.themeMode, ThemeMode.dark);
      await settings.cycleThemeMode();
      expect(settings.themeMode, ThemeMode.system);
    });

    test('memberi tahu pendengar sekali per perubahan', () async {
      var calls = 0;
      settings.addListener(() => calls++);
      await settings.setThemeMode(ThemeMode.dark);
      expect(calls, 1);
      // Memilih mode yang sama tidak boleh memicu rebuild.
      await settings.setThemeMode(ThemeMode.dark);
      expect(calls, 1);
    });

    test('nilai tak dikenal di database jatuh ke ikut sistem', () async {
      await db.update('profile', {'theme_mode': 'neon'}, where: 'id = 1');
      final loaded = AppSettings(db);
      await loaded.load();
      expect(loaded.themeMode, ThemeMode.system);
    });
  });

  group('Tombol tema di aplikasi', () {
    late ConstellaApp app;

    setUp(() async {
      app = await ConstellaApp.inMemory(factory: databaseFactoryFfi);
    });

    /// Palet yang sedang dipakai pohon widget, dibaca dari Theme aktif.
    AppPalette paletteOf(WidgetTester tester) {
      final ctx = tester.element(find.byType(ThemeToggleButton));
      return Theme.of(ctx).extension<AppPalette>()!;
    }

    testWidgets('tombol tampil di landasan dan memutar tema', (tester) async {
      // Tes berjalan dengan platformBrightness terang, jadi "ikut sistem"
      // bermula di palet terang.
      await tester.pumpWidget(app);
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(ThemeToggleButton), findsOneWidget);
      expect(paletteOf(tester).isDark, isFalse);

      // Ketukan pertama: ikut sistem -> terang. Masih terang.
      await tester.runAsync(() async {
        await tester.tap(find.byType(ThemeToggleButton));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump(const Duration(milliseconds: 600));
      expect(paletteOf(tester).isDark, isFalse);

      // Ketukan kedua: terang -> gelap.
      await tester.runAsync(() async {
        await tester.tap(find.byType(ThemeToggleButton));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      // Perpindahan tema dianimasikan 360 ms; dipompa melewati akhirnya.
      await tester.pump(const Duration(milliseconds: 600));
      expect(paletteOf(tester).isDark, isTrue);
    });

    testWidgets('tombol memenuhi target sentuh 44 pt', (tester) async {
      await tester.pumpWidget(app);
      await tester.pump(const Duration(milliseconds: 600));

      final size = tester.getSize(find.byType(ThemeToggleButton));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });
  });
}
