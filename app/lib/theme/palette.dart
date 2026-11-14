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
    // Putih bersemu mint, bukan abu biru. Cukup untuk memisahkan latar layar
    // dari kartu putih, dan cukup netral untuk tetap terbaca sebagai putih.
    backgroundSecondary: Color(0xFFF2F7F5),
    accentPrimary: Color(0xFFAEEED3), // Mint
    accentSecondary: Color(0xFFFFF8B0), // Kuning pucat
    // 4.70:1 di latar sekunder, 5.09:1 di kartu putih, 4.60:1 di accentWash.
    // Teal tua dipakai langsung sebagai warna ikon bermakna: ia sudah lolos
    // ambang teks, jadi tidak perlu varian terpisah yang bisa menyimpang.
    accentStrong: Color(0xFF287A74),
    accentWash: Color(0xFFE8F7F0),
    controlSurface: Color(0xFFF2F7F5),
    actionPrimary: Color(0xFF287A74), // Teal tua
    actionPrimaryAlt: Color(0xFF55A9A0),
    onAction: Color(0xFFFFFFFF), // 5.09:1 di teal tua
    textPrimary: Color(0xFF0C2B28), // 13.94:1 di #F2F7F5
    textSecondary: Color(0xFF4E6B67), // 5.35:1 di #F2F7F5
    skyTop: Color(0xFF55A9A0),
    skyBottom: Color(0xFF287A74),
    cardBorder: null,
    glassTint: Color(0xCCFFFFFF),
    glassBorder: Color(0x33FFFFFF),
    tabBarSurface: Color(0xF7FFFFFF),
    tabBarBorder: Color(0x14052421),
    heroHaloStart: Color(0xFFD6F5E6),
    heroHaloEnd: Color(0xFFFFF8D9),
    chipSelectedBg: Color(0xFFAEEED3),
    chipSelectedText: Color(0xFF0C2B28), // 11.47:1 di mint
    destructive: Color(0xFFB3261E), // putih 6.54:1
    softShadow: [
      BoxShadow(color: Color(0x14052421), blurRadius: 24, offset: Offset(0, 8)),
    ],
    liftedShadow: [
      BoxShadow(
        color: Color(0x1F052421),
        blurRadius: 32,
        offset: Offset(0, 14),
      ),
    ],
  );

  // ----------------------------------------------------------------- gelap

  static const dark = AppPalette(
    brightness: Brightness.dark,
    backgroundPrimary: Color(0xFF112523), // kartu
    backgroundSecondary: Color(0xFF06100F), // latar layar
    accentPrimary: Color(0xFFAEEED3),
    accentSecondary: Color(0xFFFFF8B0),
    accentStrong: Color(0xFF7FD6C3), // 11.31:1 di latar, 9.38:1 di kartu
    accentWash: Color(0xFF16302C),
    controlSurface: Color(0xFF1B3835),
    // Tombol utama jadi kapsul mint berteks gelap. Teal tua di atas latar
    // nyaris hitam akan hilang; ini konvensi tinted button iOS di tema gelap.
    actionPrimary: Color(0xFFAEEED3),
    actionPrimaryAlt: Color(0xFF55A9A0),
    onAction: Color(0xFF06231F), // 12.60:1 di mint
    textPrimary: Color(0xFFE6F2EF), // 16.82:1 di latar, 13.95:1 di kartu
    textSecondary: Color(0xFF93AFAA), // 8.22:1 di latar, 6.82:1 di kartu
    skyTop: Color(0xFF17443F),
    skyBottom: Color(0xFF0B2A27),
    cardBorder: Color(0x1FFFFFFF),
    glassTint: Color(0xD1112523),
    glassBorder: Color(0x1FFFFFFF),
    tabBarSurface: Color(0xF2112523),
    tabBarBorder: Color(0x1FFFFFFF),
    heroHaloStart: Color(0xFF1C443C),
    heroHaloEnd: Color(0xFF3A3A22),
    chipSelectedBg: Color(0xFF1F4541),
    chipSelectedText: Color(0xFFE6F2EF), // 9.22:1
    destructive: Color(0xFFC9372C), // putih 5.16:1, 3.73:1 vs latar
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
