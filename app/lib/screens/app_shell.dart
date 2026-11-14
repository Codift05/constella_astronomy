import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../theme/tokens.dart';
import '../widgets/app_tab_bar.dart';
import 'constellations_screen.dart';
import 'sky_launchpad_screen.dart';
import 'star_catcher_screen.dart';

/// Tab hanya untuk tujuan yang berdiri sendiri: Langit (PRD 4.1),
/// Bintang, dan Rasi (4.2).
///
/// Fokus (4.4) sengaja **bukan** tab. PRD menyebutnya sebagai cara masuk ke
/// Malam Kosmik — "Tombol 'Start focus session' memulai timer dan masuk ke
/// mode Malam Kosmik" — bukan tujuan tersendiri. Saat ia berdiri sebagai tab
/// setara, aplikasinya terbaca seperti timer belajar yang nyempil, bukan
/// aplikasi eksplorasi langit. Pintu masuknya kini ada di layar Langit.
enum AppTab { sky, stars, constellations }

extension AppTabView on AppTab {
  IconData get icon => switch (this) {
    AppTab.sky => Icons.nights_stay_rounded,
    AppTab.stars => Icons.filter_center_focus_rounded,
    AppTab.constellations => Icons.hub_rounded,
  };

  String label(BuildContext context) => switch (this) {
    AppTab.sky => context.l10n.tabSky,
    AppTab.stars => context.l10n.tabStars,
    AppTab.constellations => context.l10n.tabConstellations,
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
            AppTab.stars => const StarCatcherScreen(),
            AppTab.constellations => const ConstellationsScreen(),
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
