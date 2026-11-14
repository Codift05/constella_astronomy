import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/motion.dart';
import '../theme/tokens.dart';
import 'soft_ui.dart';

/// Tab bar melayang bergaya iOS: kapsul material transparan di atas konten,
/// dengan indikator yang meluncur memakai spring physics.
///
/// Mengikuti materials.md > Liquid Glass: "a distinct functional layer for
/// controls and navigation elements ... that floats above the content layer".
class AppTabBar<T> extends StatefulWidget {
  const AppTabBar({
    super.key,
    required this.tabs,
    required this.current,
    required this.onChanged,
    required this.iconOf,
    required this.labelOf,
  });

  final List<T> tabs;
  final T current;
  final ValueChanged<T> onChanged;
  final IconData Function(T) iconOf;
  final String Function(T) labelOf;

  @override
  State<AppTabBar<T>> createState() => _AppTabBarState<T>();
}

class _AppTabBarState<T> extends State<AppTabBar<T>>
    with SingleTickerProviderStateMixin {
  /// Posisi indikator dalam satuan indeks tab, dianimasikan dengan spring
  /// supaya perpindahan terasa menerus, bukan meloncat.
  late final AnimationController _slide = AnimationController.unbounded(
    vsync: this,
    value: widget.tabs.indexOf(widget.current).toDouble(),
  );

  @override
  void didUpdateWidget(AppTabBar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.tabs.indexOf(widget.current).toDouble();
    if (target != _slide.value) {
      springTo(
        _slide,
        AppSpring.popup,
        target,
        reduceMotion: context.reduceMotion,
      );
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.tabs.length;

    // Bar ini melayang, jadi ia butuh jarak nyata ke tepi bawah — menempel
    // membuatnya terbaca sebagai bar biasa yang menempel di dasar layar.
    // Di perangkat berhome indicator jaraknya dihitung dari inset sistem;
    // di perangkat tanpa inset tetap ada jarak minimum.
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    final bottomGap = math.max<double>(inset, 14) + 10;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, bottomGap),
      child: _TabBarSurface(
        padding: const EdgeInsets.all(6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slotWidth = constraints.maxWidth / count;
            return Stack(
              children: [
                AnimatedBuilder(
                  animation: _slide,
                  builder: (context, child) => Positioned(
                    left: _slide.value.clamp(0, count - 1) * slotWidth,
                    top: 0,
                    bottom: 0,
                    width: slotWidth,
                    child: child!,
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: ShapeDecoration(
                      color: context.palette.accentWash,
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final tab in widget.tabs)
                      Expanded(
                        child: _TabItem(
                          icon: widget.iconOf(tab),
                          label: widget.labelOf(tab),
                          selected: tab == widget.current,
                          onTap: () {
                            if (tab == widget.current) return;
                            HapticFeedback.selectionClick();
                            widget.onChanged(tab);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Permukaan tab bar. Blur backdrop sengaja dihindari: ia memaksa saveLayer
/// atas seluruh konten di belakangnya pada setiap frame, dan konten itu
/// bergerak terus karena maskot beranimasi.
class _TabBarSurface extends StatelessWidget {
  const _TabBarSurface({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: p.tabBarSurface,
        shape: StadiumBorder(side: BorderSide(color: p.tabBarBorder)),
        shadows: p.liftedShadow,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.actionPrimary : p.textSecondary;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: SpringTap(
        onTap: onTap,
        pressedScale: 0.92,
        haptic: HapticFeedback.selectionClick,
        child: ConstrainedBox(
          // 44 pt: target sentuh default iOS.
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: selected ? 1 : 0),
                duration: context.calm(const Duration(milliseconds: 240)),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Transform.translate(
                  offset: Offset(0, -2 * t),
                  child: child,
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.captionSmall.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
