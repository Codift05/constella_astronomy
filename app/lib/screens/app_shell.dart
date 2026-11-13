import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../theme/tokens.dart';
import '../widgets/app_tab_bar.dart';
import 'constellations_screen.dart';
import 'focus_session_screen.dart';
import 'sky_launchpad_screen.dart';

/// Tiga tab, satu per fitur PRD yang punya layar sendiri:
/// Langit (4.1), Rasi (4.2), Fokus (4.4).
/// Fitur 4.3 Astro-Transit belum punya layar karena belum dibangun.
enum AppTab { sky, constellations, focus }

extension AppTabView on AppTab {
  IconData get icon => switch (this) {
    AppTab.sky => Icons.nights_stay_rounded,
    AppTab.constellations => Icons.hub_rounded,
    AppTab.focus => Icons.access_time_rounded,
  };

  String label(BuildContext context) => switch (this) {
    AppTab.sky => context.l10n.tabSky,
    AppTab.constellations => context.l10n.tabConstellations,
    AppTab.focus => context.l10n.tabFocus,
  };
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab _tab = AppTab.sky;

  /// Arah geser isi tab: +1 saat pindah ke kanan, -1 ke kiri.
  int _direction = 1;

  void _select(AppTab tab) {
    if (tab == _tab) return;
    setState(() {
      _direction = tab.index > _tab.index ? 1 : -1;
      _tab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.backgroundSecondary,
      // Konten mengalir di bawah tab bar melayang, sesuai materials.md:
      // "allows content to scroll and peek through from beneath".
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) =>
            Stack(children: [...previous, ?current]),
        transitionBuilder: (child, animation) {
          final incoming = child.key == ValueKey(_tab);
          final begin = Offset(
            incoming ? 0.18 * _direction : -0.18 * _direction,
            0,
          );
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: begin,
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_tab),
          child: switch (_tab) {
            AppTab.sky => const SkyLaunchpadScreen(),
            AppTab.constellations => const ConstellationsScreen(),
            AppTab.focus => const FocusSessionScreen(),
          },
        ),
      ),
      bottomNavigationBar: AppTabBar<AppTab>(
        tabs: AppTab.values,
        current: _tab,
        onChanged: _select,
        iconOf: (t) => t.icon,
        labelOf: (t) => t.label(context),
      ),
    );
  }
}
