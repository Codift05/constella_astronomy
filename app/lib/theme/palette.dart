import 'package:flutter/material.dart';

/// Satu sumber warna untuk kedua tema.
///
/// Semua pasangan teks/latar di sini sudah dihitung terhadap WCAG AA: 4.5:1
/// untuk teks sampai 17 pt, dan 3:1 untuk ikon serta elemen non-teks
/// (accessibility.md > Color and effects). Angka tiap pasangan ditulis di
/// komentar supaya penggantian warna berikutnya tidak menebak.
///
/// Dipasang sebagai [ThemeExtension] supaya [MaterialApp] ikut menganimasikan
/// perpindahan terang/gelap, bukan mengedipkannya.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.accentStrong,
    required this.accentWash,
    required this.controlSurface,
    required this.actionPrimary,
    required this.actionPrimaryAlt,
    required this.onAction,
    required this.textPrimary,
    required this.textSecondary,
    required this.skyTop,
    required this.skyBottom,
    required this.cardBorder,
    required this.glassTint,
    required this.glassBorder,
    required this.tabBarSurface,
    required this.tabBarBorder,
    required this.heroHaloStart,
    required this.heroHaloEnd,
    required this.chipSelectedBg,
    required this.destructive,
    required this.chipSelectedText,
    required this.softShadow,
    required this.liftedShadow,
  });

  final Brightness brightness;

  /// Permukaan kartu, selalu lebih terang dari [backgroundSecondary] di tema
  /// gelap supaya hierarki kedalaman tetap terbaca tanpa bayangan.
  final Color backgroundPrimary;

  /// Latar layar.
  final Color backgroundSecondary;

  /// Pastel Blue. Warna permukaan, bukan warna teks atau ikon bermakna.
  final Color accentPrimary;
  final Color accentSecondary;

  /// Varian accent yang cukup kontras untuk ikon bermakna dan isi progress bar.
  final Color accentStrong;

  /// Latar chip non-aktif.
  final Color accentWash;

  /// Permukaan kontrol kecil di dalam kartu: tombol bulat stepper, dan latar
  /// progress bar. Di tema gelap ini harus lebih terang dari kartunya, bukan
  /// lebih gelap, supaya tidak terlihat seperti lubang.
  final Color controlSurface;

  final Color actionPrimary;
  final Color actionPrimaryAlt;

  /// Warna label di atas [actionPrimary].
  final Color onAction;

  final Color textPrimary;
  final Color textSecondary;

  final Color skyTop;
  final Color skyBottom;

  /// Garis rambut di tepi kartu. `null` di tema terang: di sana bayangan yang
  /// memisahkan kartu dari latar, sementara di tema gelap bayangan hitam tidak
  /// terlihat sehingga tepi yang mengambil perannya.
  final Color? cardBorder;

  final Color glassTint;
  final Color glassBorder;

  final Color tabBarSurface;
  final Color tabBarBorder;

  /// Gradient halo di belakang maskot.
  final Color heroHaloStart;
  final Color heroHaloEnd;

  /// Chip terpilih tidak bisa memakai [accentPrimary] di tema gelap: pastel
  /// terang dengan teks terang hanya 1.1:1. Pasangan ini dihitung terpisah.
  final Color chipSelectedBg;
  final Color chipSelectedText;

  /// Latar aksi merusak (geser-untuk-hapus). Selalu berpasangan dengan putih.
  /// Di tema gelap ia dinaikkan: `#B3261E` hanya 2.98:1 terhadap latar
  /// `#070D18`, jadi petak hapusnya nyaris menyatu dengan layar.
  final Color destructive;

  final List<BoxShadow> softShadow;
  final List<BoxShadow> liftedShadow;

  bool get isDark => brightness == Brightness.dark;

  // ---------------------------------------------------------------- terang

  static const light = AppPalette(
    brightness: Brightness.light,
    backgroundPrimary: Color(0xFFFFFFFF),
    backgroundSecondary: Color(0xFFF4F6F8),
    accentPrimary: Color(0xFF8FB8FF),
    accentSecondary: Color(0xFFBFC6FF),
    // 3.29:1 di latar sekunder, 3.56:1 di kartu putih, 3.11:1 di accentWash.
    // Nilai lama #5C8EE6 hanya 2.997:1 di latar sekunder — gagal 3:1 di
    // ikon empty-state dan titik onboarding yang digambar di sana.
    accentStrong: Color(0xFF5687DC),
    accentWash: Color(0xFFE8F0FF),
    controlSurface: Color(0xFFF4F6F8),
    actionPrimary: Color(0xFF0A192F), // Deep Navy
    actionPrimaryAlt: Color(0xFF14284A),
    onAction: Color(0xFFFFFFFF), // 16.25:1 di Navy
    textPrimary: Color(0xFF0A192F), // 16.25:1 di #F4F6F8
    textSecondary: Color(0xFF5A6880), // 5.20:1 di #F4F6F8
    skyTop: Color(0xFF6FA4FF),
    skyBottom: Color(0xFF3E7BFF),
    cardBorder: null,
    glassTint: Color(0xCCFFFFFF),
    glassBorder: Color(0x33FFFFFF),
    tabBarSurface: Color(0xF7FFFFFF),
    tabBarBorder: Color(0x14000F2E),
    heroHaloStart: Color(0xFFDCE9FF),
    heroHaloEnd: Color(0xFFEFE6FF),
    chipSelectedBg: Color(0xFF8FB8FF),
    chipSelectedText: Color(0xFF0A192F), // 8.77:1 di pastel
    destructive: Color(0xFFB3261E), // putih 6.54:1
    softShadow: [
      BoxShadow(color: Color(0x14000F2E), blurRadius: 24, offset: Offset(0, 8)),
    ],
    liftedShadow: [
      BoxShadow(
        color: Color(0x1F000F2E),
        blurRadius: 32,
        offset: Offset(0, 14),
      ),
    ],
  );

  // ----------------------------------------------------------------- gelap

  static const dark = AppPalette(
    brightness: Brightness.dark,
    backgroundPrimary: Color(0xFF131C2E), // kartu
    backgroundSecondary: Color(0xFF070D18), // latar layar
    accentPrimary: Color(0xFF8FB8FF),
    accentSecondary: Color(0xFFA9B1FF),
    accentStrong: Color(0xFF93C0FF), // 10.40:1 di latar, 9.10:1 di kartu
    accentWash: Color(0xFF1C2942),
    controlSurface: Color(0xFF1F2C47),
    // Tombol utama jadi kapsul biru terang berteks gelap. Navy di atas latar
    // nyaris hitam akan hilang; ini konvensi tinted button iOS di tema gelap.
    actionPrimary: Color(0xFF8FB8FF),
    actionPrimaryAlt: Color(0xFFBFC6FF),
    onAction: Color(0xFF08101F), // 9.48:1 di #8FB8FF
    textPrimary: Color(0xFFE9EEF8), // 16.72:1 di latar, 14.64:1 di kartu
    textSecondary: Color(0xFF9AA8C0), // 8.09:1 di latar, 7.08:1 di kartu
    skyTop: Color(0xFF1B3A7A),
    skyBottom: Color(0xFF0E2550),
    cardBorder: Color(0x1FFFFFFF),
    glassTint: Color(0xD1131C2E),
    glassBorder: Color(0x1FFFFFFF),
    tabBarSurface: Color(0xF2131C2E),
    tabBarBorder: Color(0x1FFFFFFF),
    heroHaloStart: Color(0xFF22325C),
    heroHaloEnd: Color(0xFF2B2550),
    chipSelectedBg: Color(0xFF2E4878),
    chipSelectedText: Color(0xFFE9EEF8), // 7.80:1
    destructive: Color(0xFFC9372C), // putih 5.16:1, 3.77:1 vs latar
    softShadow: [
      BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8)),
    ],
    liftedShadow: [
      BoxShadow(
        color: Color(0x80000000),
        blurRadius: 32,
        offset: Offset(0, 14),
      ),
    ],
  );

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? backgroundPrimary,
    Color? backgroundSecondary,
    Color? accentPrimary,
    Color? accentSecondary,
    Color? accentStrong,
    Color? accentWash,
    Color? controlSurface,
    Color? actionPrimary,
    Color? actionPrimaryAlt,
    Color? onAction,
    Color? textPrimary,
    Color? textSecondary,
    Color? skyTop,
    Color? skyBottom,
    Color? cardBorder,
    Color? glassTint,
    Color? glassBorder,
    Color? tabBarSurface,
    Color? tabBarBorder,
    Color? heroHaloStart,
    Color? heroHaloEnd,
    Color? chipSelectedBg,
    Color? destructive,
    Color? chipSelectedText,
    List<BoxShadow>? softShadow,
    List<BoxShadow>? liftedShadow,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      accentStrong: accentStrong ?? this.accentStrong,
      accentWash: accentWash ?? this.accentWash,
      controlSurface: controlSurface ?? this.controlSurface,
      actionPrimary: actionPrimary ?? this.actionPrimary,
      actionPrimaryAlt: actionPrimaryAlt ?? this.actionPrimaryAlt,
      onAction: onAction ?? this.onAction,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      skyTop: skyTop ?? this.skyTop,
      skyBottom: skyBottom ?? this.skyBottom,
      cardBorder: cardBorder ?? this.cardBorder,
      glassTint: glassTint ?? this.glassTint,
      glassBorder: glassBorder ?? this.glassBorder,
      tabBarSurface: tabBarSurface ?? this.tabBarSurface,
      tabBarBorder: tabBarBorder ?? this.tabBarBorder,
      heroHaloStart: heroHaloStart ?? this.heroHaloStart,
      heroHaloEnd: heroHaloEnd ?? this.heroHaloEnd,
      chipSelectedBg: chipSelectedBg ?? this.chipSelectedBg,
      destructive: destructive ?? this.destructive,
      chipSelectedText: chipSelectedText ?? this.chipSelectedText,
      softShadow: softShadow ?? this.softShadow,
      liftedShadow: liftedShadow ?? this.liftedShadow,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      // Brightness tidak bisa diinterpolasi; ia berbalik di titik tengah.
      brightness: t < 0.5 ? brightness : other.brightness,
      backgroundPrimary: c(backgroundPrimary, other.backgroundPrimary),
      backgroundSecondary: c(backgroundSecondary, other.backgroundSecondary),
      accentPrimary: c(accentPrimary, other.accentPrimary),
      accentSecondary: c(accentSecondary, other.accentSecondary),
      accentStrong: c(accentStrong, other.accentStrong),
      accentWash: c(accentWash, other.accentWash),
      controlSurface: c(controlSurface, other.controlSurface),
      actionPrimary: c(actionPrimary, other.actionPrimary),
      actionPrimaryAlt: c(actionPrimaryAlt, other.actionPrimaryAlt),
      onAction: c(onAction, other.onAction),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      skyTop: c(skyTop, other.skyTop),
      skyBottom: c(skyBottom, other.skyBottom),
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t),
      glassTint: c(glassTint, other.glassTint),
      glassBorder: c(glassBorder, other.glassBorder),
      tabBarSurface: c(tabBarSurface, other.tabBarSurface),
      tabBarBorder: c(tabBarBorder, other.tabBarBorder),
      heroHaloStart: c(heroHaloStart, other.heroHaloStart),
      heroHaloEnd: c(heroHaloEnd, other.heroHaloEnd),
      chipSelectedBg: c(chipSelectedBg, other.chipSelectedBg),
      destructive: c(destructive, other.destructive),
      chipSelectedText: c(chipSelectedText, other.chipSelectedText),
      softShadow: BoxShadow.lerpList(softShadow, other.softShadow, t)!,
      liftedShadow: BoxShadow.lerpList(liftedShadow, other.liftedShadow, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// Palet tema aktif. Memanggil ini membuat widget ikut rebuild saat tema
  /// berganti, karena [Theme.of] mendaftar sebagai dependency.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
