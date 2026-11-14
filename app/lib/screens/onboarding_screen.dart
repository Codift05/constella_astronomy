import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_settings.dart';
import '../l10n/l10n_ext.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import '../widgets/mascot.dart';
import '../widgets/soft_ui.dart';

/// PRD §4.4 — "speech bubble memandu pengguna baru melewati onboarding".
///
/// Langkah terakhir menjelaskan untuk apa kamera dipakai sebelum sistem
/// memunculkan dialog izin, sesuai privacy.md: minta izin dalam konteks,
/// dengan alasan yang jujur.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  List<(String, String)> _steps(BuildContext context) {
    final l10n = context.l10n;
    return [
      (l10n.onboardingWelcomeTitle(mascotName), l10n.onboardingWelcomeBody),
      (l10n.onboardingPortalTitle, l10n.onboardingPortalBody),
      (l10n.onboardingDrawTitle, l10n.onboardingDrawBody),
      (l10n.onboardingCameraTitle, l10n.onboardingCameraBody),
    ];
  }

  void _next(int total) {
    HapticFeedback.selectionClick();
    if (_index >= total - 1) {
      _finish();
      return;
    }
    _pages.nextPage(
      duration: context.calm(const Duration(milliseconds: 420)),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish() => SettingsScope.of(context).completeOnboarding();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = _steps(context);
    final isLast = _index == steps.length - 1;

    return Scaffold(
      backgroundColor: context.palette.backgroundSecondary,
      body: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.sm),
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(
                        l10n.onboardingSkip,
                        style: context.palette.caption,
                      ),
                    ),
                  ),
                ),
                // Maskot tetap di tempat sementara teksnya berganti, supaya
                // terasa satu karakter yang sedang bicara, bukan empat layar.
                const CosmicMascot(size: kMascotHero),
                const SizedBox(height: AppSpace.lg),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: steps.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final (title, body) = steps[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.lg,
                        ),
                        child: Column(
                          // Dipusatkan di ruang yang tersisa. Perataan awal
                          // menyisakan rongga besar tanpa makna di ponsel
                          // tinggi (layout.md > Visual hierarchy).
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SpeechBubble(text: title),
                            const SizedBox(height: AppSpace.md),
                            Text(
                              body,
                              textAlign: TextAlign.center,
                              style: context.palette.body.copyWith(
                                color: context.palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                _Dots(count: steps.length, index: _index),
                const SizedBox(height: AppSpace.md),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg,
                    0,
                    AppSpace.lg,
                    AppSpace.lg,
                  ),
                  child: PillButton(
                    label: isLast ? l10n.onboardingStart : l10n.onboardingNext,
                    onPressed: () => _next(steps.length),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: context.calm(const Duration(milliseconds: 240)),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 22 : 8,
            height: 8,
            decoration: ShapeDecoration(
              color: i == index
                  ? context.palette.accentStrong
                  : context.palette.accentWash,
              shape: const StadiumBorder(),
            ),
          ),
      ],
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -220,
      left: -80,
      right: -80,
      height: 480,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // Pastel polos, bukan gradasi (revisi 15 November, flat 2D).
          color: context.palette.accentWash,
          borderRadius: BorderRadius.circular(300),
        ),
      ),
    );
  }
}
