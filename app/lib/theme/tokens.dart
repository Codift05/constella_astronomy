import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'palette.dart';

export 'palette.dart' show AppPalette, AppPaletteContext;

/// Warna tetap untuk permukaan yang selalu gelap apa pun temanya: layar AR,
/// lapisan gambar rasi, dan pesan galat kamera. Di sana latar belakangnya
/// adalah umpan kamera atau langit hitam, jadi warnanya tidak boleh ikut
/// berpindah saat pengguna mengganti tema.
abstract final class AppNight {
  static const accent = Color(0xFF8FB8FF);
  static const neon = Color(0xFF8FD8FF);
  static const surface = Color(0xFF14284A);
  static const scrim = Color(0x66000000);
  static const scrimLight = Color(0x55000000);
  static const onSurface = Color(0xFFFFFFFF);
  static const onSurfaceMuted = Color(0xB3FFFFFF); // white70
  /// Label di atas [accent]: 9.48:1.
  static const onAccent = Color(0xFF08101F);
}

abstract final class AppRadius {
  static const card = 28.0;
  static const cardInner = 20.0;
  static const sheet = 36.0;
}

/// Ukuran target sentuh minimum iOS (accessibility.md > Offering sufficiently
/// sized controls: default 44x44 pt, minimum 28x28 pt).
const kMinTapTarget = 44.0;

/// Ruang yang harus disisakan di dasar layar agar konten tidak tertutup
/// tab bar melayang.
const kTabBarInset = 112.0;

abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class AppFont {
  /// SF Pro Rounded hanya tersedia di iOS. Android jatuh ke fallback sistem
  /// sampai pengganti berlisensi dipilih — lihat docs/06-open-questions.md #7.
  static const rounded = '.SF Pro Rounded';
  static const display = '.SF Pro Display';
}

/// Spring physics untuk semua transisi. Tidak ada kurva linear yang
/// terlihat pengguna — docs/03-design-system.md §3.5.
abstract final class AppSpring {
  /// Press tombol: sangat cepat, overshoot nyaris nol.
  static const press = SpringDescription(mass: 1, stiffness: 900, damping: 42);

  /// Pop-up dan bottom sheet: cepat, overshoot kecil.
  static const popup = SpringDescription(mass: 1, stiffness: 420, damping: 28);

  /// Portal AR: lambat, overshoot terlihat, megah.
  static const portal = SpringDescription(mass: 2, stiffness: 180, damping: 22);
}

/// Skala Dynamic Type iOS. Semua gaya di sini **tanpa warna** — warnanya
/// diambil dari palet lewat [AppTextStyles] supaya satu definisi tipografi
/// melayani tema terang dan gelap sekaligus.
abstract final class AppText {
  /// Large Title — 34/41 (typography.md > iOS Dynamic Type, Large).
  static const largeTitle = TextStyle(
    fontFamily: AppFont.rounded,
    fontSize: 34,
    height: 41 / 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );

  /// Title 2 — 22/28.
  static const title2 = TextStyle(
    fontFamily: AppFont.rounded,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  /// Title 3 — 20/25.
  static const title = TextStyle(
    fontFamily: AppFont.rounded,
    fontSize: 20,
    height: 25 / 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static const numeral = TextStyle(
    fontFamily: AppFont.rounded,
    fontSize: 56,
    fontWeight: FontWeight.w700,
    letterSpacing: -2,
    height: 1,
  );

  /// Body — 17/22. Ukuran default iOS; nilai lama 15 pt itu Subhead.
  static const body = TextStyle(
    fontFamily: AppFont.display,
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w500,
  );

  /// Subhead — 15/20. Untuk label sekunder di dalam kartu.
  static const subhead = TextStyle(
    fontFamily: AppFont.display,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w500,
  );

  /// Footnote — 13/18.
  static const caption = TextStyle(
    fontFamily: AppFont.display,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
  );

  /// Caption 2 — 11/13. Batas bawah yang diizinkan iOS; hanya untuk label tab.
  static const captionSmall = TextStyle(
    fontFamily: AppFont.rounded,
    fontSize: 11,
    height: 13 / 11,
    fontWeight: FontWeight.w600,
  );

  static const button = TextStyle(
    fontFamily: AppFont.rounded,
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w600,
  );
}

/// Tipografi yang sudah diberi warna dari palet aktif.
/// Pakai `context.palette.body`, bukan `AppText.body`, di layar yang
/// mengikuti tema.
extension AppTextStyles on AppPalette {
  TextStyle get largeTitle => AppText.largeTitle.copyWith(color: textPrimary);
  TextStyle get title2 => AppText.title2.copyWith(color: textPrimary);
  TextStyle get title => AppText.title.copyWith(color: textPrimary);
  TextStyle get numeral => AppText.numeral.copyWith(color: textPrimary);
  TextStyle get body => AppText.body.copyWith(color: textPrimary);
  TextStyle get subhead => AppText.subhead.copyWith(color: textPrimary);
  TextStyle get caption => AppText.caption.copyWith(color: textSecondary);
  TextStyle get captionSmall =>
      AppText.captionSmall.copyWith(color: textSecondary);
  TextStyle get button => AppText.button.copyWith(color: onAction);
}

ThemeData buildAppTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    // Transisi geser dari tepi di kedua platform, bukan zoom ala Android.
    // Memberi swipe-to-go-back sekaligus, sesuai designing-for-ios.md:
    // "let people swipe to navigate back".
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      },
    ),
    extensions: [p],
    scaffoldBackgroundColor: p.backgroundSecondary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.accentPrimary,
      brightness: brightness,
      primary: p.actionPrimary,
      onPrimary: p.onAction,
      surface: p.backgroundPrimary,
      onSurface: p.textPrimary,
    ),
    // Dialog, snackbar, dan TextField ikut palet lewat textTheme ini.
    textTheme: Typography.material2021(platform: TargetPlatform.iOS).black
        .apply(
          bodyColor: p.textPrimary,
          displayColor: p.textPrimary,
          fontFamily: AppFont.display,
        ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.backgroundPrimary,
      titleTextStyle: AppText.title.copyWith(color: p.textPrimary),
      contentTextStyle: AppText.body.copyWith(color: p.textSecondary),
    ),
    fontFamily: AppFont.display,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
