import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_settings.dart';
import '../l10n/l10n_ext.dart';
import '../theme/tokens.dart';
import 'soft_ui.dart';

/// Pemutar tema: ikut sistem -> terang -> gelap -> ikut sistem.
///
/// Default-nya "ikut sistem", yang diminta Apple di dark-mode.md: aplikasi
/// sebaiknya mengikuti pengaturan perangkat, dan menyediakan pilihan manual
/// hanya sebagai tambahan — bukan sebagai satu-satunya cara.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    final settings = SettingsScope.of(context);
    final mode = settings.themeMode;

    final (icon, name) = switch (mode) {
      ThemeMode.system => (
        Icons.brightness_auto_rounded,
        l10n.appearanceSystem,
      ),
      ThemeMode.light => (Icons.light_mode_rounded, l10n.appearanceLight),
      ThemeMode.dark => (Icons.dark_mode_rounded, l10n.appearanceDark),
    };

    return Semantics(
      button: true,
      label: l10n.appearanceLabel(name),
      excludeSemantics: true,
      child: Tooltip(
        message: name,
        child: SpringTap(
          onTap: settings.cycleThemeMode,
          pressedScale: 0.88,
          haptic: HapticFeedback.selectionClick,
          child: Container(
            // 44 pt: target sentuh default iOS.
            width: kMinTapTarget,
            height: kMinTapTarget,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: p.backgroundPrimary,
              shape: const CircleBorder(),
              shadows: p.softShadow,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              // Ikon berputar seperempat putaran saat berganti, supaya
              // pergantian mode terasa sebagai satu gerakan, bukan kedipan.
              transitionBuilder: (child, animation) => RotationTransition(
                turns: Tween(begin: 0.75, end: 1.0).animate(animation),
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Icon(
                icon,
                key: ValueKey(mode),
                size: 20,
                color: p.accentStrong,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
