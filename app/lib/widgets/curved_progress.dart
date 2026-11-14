import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/motion.dart';
import '../theme/tokens.dart';
import 'entrance.dart';

/// Progress bar melengkung untuk Stardust Energy (PRD §4.4 "Status Bar":
/// "indikator pengumpulan poin eksplorasi dengan progress bar melengkung").
///
/// Busur terbuka di bawah, nilai di tengah. Pergerakannya memakai spring,
/// bukan kurva linear.
class CurvedProgressBar extends StatelessWidget {
  const CurvedProgressBar({
    super.key,
    required this.value,
    required this.label,
    this.caption,
    this.size = 180,
  });

  /// 0.0 sampai 1.0.
  final double value;

  /// Teks besar di tengah busur.
  final String label;
  final String? caption;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0.0, 1.0)),
      duration: context.calm(const Duration(milliseconds: 900)),
      curve: Curves.elasticOut,
      builder: (context, t, _) => SizedBox(
        width: size,
        // Tinggi ikut membesar sebagian saat Dynamic Type dinaikkan. Tanpa
        // ini, angka 40 pt di tengah tumbuh melewati kotak bertinggi tetap
        // dan Column-nya overflow — tidak terlihat selama kartu ini masih di
        // bawah lipatan layar, karena ListView belum membangunnya.
        height: size * 0.72 * _growth(context),
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _ArcPainter(
              t,
              track: p.controlSurface,
              fill: p.accentStrong,
            ),
            child: Center(
              // Jaring pengaman terakhir: pada skala teks ekstrem isinya
              // mengecil proporsional alih-alih melimpah keluar busur.
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size * 0.14),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CountUpText(
                        value: int.tryParse(label) ?? 0,
                        style: p.numeral.copyWith(fontSize: 40),
                      ),
                      if (caption != null) ...[
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          caption!,
                          textAlign: TextAlign.center,
                          style: p.caption,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Faktor pertumbuhan kotak terhadap skala teks, ditahan di 1,4x supaya
  /// busurnya tidak ikut melar tak terkendali di layar kecil.
  double _growth(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return (1 + (scale - 1) * 0.45).clamp(1.0, 1.4);
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter(this.value, {required this.track, required this.fill});

  final double value;

  /// Painter tidak bisa membaca [BuildContext], jadi warna palet diteruskan
  /// lewat konstruktor dan dibandingkan di [shouldRepaint].
  final Color track;
  final Color fill;

  /// Busur membentang 240 derajat, terbuka di bawah.
  static const _start = math.pi * 0.75;
  static const _sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.width - stroke,
    );

    canvas.drawArc(
      rect,
      _start,
      _sweep,
      false,
      Paint()
        ..color = track
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    if (value <= 0) return;
    canvas.drawArc(
      rect,
      _start,
      _sweep * value,
      false,
      // Satu warna penuh, bukan gradasi menyapu (revisi 15 November).
      // Nilai yang dibaca adalah panjang busurnya, dan itu tetap terbaca
      // jelas tanpa warna yang berubah sepanjang jalan.
      Paint()
        ..color = fill
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.track != track ||
      oldDelegate.fill != fill;
}
