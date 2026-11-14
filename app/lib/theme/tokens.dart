import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'palette.dart';

export 'palette.dart' show AppPalette, AppPaletteContext;

/// Warna tetap untuk permukaan yang selalu gelap apa pun temanya: layar AR,
/// lapisan gambar rasi, dan pesan galat kamera. Di sana latar belakangnya
/// adalah umpan kamera atau langit hitam, jadi warnanya tidak boleh ikut
/// berpindah saat pengguna mengganti tema.
abstract final class AppNight {
  static const accent = Color(0xFFAEEED3); // Mint
  /// Penanda sumber cahaya yang tertangkap kamera. Kuning pucat, karena lampu
  /// yang ditandainya memang kuning — warnanya menyebut benda, bukan merek.
  static const neon = Color(0xFFFFF8B0);
  static const surface = Color(0xFF12302C);
  static const scrim = Color(0x66000000);
  static const scrimLight = Color(0x55000000);
  static const onSurface = Color(0xFFFFFFFF);
  static const onSurfaceMuted = Color(0xB3FFFFFF); // white70
  /// Label di atas [accent]: 12.60:1.
  static const onAccent = Color(0xFF06231F);
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
  /// Nunito, dibundel sebagai variable font.
  ///
  /// Menjawab [open questions #7](../../../docs/06-open-questions.md): SF Pro
  /// Rounded hanya ada di iOS, jadi Android selama ini jatuh ke font sistem
  /// dan tampilannya berbeda antar perangkat. Satu font untuk keduanya
  /// membuat aplikasinya terlihat sama di mana pun.
  ///
  /// Lisensinya SIL OFL, dan berkas lisensinya ikut dibundel.
  static const rounded = 'Nunito';
  static const display = 'Nunito';
}

/// Membentuk gaya teks dengan bobot yang benar-benar terpakai.
///
/// Nunito di sini adalah **variable font**: satu berkas memuat seluruh rentang
/// bobot pada sumbu `wght`. `fontWeight` saja tidak menggerakkan sumbu itu,
/// jadi setiap gaya juga membawa [FontVariation] yang cocok. Tanpa ini semua
/// teks akan tampil pada satu bobot yang sama.
TextStyle _nunito({
  required double size,
  required double lineHeight,
  required FontWeight weight,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: AppFont.rounded,
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
    letterSpacing: letterSpacing,
  );
}

/// Spring physics untuk semua transisi. Tidak ada kurva linear yang
/// terlihat pengguna — docs/03-design-system.md §3.5.
abstract final class AppSpring {
  /// Press tombol: sangat cepat, overshoot nyaris nol.
  static const press = SpringDescription(mass: 1, stiffness: 900, damping: 42);

  /// Pop-up dan bottom sheet: cepat, overshoot kecil.
  static const popup = SpringDescription(mass: 1, stiffness: 420, damping: 28);

  /// Lepas tekan: kembali ke ukuran asal sambil melewatinya sedikit, lalu
  /// menetap. Inilah yang membuat tombol terasa hidup, bukan sekadar mengecil
  /// dan membesar lagi. Overshoot-nya di bawah lima persen, jadi tombol tidak
  /// pernah menabrak tetangganya.
  static const bouncy = SpringDescription(mass: 1, stiffness: 600, damping: 18);

  /// Portal AR: lambat, overshoot terlihat, megah.
  static const portal = SpringDescription(mass: 2, stiffness: 180, damping: 22);
}

/// Skala Dynamic Type iOS. Semua gaya di sini **tanpa warna** — warnanya
/// diambil dari palet lewat [AppTextStyles] supaya satu definisi tipografi
/// melayani tema terang dan gelap sekaligus.
abstract final class AppText {
  /// Large Title — 34/41 (typography.md > iOS Dynamic Type, Large).
  static final largeTitle = _nunito(
    size: 34,
    lineHeight: 41,
    weight: FontWeight.w800,
    letterSpacing: -0.6,
  );

  /// Title 2 — 22/28.
  static final title2 = _nunito(
    size: 22,
    lineHeight: 28,
    weight: FontWeight.w800,
    letterSpacing: -0.4,
  );

  /// Title 3 — 20/25.
  static final title = _nunito(
    size: 20,
    lineHeight: 25,
    weight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static final numeral = _nunito(
    size: 56,
    lineHeight: 56,
    weight: FontWeight.w800,
    letterSpacing: -2,
  );

  /// Body — 17/22. Ukuran default iOS; nilai lama 15 pt itu Subhead.
  static final body = _nunito(
    size: 17,
    lineHeight: 22,
    weight: FontWeight.w500,
  );

  /// Subhead — 15/20. Untuk label sekunder di dalam kartu.
  static final subhead = _nunito(
    size: 15,
    lineHeight: 20,
    weight: FontWeight.w500,
  );

  /// Footnote — 13/18.
  static final caption = _nunito(
    size: 13,
    lineHeight: 18,
    weight: FontWeight.w500,
  );

  /// Caption 2 — 11/13. Batas bawah yang diizinkan iOS; hanya untuk label tab.
  static final captionSmall = _nunito(
    size: 11,
    lineHeight: 13,
    weight: FontWeight.w600,
  );

  static final button = _nunito(
    size: 17,
    lineHeight: 22,
    weight: FontWeight.w700,
  );
}

/// Mengubah ketebalan teks pada variable font.
///
/// `copyWith(fontWeight: ...)` saja **tidak cukup**: sumbu `wght` Nunito tetap
/// di nilai lama, jadi teksnya terlihat sama saja. Ini mengubah keduanya
/// sekaligus.
extension VariableWeight on TextStyle {
  TextStyle withWeight(FontWeight weight) => copyWith(
    fontWeight: weight,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
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
