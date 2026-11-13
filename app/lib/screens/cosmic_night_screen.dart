import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../ar/sky_attitude.dart';
import '../constellations/constellation_draft.dart';
import '../constellations/constellation_store.dart';
import '../focus/focus_session.dart';
import '../l10n/l10n_ext.dart';
import '../stardust/stardust_rules.dart';
import '../stardust/stardust_store.dart';
import '../theme/tokens.dart';
import '../widgets/constellation_layer.dart';
import '../widgets/soft_ui.dart';

/// Fitur 4.1 — AR Time-Bubble. Portal spasial yang menimpa tangkapan kamera
/// siang hari menjadi malam tata surya.
///
/// shortcut: isi portal masih starfield yang digambar sendiri, bukan sky
/// replacement ARKit/ARCore dan bukan posisi planet real-time. Upgrade setelah
/// docs/06-open-questions.md #1, #2 dan #6 dijawab.
class CosmicNightScreen extends StatefulWidget {
  const CosmicNightScreen({super.key, this.session});

  /// Sesi fokus yang berjalan di dalam mode ini. null berarti eksplorasi
  /// bebas tanpa hitung mundur (PRD §4.4).
  final FocusSession? session;

  @override
  State<CosmicNightScreen> createState() => _CosmicNightScreenState();
}

enum _CameraState { loading, ready, denied, unavailable }

class _CosmicNightScreenState extends State<CosmicNightScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _camera;
  _CameraState _state = _CameraState.loading;

  /// Sudut elevasi kamera. Dipakai untuk menempatkan cakrawala dan menambatkan
  /// orb ke langit alih-alih ke layar.
  late final SkyAttitude _attitude = SkyAttitude()..start();

  /// Elevasi saat layar dibuka. Orb dipasang di titik langit ini.
  double? _orbElevation;

  /// 0 = orb kuncup, 1 = portal penuh layar.
  late final AnimationController _portal = AnimationController.unbounded(
    vsync: this,
    value: 0,
  );
  bool _portalOpen = false;
  bool _reachedFull = false;

  /// Fitur 4.2 — rasi bintang yang sedang digambar di dalam portal.
  ConstellationDraft _draft = const ConstellationDraft();
  final _nameController = TextEditingController();

  /// Fitur 4.4 — hitung mundur sesi fokus.
  FocusSession? _session;
  Timer? _tick;
  bool _awarded = false;

  @override
  void initState() {
    super.initState();
    _portal.addListener(_onPortalTick);
    _startCamera();

    _session = widget.session;
    if (_session != null) {
      // Sisa waktu dihitung dari jam dinding, jadi tick sedetik sekali hanya
      // untuk menyegarkan tampilan — ketelitiannya tidak bergantung padanya.
      _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    }
  }

  void _onTick() {
    if (!mounted) return;
    final session = _session;
    if (session == null) return;
    setState(() {});
    if (!_awarded && !session.isPaused && session.isComplete(DateTime.now())) {
      _awarded = true;
      _tick?.cancel();
      unawaited(StardustScope.of(context).completeSession(session));
      HapticFeedback.heavyImpact();
      _showSessionComplete(session);
    }
  }

  void _togglePause() {
    final session = _session;
    if (session == null) return;
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    setState(() {
      _session = session.isPaused ? session.resume(now) : session.pause(now);
    });
  }

  Future<void> _confirmGiveUp() async {
    final l10n = context.l10n;
    final giveUp = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.giveUpTitle),
        content: Text(l10n.giveUpBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.giveUpCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.giveUpConfirm),
          ),
        ],
      ),
    );
    if (giveUp != true || !mounted) return;
    // Sesi yang dibatalkan tidak memberi Stardust.
    _tick?.cancel();
    Navigator.of(context).maybePop();
  }

  Future<void> _showSessionComplete(FocusSession session) async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.sessionCompleteTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.sessionCompleteBodyShort(session.totalMinutes)),
            const SizedBox(height: AppSpace.sm),
            Text(
              l10n.stardustEarned(
                StardustRules.forFocusSession(session.totalMinutes),
              ),
              style: AppText.title.copyWith(fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    _portal.removeListener(_onPortalTick);
    _portal.dispose();
    _nameController.dispose();
    _camera?.dispose();
    _attitude.dispose();
    super.dispose();
  }

  /// Perangkat tanpa kamera belakang (sebagian emulator) membuat
  /// availableCameras() atau initialize() menggantung tanpa batas, jadi
  /// seluruh inisialisasi dibatasi waktu.
  static const _cameraTimeout = Duration(seconds: 8);

  /// Melepas controller lama lalu menginisialisasi ulang dari nol. Dipakai
  /// tombol coba-lagi pada layar galat.
  Future<void> _retryCamera() async {
    final old = _camera;
    setState(() {
      _camera = null;
      _state = _CameraState.loading;
    });
    await old?.dispose();
    await _startCamera();
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras().timeout(_cameraTimeout);
      if (cameras.isEmpty) {
        if (mounted) setState(() => _state = _CameraState.unavailable);
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize().timeout(_cameraTimeout);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _state = _CameraState.ready;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(
        () => _state = e.code == 'CameraAccessDenied'
            ? _CameraState.denied
            : _CameraState.unavailable,
      );
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _state = _CameraState.unavailable);
    }
  }

  /// Haptic berat sekali saat portal mencapai ukuran penuh
  /// (docs/03-design-system.md §3.4).
  void _onPortalTick() {
    if (_portalOpen && !_reachedFull && _portal.value >= 0.98) {
      _reachedFull = true;
      HapticFeedback.heavyImpact();
    }
  }

  void _togglePortal() {
    final opening = !_portalOpen;
    setState(() => _portalOpen = opening);
    if (opening) {
      _reachedFull = false;
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    _portal.animateWith(
      SpringSimulation(
        AppSpring.portal,
        _portal.value,
        opening ? 1.0 : 0.0,
        _portal.velocity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Layar ini selalu hitam, jadi ikon status bar harus terang apa pun tema
    // yang dipilih pengguna. Rute ini di atas _Root di Navigator, jadi ia
    // butuh anotasinya sendiri.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BackdropGroup(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _cameraLayer(),
              AnimatedBuilder(
                animation: Listenable.merge([_portal, _attitude]),
                builder: (context, _) => _PortalLayer(
                  progress: _portal.value,
                  horizon: _attitude.available
                      ? horizonY(
                          elevation: _attitude.elevation,
                          height: MediaQuery.sizeOf(context).height,
                        )
                      : null,
                ),
              ),
              if (_state == _CameraState.ready) _drawingLayer(),
              if (_state == _CameraState.ready) _orb(),
              _topBar(),
              if (_session != null) _countdown(),
              _bottomPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cameraLayer() {
    final controller = _camera;
    return switch (_state) {
      _CameraState.ready when controller != null => SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width,
            height:
                MediaQuery.sizeOf(context).width * controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
      ),
      _CameraState.loading => const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: AppNight.accent)),
      ),
      _ => _CameraProblem(
        message: _state == _CameraState.denied
            ? context.l10n.arCameraDenied
            : context.l10n.arCameraUnavailable,
        // Android menampilkan dialog izin dua kali sebelum menolak permanen,
        // jadi mencoba lagi benar-benar bisa memulihkan keadaan. Petunjuk
        // jalan ke Setelan hanya ditampilkan untuk kasus izin, bukan untuk
        // perangkat yang memang tidak punya kamera.
        hint: _state == _CameraState.denied
            ? context.l10n.arCameraDeniedHint
            : null,
        onRetry: _retryCamera,
      ),
    };
  }

  /// Lapisan gambar baru menerima sentuhan setelah portal benar-benar diam.
  /// Tanpa ini, ketukan yang membuka portal ikut tercatat sebagai node
  /// begitu lapisan muncul di bawah jari.
  bool get _canDraw =>
      _portalOpen && _portal.value >= 0.995 && !_portal.isAnimating;

  Widget _drawingLayer() {
    return AnimatedBuilder(
      animation: _portal,
      builder: (context, _) {
        if (!_canDraw) return const SizedBox.shrink();
        return ConstellationLayer(
          draft: _draft,
          onChanged: (d) => setState(() => _draft = d),
        );
      },
    );
  }

  Widget _orb() {
    return AnimatedBuilder(
      animation: Listenable.merge([_portal, _attitude]),
      builder: (context, _) {
        // Orb memudar saat portal melebar.
        final visible = (1 - _portal.value * 2).clamp(0.0, 1.0);
        if (visible == 0) return const SizedBox.shrink();
        _orbElevation ??= _attitude.available ? _attitude.elevation : null;
        return Center(
          child: Transform.translate(
            offset: Offset(0, _orbOffset(context)),
            child: Opacity(
              opacity: visible,
              child: Semantics(
                button: true,
                label: context.l10n.arOrbHint,
                child: _GlowOrb(onTap: _togglePortal),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Pergeseran tegak orb supaya ia tetap di titik langit yang sama saat
  /// ponsel dimiringkan, bukan menempel di tengah layar.
  ///
  /// Hanya sumbu tegak yang ditambatkan. Arah mata angin tidak terbaca
  /// akselerometer, jadi memutar badan tetap membawa orb ikut serta — itu
  /// batas yang hanya bisa dilewati world tracking AR sungguhan.
  double _orbOffset(BuildContext context) {
    final anchor = _orbElevation;
    if (!_attitude.available || anchor == null) return 0;
    final height = MediaQuery.sizeOf(context).height;
    final y = horizonY(elevation: _attitude.elevation - anchor, height: height);
    // Dibatasi supaya orb selalu bisa dijangkau jari; tanpa ini ia bisa
    // terbang keluar layar dan portal tidak bisa dibuka lagi.
    final limit = height * 0.34;
    return (y - height / 2).clamp(-limit, limit);
  }

  Widget _topBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Row(
          children: [
            _GlassCircleButton(
              icon: Icons.close_rounded,
              label: context.l10n.back,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: _portal,
              builder: (context, _) => AnimatedOpacity(
                opacity: _portal.value > 0.5 ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: _GlassCircleButton(
                  icon: Icons.filter_center_focus_rounded,
                  label: context.l10n.arCloseP,
                  onTap: _portalOpen ? _togglePortal : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hitung mundur sesi fokus: pil kaca di tengah atas.
  Widget _countdown() {
    final session = _session!;
    final now = DateTime.now();
    final l10n = context.l10n;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 72),
          child: GlassCard(
            radius: 100,
            grouped: true,
            tint: AppNight.scrim,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatRemaining(session.remaining(now)),
                  style: AppText.title.copyWith(
                    color: Colors.white,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Text(
                  l10n.sessionRemainingLabel,
                  style: AppText.caption.copyWith(
                    color: AppNight.onSurfaceMuted,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                _CountdownAction(
                  icon: session.isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  label: session.isPaused ? l10n.resume : l10n.pause,
                  onTap: _togglePause,
                ),
                const SizedBox(width: AppSpace.sm),
                _CountdownAction(
                  icon: Icons.stop_rounded,
                  label: l10n.giveUp,
                  onTap: _confirmGiveUp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomPanel() {
    if (_state != _CameraState.ready) return const SizedBox.shrink();
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          // Naik di atas papan ketik saat nama bentuk sedang diketik.
          padding: EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.lg,
            AppSpace.lg,
            AppSpace.lg + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: AnimatedBuilder(
            animation: _portal,
            builder: (context, _) {
              final portalOpen = _canDraw;
              if (portalOpen && !_draft.isEmpty) {
                return ConstellationDraftCard(
                  draft: _draft,
                  controller: _nameController,
                  onUndo: _undo,
                  onSave: _draft.isSaveable ? _saveConstellation : null,
                );
              }
              return GlassCard(
                radius: 100,
                grouped: true,
                tint: AppNight.scrimLight,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md,
                  vertical: 10,
                ),
                child: Text(
                  portalOpen
                      ? context.l10n.arTapToAddNode
                      : context.l10n.arOrbHint,
                  style: AppText.body.copyWith(color: Colors.white),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _undo() {
    HapticFeedback.selectionClick();
    setState(() => _draft = _draft.undo());
  }

  Future<void> _saveConstellation() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final constellations = ConstellationScope.of(context);
    final stardust = StardustScope.of(context);

    final draft = _draft;
    final name = _nameController.text.trim().isEmpty
        ? l10n.constellationNameExample
        : _nameController.text.trim();
    final reward = StardustRules.forConstellation(draft.edges.length);

    HapticFeedback.heavyImpact();
    FocusScope.of(context).unfocus();
    setState(() {
      _draft = const ConstellationDraft();
      _nameController.clear();
    });

    await constellations.add(draft, name);
    await stardust.awardConstellation(draft.edges.length);
    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppNight.surface,
        shape: const StadiumBorder(),
        margin: const EdgeInsets.all(AppSpace.md),
        content: Text(
          '${l10n.constellationSaved(name)}  ${l10n.stardustEarned(reward)}',
          style: AppText.body.copyWith(color: AppNight.onSurface),
        ),
      ),
    );
  }
}

/// Tombol kecil di dalam pil hitung mundur.
class _CountdownAction extends StatelessWidget {
  const _CountdownAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SpringTap(
        onTap: onTap,
        pressedScale: 0.86,
        child: Container(
          width: 36,
          height: 36,
          decoration: const ShapeDecoration(
            color: Color(0x33FFFFFF),
            shape: CircleBorder(),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

/// Orb bercahaya yang melayang di tengah layar kamera.
class _GlowOrb extends StatefulWidget {
  const _GlowOrb({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_GlowOrb> createState() => _GlowOrbState();
}

class _GlowOrbState extends State<_GlowOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SpringTap(
      onTap: widget.onTap,
      pressedScale: 0.9,
      haptic: HapticFeedback.mediumImpact,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_pulse.value);
          return Transform.scale(scale: 1 + t * 0.08, child: child);
        },
        child: RepaintBoundary(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Colors.white, Color(0xFF8FB8FF), Color(0xFF2F62E8)],
                stops: [0.0, 0.45, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppNight.accent.withValues(alpha: 0.65),
                  blurRadius: 48,
                  spreadRadius: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Portal bundar yang melebar dari tengah layar dan memunculkan langit malam.
class _PortalLayer extends StatelessWidget {
  const _PortalLayer({required this.progress, this.horizon});

  final double progress;

  /// Null saat perangkat tidak punya akselerometer.
  final double? horizon;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0.001) return const SizedBox.shrink();
    return IgnorePointer(
      child: ClipPath(
        clipper: _CircleClipper(progress),
        // 220 bintang + dua blur: mahal digambar, tapi isinya tidak pernah
        // berubah, jadi biarkan raster cache yang menanganinya.
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _NightSkyPainter(horizon: horizon),
            isComplex: true,
            willChange: false,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _CircleClipper extends CustomClipper<Path> {
  const _CircleClipper(this.progress);

  final double progress;

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Radius penuh menutupi sudut terjauh layar.
    final full = math.sqrt(
      math.pow(size.width / 2, 2) + math.pow(size.height / 2, 2),
    );
    return Path()..addOval(
      Rect.fromCircle(center: center, radius: 60 + (full - 60) * progress),
    );
  }

  @override
  bool shouldReclip(_CircleClipper oldClipper) =>
      oldClipper.progress != progress;
}

class _NightSkyPainter extends CustomPainter {
  const _NightSkyPainter({this.horizon});

  /// Posisi cakrawala dalam piksel dari tepi atas, atau null kalau perangkat
  /// tidak punya akselerometer. Null berarti seluruh lingkaran portal diisi
  /// langit, seperti perilaku sebelum sensor dipakai.
  final double? horizon;

  /// Langit membentang tiga kali tinggi layar ke atas dari cakrawala, supaya
  /// masih ada bintang saat ponsel diarahkan jauh ke atas.
  static const _bandFactor = 3.0;

  /// Seed tetap supaya bintang tidak melompat tiap frame.
  static final _rng = math.Random(20260313);
  static final List<_Star> _stars = List.generate(
    520,
    (_) => _Star(
      _rng.nextDouble(),
      _rng.nextDouble(),
      0.4 + _rng.nextDouble() * 1.6,
      0.3 + _rng.nextDouble() * 0.7,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    // Tanpa sensor, cakrawala dianggap di luar bingkai bawah: semua langit.
    final line = (horizon ?? h * 2).clamp(0.0, h * 2);
    // Kamera menghadap tanah: tidak ada langit sama sekali.
    if (line <= 0) {
      return;
    }

    final band = h * _bandFactor;
    final skyTop = line - band;

    // Seluruh langit digambar ke dalam satu lapisan, lalu tepi bawahnya
    // dihapus dengan gradien supaya pertemuan dengan gedung tidak berupa
    // garis lurus yang keras.
    final layer = Rect.fromLTRB(0, 0, size.width, math.min(line, h));
    canvas.saveLayer(layer, Paint());
    canvas.save();
    canvas.clipRect(layer);

    canvas.drawRect(
      Rect.fromLTRB(0, skyTop, size.width, line),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF040A1F), Color(0xFF0A192F), Color(0xFF13234A)],
        ).createShader(Rect.fromLTRB(0, skyTop, size.width, line)),
    );

    // Pita Bima Sakti melintang, ikut tertambat ke langit.
    canvas.save();
    canvas.translate(size.width / 2, skyTop + band * 0.58);
    canvas.rotate(-0.5);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: size.width * 2, height: 200),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00FFFFFF), Color(0x33A9C7FF), Color(0x00FFFFFF)],
            ).createShader(
              Rect.fromCenter(
                center: Offset.zero,
                width: size.width * 2,
                height: 200,
              ),
            )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
    canvas.restore();

    for (final s in _stars) {
      canvas.drawCircle(
        Offset(s.x * size.width, skyTop + s.y * band),
        s.radius,
        Paint()..color = Colors.white.withValues(alpha: s.opacity),
      );
    }

    // shortcut: tiga planet pada posisi tetap. Ganti dengan ephemeris asli
    // setelah docs/06-open-questions.md #6 diputuskan.
    const planets = [
      (0.22, 0.28, 7.0, Color(0xFFE8C07D)),
      (0.74, 0.20, 5.0, Color(0xFFE8897D)),
      (0.58, 0.63, 6.0, Color(0xFFBFD4FF)),
    ];
    for (final (x, y, r, color) in planets) {
      final c = Offset(x * size.width, skyTop + y * band);
      canvas.drawCircle(
        c,
        r * 3,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawCircle(c, r, Paint()..color = color);
    }

    canvas.restore(); // clipRect

    // Pudarkan 90 piksel terakhir tepat di atas cakrawala, supaya langit
    // menyatu dengan gedung alih-alih terpotong garis lurus.
    if (line < h) {
      final fade = Rect.fromLTRB(0, math.max(0, line - 90), size.width, line);
      canvas.drawRect(
        fade,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0xFF000000)],
          ).createShader(fade),
      );
    }
    canvas.restore(); // saveLayer
  }

  @override
  bool shouldRepaint(_NightSkyPainter oldDelegate) =>
      oldDelegate.horizon != horizon;
}

class _Star {
  const _Star(this.x, this.y, this.radius, this.opacity);

  final double x;
  final double y;
  final double radius;
  final double opacity;
}

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SpringTap(
        onTap: onTap,
        pressedScale: 0.88,
        child: GlassCard(
          radius: 100,
          grouped: true,
          tint: const Color(0x55000000),
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _CameraProblem extends StatelessWidget {
  const _CameraProblem({required this.message, this.hint, this.onRetry});

  final String message;

  /// Petunjuk tambahan untuk kasus izin ditolak permanen.
  final String? hint;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppNight.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_photography_rounded,
                size: 48,
                color: AppNight.onSurfaceMuted,
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: AppNight.onSurface),
              ),
              if (hint != null) ...[
                const SizedBox(height: AppSpace.sm),
                Text(
                  hint!,
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(
                    color: AppNight.onSurfaceMuted,
                  ),
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: AppSpace.lg),
                PillButton(
                  label: context.l10n.arCameraRetry,
                  color: AppNight.accent,
                  labelColor: AppNight.onAccent,
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
