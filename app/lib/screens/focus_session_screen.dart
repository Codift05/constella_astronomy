import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../focus/focus_options.dart';
import '../focus/focus_session.dart';
import '../l10n/l10n_ext.dart';
import '../theme/tokens.dart';
import '../widgets/mascot.dart';
import '../widgets/soft_ui.dart';
import 'cosmic_night_screen.dart';

/// PRD §4.4 — layar pengaturan sesi. Tombolnya memulai mode Malam Kosmik,
/// dan hitung mundurnya berjalan di dalam mode itu.
class FocusSessionScreen extends StatefulWidget {
  const FocusSessionScreen({super.key});

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> {
  int _minutes = FocusDuration.defaultMinutes;

  void _setMinutes(int value) {
    if (value == _minutes) return;
    HapticFeedback.selectionClick();
    setState(() => _minutes = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.backgroundSecondary,
      body: Stack(
        children: [
          const _SkyBackdrop(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.md,
                      AppSpace.sm,
                      AppSpace.md,
                      AppSpace.lg,
                    ),
                    child: Column(
                      children: [
                        Text(
                          context.l10n.mascotReadyToFocus(mascotName),
                          textAlign: TextAlign.center,
                          style: context.palette.caption,
                        ),
                        const SizedBox(height: AppSpace.md),
                        const CosmicMascot(size: kMascotInline),
                        const SizedBox(height: AppSpace.lg),
                        _durationCard(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpace.md,
                    0,
                    AppSpace.md,
                    // Sebagai rute yang di-push tidak ada tab bar di bawahnya,
                    // jadi ruang itu tidak perlu disisakan lagi.
                    Navigator.of(context).canPop() ? AppSpace.xl : kTabBarInset,
                  ),
                  child: PillButton(
                    label: context.l10n.startFocusSession,
                    onPressed: _startSession,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      child: Row(
        children: [
          if (Navigator.of(context).canPop())
            RoundIconButton(
              icon: Icons.chevron_left_rounded,
              semanticLabel: context.l10n.back,
              onPressed: () => Navigator.of(context).maybePop(),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              context.l10n.focusSessionTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.palette.title,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _durationCard() {
    return SoftCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        children: [
          Text(context.l10n.focusTime, style: context.palette.body),
          const SizedBox(height: AppSpace.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RoundIconButton(
                icon: Icons.remove_rounded,
                semanticLabel: context.l10n.decreaseDuration,
                onPressed: FocusDuration.canDecrease(_minutes)
                    ? () => _setMinutes(FocusDuration.shift(_minutes, -1))
                    : null,
              ),
              // Angka besar mengecil sendiri saat Dynamic Type membesar,
              // daripada mendorong tombol minus dan plus keluar layar.
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('$_minutes', style: context.palette.numeral),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      context.l10n.minutesUnit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.palette.caption,
                    ),
                  ],
                ),
              ),
              RoundIconButton(
                icon: Icons.add_rounded,
                semanticLabel: context.l10n.increaseDuration,
                onPressed: FocusDuration.canIncrease(_minutes)
                    ? () => _setMinutes(FocusDuration.shift(_minutes, 1))
                    : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final m in FocusDuration.presets)
                SoftChip(
                  label: '${m}m',
                  dense: true,
                  selected: m == _minutes,
                  onTap: () => _setMinutes(m),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _startSession() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CosmicNightScreen(session: FocusSession.start(_minutes)),
      ),
    );
  }
}

/// Blob terang besar di belakang layar.
class _SkyBackdrop extends StatelessWidget {
  const _SkyBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -200,
      left: -80,
      right: -80,
      height: 420,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.palette.accentWash,
              context.palette.backgroundSecondary,
            ],
          ),
          borderRadius: BorderRadius.circular(300),
        ),
      ),
    );
  }
}
