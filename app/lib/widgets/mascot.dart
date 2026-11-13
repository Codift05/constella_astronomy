import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n_ext.dart';
import '../theme/tokens.dart';
import 'soft_ui.dart';

/// Nama placeholder. Maskot final butuh nama dan desain orisinal —
/// docs/06-open-questions.md #17.
const mascotName = 'Nova';

/// shortcut: maskot digambar 2D dengan CustomPainter, bukan model 3D.
/// Upgrade ke 3D (model_viewer / three_dart) setelah asset karakter jadi.
class CosmicMascot extends StatefulWidget {
  const CosmicMascot({super.key, this.size = 160, this.onTap});

  final double size;
  final VoidCallback? onTap;

  @override
  State<CosmicMascot> createState() => _CosmicMascotState();
}

class _CosmicMascotState extends State<CosmicMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.mascotSemanticLabel(mascotName),
      button: widget.onTap != null,
      child: SpringTap(
        onTap: widget.onTap,
        pressedScale: 0.92,
        haptic: HapticFeedback.selectionClick,
        child: AnimatedBuilder(
          animation: _float,
          builder: (_, child) {
            final t = Curves.easeInOut.transform(_float.value);
            return Transform.translate(
              offset: Offset(0, -8 * t),
              child: Transform.rotate(angle: (t - 0.5) * 0.05, child: child),
            );
          },
          // Maskot hanya ditransformasi, tidak digambar ulang tiap frame.
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _MascotPainter(),
              isComplex: true,
              willChange: false,
            ),
          ),
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final body = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5B9BFF), Color(0xFF2F62E8)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Telinga.
    for (final dx in [0.30, 0.70]) {
      canvas.drawPath(
        Path()
          ..moveTo(w * (dx - 0.10), h * 0.34)
          ..quadraticBezierTo(w * dx, h * 0.02, w * (dx + 0.10), h * 0.34)
          ..close(),
        body,
      );
    }

    // Badan: blob membulat, lebih lebar di bawah.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.50, h * 0.18)
        ..cubicTo(w * 0.86, h * 0.18, w * 0.94, h * 0.48, w * 0.92, h * 0.68)
        ..cubicTo(w * 0.90, h * 0.90, w * 0.72, h * 0.96, w * 0.50, h * 0.96)
        ..cubicTo(w * 0.28, h * 0.96, w * 0.10, h * 0.90, w * 0.08, h * 0.68)
        ..cubicTo(w * 0.06, h * 0.48, w * 0.14, h * 0.18, w * 0.50, h * 0.18)
        ..close(),
      body,
    );

    // Mata.
    final eyeWhite = Paint()..color = Colors.white;
    final pupil = Paint()..color = const Color(0xFF0A192F);
    for (final dx in [0.36, 0.64]) {
      final c = Offset(w * dx, h * 0.52);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: w * 0.20, height: h * 0.24),
        eyeWhite,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: c.translate(0, h * 0.02),
          width: w * 0.12,
          height: h * 0.15,
        ),
        pupil,
      );
      canvas.drawCircle(c.translate(-w * 0.03, -h * 0.03), w * 0.025, eyeWhite);
    }

    // Senyum.
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.66),
        width: w * 0.16,
        height: h * 0.10,
      ),
      0,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF0A192F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.022
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_MascotPainter oldDelegate) => false;
}

/// Balon ucapan maskot untuk onboarding.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SoftCard(
          radius: AppRadius.cardInner,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: 12,
          ),
          child: Text(text, style: context.palette.body),
        ),
        Padding(
          padding: const EdgeInsets.only(left: AppSpace.lg),
          child: CustomPaint(
            size: const Size(18, 10),
            painter: _TailPainter(context.palette.backgroundPrimary),
          ),
        ),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter(this.color);

  /// Harus sama dengan warna [SoftCard] di atasnya, jadi ikut palet.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..quadraticBezierTo(size.width * 0.3, size.height * 0.4, 0, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) => oldDelegate.color != color;
}
