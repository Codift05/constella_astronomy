import 'dart:math' as math;
import 'dart:ui';

import 'package:constella_app/theme/palette.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rasio kontras WCAG 2.1. Kanal sRGB dilinearkan dulu, sesuai rumus resmi.
double _contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  final hi = math.max(la, lb), lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

double _luminance(Color c) =>
    0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b);

double _lin(double channel) => channel <= 0.04045
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

/// Satu pasangan warna yang harus lolos ambang tertentu.
typedef _Pair = (String name, Color fg, Color bg, double min);

/// Ambang WCAG AA: 4.5:1 untuk teks sampai 17 pt, 3:1 untuk ikon dan elemen
/// non-teks (accessibility.md > Color and effects).
const _text = 4.5;
const _nonText = 3.0;

List<_Pair> _pairsFor(AppPalette p) => [
  // Teks di atas tiap permukaan yang benar-benar dipakai.
  ('textPrimary di latar layar', p.textPrimary, p.backgroundSecondary, _text),
  ('textPrimary di kartu', p.textPrimary, p.backgroundPrimary, _text),
  (
    'textSecondary di latar layar',
    p.textSecondary,
    p.backgroundSecondary,
    _text,
  ),
  ('textSecondary di kartu', p.textSecondary, p.backgroundPrimary, _text),
  ('textSecondary di accentWash', p.textSecondary, p.accentWash, _text),
  ('textSecondary di controlSurface', p.textSecondary, p.controlSurface, _text),

  // Label tombol utama.
  ('onAction di actionPrimary', p.onAction, p.actionPrimary, _text),

  // Chip: pasangan terpilih dihitung terpisah karena pastel terang tidak bisa
  // dipakai bersama teks terang.
  (
    'chipSelectedText di chipSelectedBg',
    p.chipSelectedText,
    p.chipSelectedBg,
    _text,
  ),
  ('textSecondary di chip non-aktif', p.textSecondary, p.accentWash, _text),

  // Tab bar.
  ('tab terpilih di tab bar', p.actionPrimary, p.tabBarSurface, _text),
  ('tab non-aktif di tab bar', p.textSecondary, p.tabBarSurface, _text),
  ('tab terpilih di indikator', p.actionPrimary, p.accentWash, _text),
  ('tab non-aktif di indikator', p.textSecondary, p.accentWash, _text),

  // Aksi merusak: label putih di atasnya, dan petaknya harus terpisah dari
  // latar layar saat baris digeser.
  ('putih di destructive', Color(0xFFFFFFFF), p.destructive, _text),
  (
    'destructive vs latar layar',
    p.destructive,
    p.backgroundSecondary,
    _nonText,
  ),

  // Ikon dan elemen non-teks.
  (
    'accentStrong di latar layar',
    p.accentStrong,
    p.backgroundSecondary,
    _nonText,
  ),
  ('accentStrong di kartu', p.accentStrong, p.backgroundPrimary, _nonText),
  (
    'accentStrong di controlSurface',
    p.accentStrong,
    p.controlSurface,
    _nonText,
  ),
  ('ikon kontrol di controlSurface', p.textPrimary, p.controlSurface, _nonText),
];

void main() {
  group('Kontras palet', () {
    for (final (label, palette) in [
      ('terang', AppPalette.light),
      ('gelap', AppPalette.dark),
    ]) {
      group('tema $label', () {
        for (final (name, fg, bg, min) in _pairsFor(palette)) {
          test('$name >= $min:1', () {
            final r = _contrast(fg, bg);
            expect(
              r,
              greaterThanOrEqualTo(min),
              reason:
                  'Kontras hanya ${r.toStringAsFixed(2)}:1, '
                  'butuh minimal $min:1.',
            );
          });
        }
      });
    }

    test('kartu dan latar layar tidak identik', () {
      // Kalau keduanya sama, hierarki kedalaman hilang total.
      for (final p in [AppPalette.light, AppPalette.dark]) {
        expect(p.backgroundPrimary, isNot(p.backgroundSecondary));
      }
    });

    test(
      'tema gelap menaikkan kartu di atas latar, bukan menenggelamkannya',
      () {
        // Tanpa ini, bayangan hitam di latar nyaris hitam membuat kartu lenyap.
        expect(
          _luminance(AppPalette.dark.backgroundPrimary),
          greaterThan(_luminance(AppPalette.dark.backgroundSecondary)),
        );
        expect(
          _luminance(AppPalette.dark.controlSurface),
          greaterThan(_luminance(AppPalette.dark.backgroundPrimary)),
        );
      },
    );

    test(
      'tema gelap memberi tepi kartu, tema terang mengandalkan bayangan',
      () {
        expect(AppPalette.dark.cardBorder, isNotNull);
        expect(AppPalette.light.cardBorder, isNull);
      },
    );

    test('lerp menukar brightness di titik tengah dan tidak melempar', () {
      final mid = AppPalette.light.lerp(AppPalette.dark, 0.5);
      expect(mid.brightness, Brightness.dark);
      expect(
        AppPalette.light.lerp(AppPalette.dark, 0.0).brightness,
        Brightness.light,
      );
      expect(
        AppPalette.light.lerp(AppPalette.dark, 1.0).brightness,
        Brightness.dark,
      );
      // cardBorder null -> non-null harus tetap terinterpolasi, bukan crash.
      expect(mid.cardBorder, isNotNull);
    });

    test('lerp dengan null mengembalikan dirinya sendiri', () {
      expect(AppPalette.light.lerp(null, 0.5), AppPalette.light);
    });
  });
}
