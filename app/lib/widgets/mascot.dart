import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n_ext.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import 'soft_ui.dart';

/// Nama placeholder. Maskot final butuh nama dan desain orisinal —
/// docs/06-open-questions.md #17.
const mascotName = 'Lumi';

/// Dua ukuran maskot, masing-masing dengan alasannya (R-31).
///
/// [kMascotHero] untuk layar yang isinya hanya maskot dan satu kalimat, tempat
/// ia memang jadi pusat perhatian. [kMascotInline] untuk maskot yang duduk di
/// dalam kartu bersama isi lain.
const kMascotHero = 160.0;
const kMascotInline = 140.0;

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
    with TickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  /// Satu putaran penuh berisi satu kedipan di ujungnya. Dibuat begini, bukan
  /// dengan pewaktu berkala, karena pewaktu tetap hidup setelah layarnya
  /// ditutup; putaran ini mati bersama widgetnya dan ikut berhenti saat
  /// Kurangi Gerak menyala.
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );

  /// Lompatan sekali jalan saat Lumi disentuh.
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 540),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Napas maskot berjalan selamanya, jadi setelan sistem inilah kendali
    // hentinya (R-39). Dipasang di sini, bukan initState, karena MediaQuery
    // baru bisa dibaca setelah dependensi terpasang.
    holdOrRepeat(_float, reduceMotion: context.reduceMotion);
    if (context.reduceMotion) {
      if (_blink.isAnimating) _blink.stop();
      _blink.value = 0;
    } else if (!_blink.isAnimating) {
      _blink.repeat();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _blink.dispose();
    _hop.dispose();
    super.dispose();
  }

  /// Seberapa tertutup mata pada posisi [t] dalam satu putaran.
  ///
  /// Nol hampir sepanjang putaran: kedipan yang terlalu sering membuat maskot
  /// tampak gelisah, bukan hidup.
  static double _blinkAt(double t) {
    const mulai = 0.94;
    if (t < mulai) return 0;
    return math.sin((t - mulai) / (1 - mulai) * math.pi);
  }

  void _handleTap() {
    if (!context.reduceMotion) _hop.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.mascotSemanticLabel(mascotName),
      button: widget.onTap != null,
      child: SpringTap(
        onTap: widget.onTap == null ? null : _handleTap,
        pressedScale: 0.92,
        haptic: HapticFeedback.selectionClick,
        child: AnimatedBuilder(
          animation: Listenable.merge([_float, _hop]),
          builder: (_, child) {
            final t = Curves.easeInOut.transform(_float.value);
            // Lompatan naik lalu turun dalam satu busur, dan badannya memipih
            // sesaat di awal — pipih sebelum melompat itulah yang membuat
            // lompatan terbaca sebagai tenaga, bukan sekadar geser ke atas.
            final hop = math.sin(_hop.value * math.pi);
            final squash = _hop.isAnimating
                ? math.sin(_hop.value * math.pi * 2)
                : 0.0;
            return Transform.translate(
              offset: Offset(0, -8 * t - 22 * hop),
              child: Transform.rotate(
                angle: (t - 0.5) * 0.05,
                child: Transform.scale(
                  scaleX: 1 + 0.06 * squash.clamp(-1.0, 0.0).abs(),
                  scaleY: 1 - 0.06 * squash.clamp(-1.0, 0.0).abs() + 0.05 * hop,
                  child: child,
                ),
              ),
            );
          },
          // Hanya mata yang digambar ulang saat berkedip; sisanya cuma
          // ditransformasi.
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _blink,
              builder: (_, _) => CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _MascotPainter(blink: _blinkAt(_blink.value)),
                isComplex: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  const _MascotPainter({this.blink = 0});

  /// 0 mata terbuka, 1 mata tertutup penuh.
  final double blink;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Isian pastel polos, tanpa gradasi: revisi 15 November meminta flat 2D
    // vector murni. Kedalaman kini datang dari bentuk dan bayangan, bukan
    // dari warna yang melandai.
    final body = Paint()..color = const Color(0xFF5B9BFF);

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
    // Kelopak menutup dari atas dan bawah sekaligus, jadi yang mengecil
    // tingginya, bukan seluruh matanya.
    final open = 1 - 0.92 * blink;
    for (final dx in [0.36, 0.64]) {
      final c = Offset(w * dx, h * 0.52);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: w * 0.20, height: h * 0.24 * open),
        eyeWhite,
      );
      if (open > 0.35) {
        canvas.drawOval(
          Rect.fromCenter(
            center: c.translate(0, h * 0.02 * open),
            width: w * 0.12,
            height: h * 0.15 * open,
          ),
          pupil,
        );
        canvas.drawCircle(
          c.translate(-w * 0.03, -h * 0.03 * open),
          w * 0.025,
          eyeWhite,
        );
      }
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
  bool shouldRepaint(_MascotPainter old) => old.blink != blink;
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
