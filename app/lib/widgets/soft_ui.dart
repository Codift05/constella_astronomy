import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Membungkus child dengan scale spring saat ditekan, plus haptic.
/// Semua elemen yang bisa ditekan memakai ini — docs/03-design-system.md §3.4.
class SpringTap extends StatefulWidget {
  const SpringTap({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
    this.haptic = HapticFeedback.lightImpact,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final Future<void> Function() haptic;

  @override
  State<SpringTap> createState() => _SpringTapState();
}

class _SpringTapState extends State<SpringTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _springTo(double target) {
    _c.animateWith(
      SpringSimulation(AppSpring.press, _c.value, target, _c.velocity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _springTo(widget.pressedScale) : null,
      onTapUp: enabled ? (_) => _springTo(1) : null,
      onTapCancel: enabled ? () => _springTo(1) : null,
      onTap: enabled
          ? () {
              widget.haptic();
              widget.onTap!();
            }
          : null,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.scale(scale: _c.value, child: child),
        child: widget.child,
      ),
    );
  }
}

/// Kartu squircle putih solid dengan soft shadow.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.md),
    this.color,
    this.radius = AppRadius.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// `null` berarti ikut [AppPalette.backgroundPrimary] tema aktif.
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final border = p.cardBorder;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: color ?? p.backgroundPrimary,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(radius),
          // Di tema gelap bayangan hitam tidak terlihat di atas latar nyaris
          // hitam, jadi tepi tipis inilah yang memisahkan kartu dari latar.
          side: border == null
              ? BorderSide.none
              : BorderSide(color: border, width: 1),
        ),
        shadows: p.softShadow,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Kartu material ultra-thin transparan dengan blur di belakangnya.
/// Dipakai untuk label landmark, pop-up, dan bottom sheet.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.md),
    this.radius = AppRadius.card,
    this.blur = 24,
    this.tint,
    this.grouped = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;

  /// Opacity dijaga tinggi supaya teks di atasnya tetap lolos WCAG AA —
  /// blur bukan pengganti kontras (docs/03-design-system.md §3.5).
  /// `null` berarti ikut tema; layar AR mengisinya dengan warna tetap.
  final Color? tint;

  /// Saat true, blur ini berbagi satu lintasan backdrop dengan kaca lain di
  /// bawah [BackdropGroup] terdekat. Beberapa kaca dalam satu layar wajib
  /// memakai ini: tanpanya tiap kaca memicu saveLayer sendiri-sendiri.
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRSuperellipse(
      borderRadius: BorderRadius.circular(radius),
      child: _backdrop(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tint ?? p.glassTint,
            border: Border.all(color: p.glassBorder, width: 1),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }

  Widget _backdrop({required Widget child}) {
    final filter = ImageFilter.blur(sigmaX: blur, sigmaY: blur);
    return grouped
        ? BackdropFilter.grouped(filter: filter, child: child)
        : BackdropFilter(filter: filter, child: child);
  }
}

/// Tombol aksi utama: kapsul Navy. Satu per layar.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.labelColor,
  });

  final String label;
  final VoidCallback? onPressed;

  /// `null` berarti ikut [AppPalette.actionPrimary].
  final Color? color;

  /// `null` berarti ikut [AppPalette.onAction]. Diisi hanya kalau [color]
  /// diisi juga, karena pasangan warna inilah yang menentukan kontras.
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fill = color ?? p.actionPrimary;
    final enabled = onPressed != null;
    return SpringTap(
      onTap: onPressed,
      pressedScale: 0.97,
      haptic: HapticFeedback.mediumImpact,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: 14,
        ),
        decoration: ShapeDecoration(
          color: enabled ? fill : fill.withValues(alpha: 0.4),
          shape: const StadiumBorder(),
          shadows: enabled ? p.liftedShadow : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.button.copyWith(color: labelColor ?? p.onAction),
        ),
      ),
    );
  }
}

/// Chip kapsul pastel. Terpilih = isi penuh accent, teks putih.
class SoftChip extends StatelessWidget {
  const SoftChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.leading,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SpringTap(
      onTap: onTap,
      pressedScale: 0.93,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        constraints: const BoxConstraints(minHeight: kMinTapTarget),
        padding: EdgeInsets.symmetric(
          horizontal: dense ? AppSpace.md : AppSpace.lg,
          vertical: 10,
        ),
        decoration: ShapeDecoration(
          color: selected ? p.chipSelectedBg : p.accentWash,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpace.sm),
            ],
            // Flexible supaya label panjang, atau teks yang diperbesar lewat
            // Dynamic Type, memendek alih-alih melewati batas chip.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.subhead.copyWith(
                  fontFamily: AppFont.rounded,
                  fontWeight: FontWeight.w600,
                  // Putih di atas pastel hanya 2.01:1. Teks gelap = 8.77:1.
                  color: selected ? p.chipSelectedText : p.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol bulat kecil, dipakai untuk minus/plus pada stepper durasi.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: SpringTap(
        onTap: onPressed,
        pressedScale: 0.88,
        child: Container(
          width: 48,
          height: 48,
          decoration: ShapeDecoration(
            color: p.controlSurface,
            shape: const CircleBorder(),
          ),
          child: Icon(
            icon,
            size: 22,
            color: enabled ? p.textPrimary : p.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Progress bar tipis rounded untuk Stardust Energy dan Today's Focus.
class SoftProgressBar extends StatelessWidget {
  const SoftProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
  });

  /// 0.0 sampai 1.0.
  final double value;
  final double height;

  /// `null` berarti ikut [AppPalette.accentStrong].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: p.controlSurface,
        valueColor: AlwaysStoppedAnimation(color ?? p.accentStrong),
      ),
    );
  }
}

/// Indikator Stardust Energy di pojok layar.
class StardustPill extends StatelessWidget {
  const StardustPill({super.key, required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: '$amount stardust energy',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: ShapeDecoration(
          color: p.backgroundPrimary,
          shape: const StadiumBorder(),
          shadows: p.softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 16, color: p.accentStrong),
            const SizedBox(width: 6),
            Text(
              '$amount',
              style: p.body.copyWith(fontFamily: AppFont.rounded),
            ),
          ],
        ),
      ),
    );
  }
}
