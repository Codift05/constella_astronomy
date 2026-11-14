import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite/sqflite.dart';

import 'constellations/constellation_store.dart';
import 'data/app_database.dart';
import 'data/app_settings.dart';
import 'dev/frame_report.dart';
import 'l10n/app_localizations.dart';
import 'screens/app_shell.dart';
import 'screens/onboarding_screen.dart';
import 'stardust/stardust_store.dart';
import 'theme/motion.dart';
import 'theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  startFrameReport();

  // Database dibuka dan dibaca sebelum frame pertama, supaya layar tidak
  // sempat menampilkan nol lalu melompat ke angka sebenarnya.
  final db = await AppDatabase.open();
  final constellations = ConstellationStore(db);
  final stardust = StardustStore(db);
  final settings = AppSettings(db);
  await Future.wait([constellations.load(), stardust.load(), settings.load()]);

  runApp(
    ConstellaApp(
      constellations: constellations,
      stardust: stardust,
      settings: settings,
    ),
  );
}

class ConstellaApp extends StatelessWidget {
  const ConstellaApp({
    super.key,
    required this.constellations,
    required this.stardust,
    required this.settings,
  });

  final ConstellationStore constellations;
  final StardustStore stardust;
  final AppSettings settings;

  /// Membangun aplikasi dengan database di memori. Dipakai tes widget.
  ///
  /// Database lama dihapus lebih dulu: sqflite menyimpan ':memory:' per path,
  /// jadi tanpa ini satu tes mewarisi isi tes sebelumnya.
  static Future<ConstellaApp> inMemory({
    required DatabaseFactory factory,
    bool skipOnboarding = true,
  }) async {
    await factory.deleteDatabase(inMemoryDatabasePath);
    final db = await AppDatabase.open(
      factory: factory,
      path: inMemoryDatabasePath,
    );
    final constellations = ConstellationStore(db);
    final stardust = StardustStore(db);
    final settings = AppSettings(db);
    await Future.wait([
      constellations.load(),
      stardust.load(),
      settings.load(),
    ]);
    if (skipOnboarding) await settings.completeOnboarding();
    return ConstellaApp(
      constellations: constellations,
      stardust: stardust,
      settings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scope harus berada di ATAS MaterialApp. Kalau ditaruh di `home`, ia
    // menjadi isi rute pertama, dan rute yang di-push — seperti layar AR —
    // adalah saudaranya, bukan keturunannya, sehingga tidak bisa membacanya.
    return ConstellationScope(
      notifier: constellations,
      child: StardustScope(
        notifier: stardust,
        child: SettingsScope(
          notifier: settings,
          // MaterialApp ikut dibangun ulang saat tema berganti, supaya
          // themeMode yang tersimpan di SQLite langsung terpakai.
          child: ListenableBuilder(
            listenable: settings,
            builder: (context, _) => MaterialApp(
              onGenerateTitle: (context) => AppL10n.of(context).appTitle,
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(Brightness.light),
              darkTheme: buildAppTheme(Brightness.dark),
              themeMode: settings.themeMode,
              // Warna palet diinterpolasi, jadi perpindahan tema meluncur
              // alih-alih berkedip. 200 ms linear bawaan terasa patah.
              themeAnimationDuration: const Duration(milliseconds: 360),
              themeAnimationCurve: Curves.easeInOutCubic,
              localizationsDelegates: const [
                AppL10n.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppL10n.supportedLocales,
              home: const _Root(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Memilih antara onboarding dan aplikasi utama, dengan transisi melebur
/// supaya perpindahannya tidak meloncat.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final done = SettingsScope.of(context).onboardingDone;
    final dark = context.palette.isDark;
    // Ikon status bar harus berlawanan dengan latar, kalau tidak ia hilang
    // saat tema gelap aktif.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: AnimatedSwitcher(
        duration: context.calm(const Duration(milliseconds: 420)),
        switchInCurve: Curves.easeOutCubic,
        child: done
            ? const AppShell(key: ValueKey('shell'))
            : const OnboardingScreen(key: ValueKey('onboarding')),
      ),
    );
  }
}
