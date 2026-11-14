import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/motion.dart';
import '../theme/tokens.dart';

/// Lapisan bintang yang menyapu layar saat berpindah tab.
///
/// Alasannya bukan hiasan (R-19): arah terbang bintang mengikuti arah
/// perpindahan, jadi ia memberi tahu kamu bergerak ke kiri atau ke kanan,
/// bukan sekadar bahwa layar berganti. Tabirnya menggelap sebentar di
/// pertengahan, sehingga pergantian terasa seperti melewati langit, bukan
/// seperti dua gambar yang bertukar.
///
/// Diam total saat pengguna meminta gerak dikurangi.
class StarWipe extends StatelessWidget {
  const StarWipe({super.key, required this.progress, required this.direction});

  /// 0 sampai 1 sepanjang satu perpindahan tab.
  final Animation<double> progress;

  /// +1 saat berpindah ke tab di kanan, -1 ke kiri.
  final int direction;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: progress,
          builder: (context, _) {
            final t = progress.value;
            if (t <= 0 || t >= 1) return const SizedBox.shrink();
            return CustomPaint(
              size: Size.infinite,
              painter: _StarWipePainter(t: t, direction: direction),
            );
          },
        ),
      ),
    );
  }
}

class _Streak {
  const _Streak(this.y, this.offset, this.speed, this.length, this.opacity);

  /// Semuanya ternormalisasi terhadap ukuran layar.
  final double y;
  final double offset;
  final double speed;
  final double length;
  final double opacity;
}

class _StarWipePainter extends CustomPainter {
  _StarWipePainter({required this.t, required this.direction});

  final double t;
  final int direction;

  /// Seed tetap supaya polanya sama tiap perpindahan: pergantian tab terjadi
  /// berkali-kali, dan pola yang berubah-ubah akan terasa berisik.
  static final _rng = math.Random(20261114);
  static final List<_Streak> _streaks = List.generate(46, (_) {
    return _Streak(
      _rng.nextDouble(),
      _rng.nextDouble(),
      0.6 + _rng.nextDouble() * 0.9,
      0.05 + _rng.nextDouble() * 0.16,
      0.35 + _rng.nextDouble() * 0.6,
    );
  });

  /// Naik lalu turun, puncaknya di tengah perpindahan.
  double get _veil => math.sin(t * math.pi);

  @override
  void paint(Canvas canvas, Size size) {
    final fade = _veil;

    // Tabir tipis. Cukup untuk menyatukan dua layar, tidak sampai menutupi.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF070D18).withValues(alpha: fade * 0.30),
    );

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4;

    for (final s in _streaks) {
      // Bintang masuk dari tepi yang ditinggalkan dan terbang ke arah tujuan.
      final travel = (t * s.speed + s.offset) % 1.0;
      final x = direction > 0
          ? (1.2 - travel * 1.5) * size.width
          : (travel * 1.5 - 0.2) * size.width;
      final tail = s.length * size.width * -direction;
      final y = s.y * size.height;

      paint.shader =
          LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppNight.onSurface.withValues(alpha: 0),
              AppNight.onSurface.withValues(alpha: s.opacity * fade),
            ],
          ).createShader(
            Rect.fromPoints(Offset(x + tail, y - 1), Offset(x, y + 1)),
          );
      canvas.drawLine(Offset(x + tail, y), Offset(x, y), paint);
    }
  }

  @override
  bool shouldRepaint(_StarWipePainter old) =>
      old.t != t || old.direction != direction;
}
