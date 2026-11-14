import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/l10n_ext.dart';
import '../sky/star_catalog.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import 'mascot.dart';
import 'soft_ui.dart';

/// Layar perayaan saat sebuah bintang berhasil ditangkap.
///
/// Muncul **hanya saat pengguna mengetuk untuk menangkap**, bukan setiap kali
/// bidikan menyenggol bintang. Bidikan mengunci dan lepas puluhan kali semenit
/// karena ponsel ada di tangan; perayaan yang ikut meledak sesering itu akan
/// berubah dari menyenangkan jadi menyiksa dalam dua menit.
class CatchCelebration extends StatelessWidget {
  const CatchCelebration({
    super.key,
    required this.star,
    required this.reward,
    required this.isNew,
    required this.onClose,
  });

  final Star star;

  /// Stardust yang diberikan. Nol kalau bintangnya sudah pernah ditangkap.
  final int reward;

  /// False kalau bintang ini sudah ada di koleksi.
  final bool isNew;

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final calm = context.reduceMotion;
    // Saat Kurangi Gerak menyala, seluruh gerak masuk runtuh jadi nol; isinya
    // tetap muncul utuh, hanya tanpa pantulan.
    final d = calm ? Duration.zero : const Duration(milliseconds: 420);

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.82),
        child: SafeArea(
          // Bisa digulir: di layar pendek, atau saat Dynamic Type dinaikkan,
          // isinya lebih tinggi dari ruang yang ada. Tanpa ini ia meluap dan
          // sebagian perayaan tidak pernah terlihat.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Sparkles(
                        still: calm,
                        child: const CosmicMascot(size: 150),
                      ),
                      const SizedBox(height: AppSpace.lg),

                      Text(
                        isNew ? l10n.starCaught : l10n.starAlreadyCaught,
                        textAlign: TextAlign.center,
                        style: AppText.largeTitle.copyWith(
                          color: AppNight.accent,
                        ),
                      ).animate().scale(
                        duration: d,
                        curve: Curves.easeOutBack,
                        begin: const Offset(0.6, 0.6),
                      ),

                      const SizedBox(height: AppSpace.sm),
                      Text(
                        star.displayName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title2.copyWith(
                          color: AppNight.onSurface,
                        ),
                      ).animate().fadeIn(duration: d),

                      const SizedBox(height: AppSpace.xs),
                      Text(
                        star.magnitude > 3
                            ? l10n.starCatchPraiseDim
                            : l10n.starCatchPraise,
                        textAlign: TextAlign.center,
                        style: AppText.caption.copyWith(
                          color: AppNight.onSurfaceMuted,
                        ),
                      ).animate().fadeIn(duration: d, delay: d * 0.3),

                      const SizedBox(height: AppSpace.lg),
                      _StatRow(star: star, duration: d),

                      const SizedBox(height: AppSpace.xl),
                      SizedBox(
                        width: double.infinity,
                        child: PillButton(
                          label: reward > 0
                              ? l10n.claimStardust(reward)
                              : l10n.closeCelebration,
                          color: AppNight.accent,
                          labelColor: AppNight.onAccent,
                          onPressed: onClose,
                        ),
                      ).animate().slideY(
                        duration: d,
                        delay: d * 0.6,
                        curve: Curves.easeOutBack,
                        begin: 0.4,
                      ),
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
}

/// Tiga kartu data berdampingan, masuk satu per satu.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.star, required this.duration});

  final Star star;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cards = <({String label, String value, Color tint})>[
      (
        label: l10n.statDistance,
        value: star.hasDistance
            ? '${star.lightYears >= 100 ? star.lightYears.round() : star.lightYears.toStringAsFixed(1)} ly'
            : '?',
        tint: const Color(0xFF8FB8FF),
      ),
      (
        label: l10n.statMagnitude,
        value: star.magnitude.toStringAsFixed(2),
        tint: const Color(0xFF9BE59B),
      ),
      (
        label: l10n.statConstellation,
        value: star.constellation,
        tint: const Color(0xFFBFC6FF),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpace.sm),
          Expanded(
            child:
                _StatCard(
                  label: cards[i].label,
                  value: cards[i].value,
                  tint: cards[i].tint,
                ).animate().scale(
                  duration: duration,
                  delay: duration * (0.2 * i),
                  curve: Curves.easeOutBack,
                  begin: const Offset(0.7, 0.7),
                ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.tint,
  });

  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // Isian pastel polos, tanpa gradasi: revisi 14 November meminta flat 2D.
      decoration: ShapeDecoration(
        color: tint.withValues(alpha: 0.18),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardInner),
          side: BorderSide(color: tint.withValues(alpha: 0.45)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: 12,
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppText.captionSmall.copyWith(color: tint),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppText.subhead
                  .withWeight(FontWeight.w700)
                  .copyWith(color: AppNight.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

/// Percik yang menyembur keluar dari maskot sekali, lalu diam.
///
/// Sekali, bukan berulang: perayaan ini layar penuh dan menutup kamera, jadi
/// percik yang berdenyut terus akan menahan mata lebih lama dari yang pantas.
class _Sparkles extends StatelessWidget {
  const _Sparkles({required this.child, required this.still});

  final Widget child;
  final bool still;

  static final _rng = math.Random(20261115);
  static final _seeds = List.generate(
    12,
    (_) => (
      angle: _rng.nextDouble() * math.pi * 2,
      distance: 70 + _rng.nextDouble() * 60,
      size: 3 + _rng.nextDouble() * 5,
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (still) return child;
    return SizedBox(
      width: 260,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final s in _seeds)
            Transform.translate(
              offset: Offset(
                math.cos(s.angle) * s.distance,
                math.sin(s.angle) * s.distance * 0.8,
              ),
              child:
                  Container(
                        width: s.size,
                        height: s.size,
                        decoration: const BoxDecoration(
                          color: AppNight.accent,
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 180.ms)
                      .then()
                      .fadeOut(duration: 600.ms)
                      .scaleXY(begin: 0.3, end: 1.4, duration: 780.ms),
            ),
          child
              .animate()
              .scaleXY(
                begin: 0.5,
                end: 1,
                duration: 520.ms,
                curve: Curves.elasticOut,
              )
              .shakeY(hz: 2, amount: 3, duration: 600.ms),
        ],
      ),
    );
  }
}
