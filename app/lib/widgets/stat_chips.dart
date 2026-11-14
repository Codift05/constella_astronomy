import 'package:flutter/material.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';

/// Satu angka beserta namanya, dalam kotak pastel.
typedef StatChip = ({String label, String value, Color tint});

/// Warna chip baku, dipakai berurutan supaya layar mana pun memberi arti yang
/// sama pada warna yang sama.
abstract final class StatTint {
  static const distance = Color(0xFF8FB8FF);
  static const brightness = Color(0xFF9BE59B);
  static const constellation = Color(0xFFBFC6FF);
}

/// Sebaris chip angka yang masuk satu per satu.
///
/// Dipakai di dua tempat: kartu bintang yang sedang dibidik, dan layar
/// perayaan setelah bintangnya tertangkap. Keduanya menyebut angka yang sama
/// tentang bintang yang sama, jadi keduanya memakai bentuk yang sama.
class StatChipRow extends StatelessWidget {
  const StatChipRow({
    super.key,
    required this.chips,
    this.stagger = const Duration(milliseconds: 420),
    this.animate = true,
  });

  final List<StatChip> chips;

  /// Lama satu chip masuk. Chip berikutnya menyusul di seperlima waktu itu,
  /// cukup untuk terbaca sebagai urutan tanpa terasa lamban.
  final Duration stagger;

  final bool animate;

  @override
  Widget build(BuildContext context) {
    final d = context.calm(stagger);
    final moving = animate && !context.reduceMotion && d > Duration.zero;

    // IntrinsicHeight, bukan stretch: baris ini dipakai juga di dalam daerah
    // yang bisa menggulung, dan di sana tingginya tidak terbatas sehingga
    // stretch memaksa chip setinggi tak hingga. Yang dibutuhkan hanya
    // "setinggi chip yang paling tinggi", dan itulah yang IntrinsicHeight beri.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpace.sm),
            Expanded(
              child: moving
                  ? _Enter(
                      // Jeda antar chip dibuat sebagai potongan dari satu
                      // animasi, bukan sebagai penundaan berpewaktu. Penundaan
                      // meninggalkan timer hidup kalau layarnya keburu
                      // ditutup; interval ikut mati bersama widgetnya.
                      interval: Interval(
                        (0.18 * i).clamp(0.0, 0.6),
                        1,
                        curve: Curves.easeOutBack,
                      ),
                      duration: d,
                      child: _Chip(chip: chips[i]),
                    )
                  : _Chip(chip: chips[i]),
            ),
          ],
        ],
      ),
    );
  }
}

/// Satu chip yang masuk dengan mengembang sedikit melewati ukurannya.
class _Enter extends StatelessWidget {
  const _Enter({
    required this.interval,
    required this.duration,
    required this.child,
  });

  final Interval interval;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: interval,
      builder: (context, t, child) => Opacity(
        // Kemunculannya diselesaikan lebih awal daripada gerakannya, supaya
        // chip sudah terbaca saat pegasnya masih mengayun.
        opacity: (t * 2).clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
      ),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.chip});

  final StatChip chip;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // Isian pastel polos, tanpa gradasi: revisi 14 November meminta flat 2D.
      decoration: ShapeDecoration(
        color: chip.tint.withValues(alpha: 0.18),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardInner),
          side: BorderSide(color: chip.tint.withValues(alpha: 0.45)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              chip.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppText.captionSmall.copyWith(color: chip.tint),
            ),
            const SizedBox(height: 2),
            Text(
              chip.value,
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
