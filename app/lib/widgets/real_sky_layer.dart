import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../sky/sky_math.dart';
import '../sky/sky_projection.dart';
import '../sky/star_catalog.dart';
import '../theme/tokens.dart';

/// Langit yang benar-benar ada di atas pengamat, digambar di atas umpan kamera.
///
/// Setiap titik di sini adalah bintang nyata dari katalog, ditaruh di posisi
/// layar yang dihitung dari tempat, waktu, dan arah ponsel. Tidak ada bintang
/// hiasan: kalau sebuah titik muncul di kanan atas, bintang itu memang ada di
/// kanan atas, di balik atap atau cahaya kota sekalipun.
class RealSkyLayer extends StatelessWidget {
  const RealSkyLayer({
    super.key,
    required this.sky,
    required this.frame,
    required this.reveal,
    this.fovDeg = defaultHorizontalFovDeg,
  });

  /// Seluruh bintang di atas ufuk pada saat ini, sudah dihitung posisinya.
  final List<SightedStar> sky;

  /// Kerangka layar sekarang. Null berarti kompasnya belum bisa dipercaya,
  /// dan tidak ada yang digambar: menebak arah lebih buruk daripada diam.
  final SkyFrame? frame;

  /// 0 saat portal tertutup, 1 saat terbuka penuh. Dipakai untuk memudarkan
  /// seluruh lapisan, bukan untuk menggeser bintangnya.
  final double reveal;

  final double fovDeg;

  @override
  Widget build(BuildContext context) {
    final f = frame;
    if (f == null || reveal <= 0.001) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        painter: _RealSkyPainter(
          sky: sky,
          frame: f,
          reveal: reveal,
          fovDeg: fovDeg,
          textScaler: MediaQuery.textScalerOf(context),
        ),
        isComplex: true,
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _RealSkyPainter extends CustomPainter {
  _RealSkyPainter({
    required this.sky,
    required this.frame,
    required this.reveal,
    required this.fovDeg,
    required this.textScaler,
  });

  final List<SightedStar> sky;
  final SkyFrame frame;
  final double reveal;
  final double fovDeg;
  final TextScaler textScaler;

  /// Di atas magnitudo ini bintang tidak diberi nama. Memberi nama semuanya
  /// akan menutupi langit dengan teks, dan yang redup justru yang paling tidak
  /// dikenali orang.
  static const _nameLimit = 2.3;

  /// Batas jumlah nama di layar. Melewati ini, teksnya saling tindih dan
  /// langit berubah jadi daftar, bukan pemandangan.
  static const _maxNames = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final focal = focalFor(size, horizontalFovDeg: fovDeg);
    _paintNightWash(canvas, size, focal);

    // Terang dulu baru redup: kalau dua bintang bertumpuk, yang terang yang
    // digambar belakangan akan menang, dan itu urutan yang benar.
    final visible = <({SightedStar star, Offset at})>[];
    for (final s in sky) {
      final at = projectToScreen(
        direction: unitFromHorizontal(s.point),
        frame: frame,
        size: size,
        focal: focal,
      );
      if (at == null) continue;
      if (!size.contains(at)) continue;
      visible.add((star: s, at: at));
    }
    visible.sort((a, b) => b.star.star.magnitude.compareTo(a.star.star.magnitude));

    for (final v in visible) {
      _paintStar(canvas, v.at, v.star.star.magnitude);
    }
    _paintNames(canvas, size, visible);
  }

  /// Selubung malam: biru tua di atas ufuk, memudar sampai hilang di bawahnya.
  ///
  /// Inilah yang membuat portal berguna di kota. Langit kota tidak hitam, ia
  /// jingga kecokelatan oleh lampu jalan, dan bintang magnitudo 3 hilang di
  /// dalamnya. Selubung ini menggelapkan bagian langit saja, bukan seluruh
  /// bingkai, sehingga gedung dan pohon tetap terlihat sebagai pijakan.
  void _paintNightWash(Canvas canvas, Size size, double focal) {
    final horizon = _horizonLine(size, focal);
    if (horizon == null) {
      // Ufuknya di luar bingkai. Kalau kamera menghadap ke atas seluruh layar
      // langit; kalau menunduk, tidak ada langit sama sekali.
      if (frame.forward.u < 0) return;
      _wash(canvas, Rect.fromLTWH(0, 0, size.width, size.height), size.height);
      return;
    }

    // Ufuk miring mengikuti kemiringan ponsel, jadi penggambarannya diputar
    // bersamanya alih-alih memakai garis mendatar.
    canvas.save();
    canvas.translate(horizon.anchor.dx, horizon.anchor.dy);
    canvas.rotate(horizon.angle);
    final span = size.longestSide * 2;
    _wash(canvas, Rect.fromLTRB(-span, -span, span, 0), span);
    canvas.restore();
  }

  void _wash(Canvas canvas, Rect rect, double fadeSpan) {
    final fade = math.min(120.0, fadeSpan);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(rect.left, rect.bottom - fade),
          Offset(rect.left, rect.bottom),
          [
            const Color(0xFF040A1F).withValues(alpha: 0.82 * reveal),
            const Color(0xFF040A1F).withValues(alpha: 0.0),
          ],
        ),
    );
    final solid = Rect.fromLTRB(
      rect.left,
      rect.top,
      rect.right,
      rect.bottom - fade,
    );
    if (solid.height > 0) {
      canvas.drawRect(
        solid,
        Paint()..color = const Color(0xFF040A1F).withValues(alpha: 0.82 * reveal),
      );
    }
  }

  /// Titik tambat dan kemiringan garis ufuk di layar, atau null kalau ufuknya
  /// tidak melintasi bingkai sama sekali.
  ({Offset anchor, double angle})? _horizonLine(Size size, double focal) {
    final az = normalize360(
      math.atan2(frame.forward.e, frame.forward.n) * 180 / math.pi,
    );
    // Dua titik di ufuk, cukup berjauhan supaya garisnya stabil.
    final a = projectToScreen(
      direction: unitFromHorizontal((altitude: 0, azimuth: az - 25)),
      frame: frame,
      size: size,
      focal: focal,
    );
    final b = projectToScreen(
      direction: unitFromHorizontal((altitude: 0, azimuth: az + 25)),
      frame: frame,
      size: size,
      focal: focal,
    );
    if (a == null || b == null) return null;
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    if (mid.dy < -size.height || mid.dy > size.height * 2) return null;
    return (anchor: mid, angle: math.atan2(b.dy - a.dy, b.dx - a.dx));
  }

  void _paintStar(Canvas canvas, Offset at, double magnitude) {
    final r = starRadiusFor(magnitude);
    final alpha = (1.0 - (magnitude + 1.5) / 8).clamp(0.35, 1.0) * reveal;

    if (magnitude < 1.6) {
      canvas.drawCircle(
        at,
        r * 3.4,
        Paint()
          ..color = AppNight.accent.withValues(alpha: 0.30 * alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
    canvas.drawCircle(
      at,
      r,
      Paint()..color = Colors.white.withValues(alpha: alpha),
    );
  }

  void _paintNames(
    Canvas canvas,
    Size size,
    List<({SightedStar star, Offset at})> visible,
  ) {
    // Terang lebih dulu: kalau jatah nama habis, yang tersisa tanpa nama
    // adalah yang paling tidak dikenali orang.
    final named = visible
        .where((v) => v.star.star.magnitude <= _nameLimit)
        .toList()
      ..sort(
        (a, b) => a.star.star.magnitude.compareTo(b.star.star.magnitude),
      );

    final taken = <Rect>[];
    var drawn = 0;
    for (final v in named) {
      if (drawn >= _maxNames) break;
      final star = v.star.star;
      final painter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: star.displayName,
              style: AppText.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.92 * reveal),
                fontWeight: FontWeight.w700,
                shadows: const [
                  Shadow(blurRadius: 6, color: Color(0xCC000814)),
                ],
              ),
            ),
            TextSpan(
              text: '\n${star.constellationName}',
              style: AppText.caption.copyWith(
                color: AppNight.accent.withValues(alpha: 0.85 * reveal),
                shadows: const [
                  Shadow(blurRadius: 6, color: Color(0xCC000814)),
                ],
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout(maxWidth: size.width * 0.45);

      final offset = v.at + const Offset(10, -8);
      final box = offset & painter.size;
      // Nama yang akan menimpa nama lain dilewati saja. Dua teks bertumpuk
      // tidak terbaca keduanya, jadi menggambarnya hanya merugikan.
      if (box.right > size.width || box.bottom > size.height) continue;
      if (taken.any((t) => t.inflate(4).overlaps(box))) continue;

      painter.paint(canvas, offset);
      taken.add(box);
      drawn++;
    }
  }

  @override
  bool shouldRepaint(_RealSkyPainter old) =>
      old.reveal != reveal ||
      old.frame != frame ||
      !identical(old.sky, sky) ||
      old.fovDeg != fovDeg;
}
