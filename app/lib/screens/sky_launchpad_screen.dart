import 'package:flutter/material.dart';

import '../constellations/constellation_store.dart';
import '../l10n/l10n_ext.dart';
import '../stardust/stardust_store.dart';
import '../theme/tokens.dart';
import '../widgets/curved_progress.dart';
import '../widgets/mascot.dart';
import '../widgets/soft_ui.dart';
import '../widgets/theme_toggle.dart';
import 'cosmic_night_screen.dart';

/// Layar utama: landasan masuk ke AR, plus indikator Stardust Energy
/// (PRD §4.4 "Status Bar").
class SkyLaunchpadScreen extends StatelessWidget {
  const SkyLaunchpadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stardust = StardustScope.of(context);

    return Scaffold(
      backgroundColor: context.palette.backgroundSecondary,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.md,
            AppSpace.sm,
            AppSpace.md,
            kTabBarInset,
          ),
          children: [
            _Greeting(stardust: stardust.energy),
            const SizedBox(height: AppSpace.md),
            const _PortalHero(),
            const SizedBox(height: AppSpace.md),
            PillButton(
              label: l10n.enterCosmicNight,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CosmicNightScreen()),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Center(
              child: Text(l10n.cosmicNightHint, style: context.palette.caption),
            ),
            const SizedBox(height: AppSpace.lg),
            const _StardustCard(),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.stardust});

  final int stardust;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hour = DateTime.now().hour;
    final greeting = switch (hour) {
      >= 5 && < 11 => l10n.greetingMorning,
      >= 11 && < 15 => l10n.greetingAfternoon,
      >= 15 && < 19 => l10n.greetingEvening,
      _ => l10n.greetingNight,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            greeting,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.palette.largeTitle,
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        StardustPill(amount: stardust),
        const SizedBox(width: AppSpace.xs),
        const ThemeToggleButton(),
      ],
    );
  }
}

/// Kartu hero: maskot mengajak membuka portal.
class _PortalHero extends StatelessWidget {
  const _PortalHero();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.palette.heroHaloStart, context.palette.heroHaloEnd],
        ),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
        shadows: context.palette.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mascotName,
              style: context.palette.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpace.sm),
            Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.8,
                child: SpeechBubble(text: context.l10n.mascotSpeechSky),
              ),
            ),
            const Center(child: CosmicMascot(size: 140)),
          ],
        ),
      ),
    );
  }
}

/// Indikator Stardust Energy dengan progress bar melengkung (PRD §4.4).
class _StardustCard extends StatelessWidget {
  const _StardustCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stardust = StardustScope.of(context);
    final shapes = ConstellationScope.of(context).length;

    return SoftCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        children: [
          Text(l10n.stardustTitle, style: context.palette.body),
          const SizedBox(height: AppSpace.sm),
          CurvedProgressBar(
            value: stardust.tierProgress,
            label: '${stardust.energy}',
            caption: l10n.stardustCaption(stardust.energy, stardust.nextTier),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            '${l10n.focusMinutesTotal(stardust.focusMinutes)}  ·  '
            '${l10n.constellationsCount(shapes)}',
            textAlign: TextAlign.center,
            style: context.palette.caption,
          ),
        ],
      ),
    );
  }
}
