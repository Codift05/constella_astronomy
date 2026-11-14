import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/motion.dart';
import '../theme/tokens.dart';

/// Semburan debu bintang sekali jalan dari sebuah titik.
///
/// Dipakai saat sebuah rasi selesai disimpan (PRD 4.2: "ledakan partikel 2D
/// stardust confetti"). Sekali jalan, bukan berulang: ini penanda sebuah
/// kejadian selesai, bukan hiasan latar.
///
/// Tidak menggambar apa pun saat pengguna meminta gerak dikurangi.
class StardustBurst extends StatefulWidget {
  const StardustBurst({
    super.key,
    required this.origin,
    this.onDone,
    this.particles = 26,
  });

  /// Titik pusat semburan, dalam koordinat lokal Stack pembungkusnya.
  final Offset origin;

  final VoidCallback? onDone;
  final int particles;

  @override
  State<StardustBurst> createState() => _StardustBurstState();
}

class _StardustBurstState extends State<StardustBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  late final List<_Particle> _seeds;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _seeds = List.generate(widget.particles, (_) {
      return _Particle(
        angle: rng.nextDouble() * math.pi * 2,
        // Jarak dan kecepatan diacak supaya semburannya tidak tampak seperti
        // lingkaran yang mengembang rapi.
        distance: 60 + rng.nextDouble() * 140,
        size: 2 + rng.nextDouble() * 4,
        spin: (rng.nextDouble() - 0.5) * 6,
        delay: rng.nextDouble() * 0.22,
      );
    });
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone?.call();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      widget.onDone?.call();
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _BurstPainter(
              t: _c.value,
              origin: widget.origin,
              seeds: _seeds,
            ),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.spin,
    required this.delay,
  });

  final double angle;
  final double distance;
  final double size;
  final double spin;
  final double delay;
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({
    required this.t,
    required this.origin,
    required this.seeds,
  });

  final double t;
  final Offset origin;
  final List<_Particle> seeds;

  /// Dua warna saja, dipilih bergantian: pastel biru dan putih. Partikel
  /// pelangi akan bertabrakan dengan palet aplikasi.
  static const _colors = [AppNight.accent, AppNight.onSurface];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < seeds.length; i++) {
      final s = seeds[i];
      final local = ((t - s.delay) / (1 - s.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      // Melambat ke arah akhir, lalu memudar: partikel yang berhenti mendadak
      // terlihat seperti patah, bukan seperti debu yang melayang.
      final eased = Curves.easeOutCubic.transform(local);
      final fade = (1 - local * local).clamp(0.0, 1.0);
      final gravity = 26 * local * local;

      final p = Offset(
        origin.dx + math.cos(s.angle) * s.distance * eased,
        origin.dy + math.sin(s.angle) * s.distance * eased + gravity,
      );

      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(s.spin * eased);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: s.size,
            height: s.size * 2.2,
          ),
          Radius.circular(s.size),
        ),
        Paint()
          ..color = _colors[i % _colors.length].withValues(alpha: fade * 0.9),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t || old.origin != origin;
}
