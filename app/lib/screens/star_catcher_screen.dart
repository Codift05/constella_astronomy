import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n_ext.dart';
import '../sky/observer_location.dart';
import '../sky/sky_math.dart';
import '../sky/sky_orientation.dart';
import '../sky/star_catalog.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import '../widgets/soft_ui.dart';

enum _Camera { loading, ready, denied, unavailable }

/// Penangkap bintang: arahkan kamera, bidikan di tengah mengunci bintang
/// terdekat, lalu datanya muncul.
///
/// Katalognya dibundel, jadi seluruh layar ini bekerja tanpa jaringan.
class StarCatcherScreen extends StatefulWidget {
  const StarCatcherScreen({
    super.key,
    this.orientation,
    this.location,
    this.catalog,
    this.enableCamera = true,
  });

  /// Semua disuntikkan hanya oleh tes; di aplikasi nyata dibuat sendiri.
  final SkyOrientation? orientation;
  final ObserverLocation? location;
  final StarCatalog? catalog;

  /// Kamera tidak bisa diinisialisasi di lingkungan tes widget.
  final bool enableCamera;

  @override
  State<StarCatcherScreen> createState() => _StarCatcherScreenState();
}

class _StarCatcherScreenState extends State<StarCatcherScreen> {
  static const _cameraTimeout = Duration(seconds: 8);

  /// Langit bergeser seperempat derajat per menit, jadi menghitung ulang
  /// posisi seluruh katalog tiap frame hanya membuang tenaga.
  static const _skyRefresh = Duration(seconds: 20);

  late final SkyOrientation _orientation =
      widget.orientation ?? SkyOrientation();
  late final ObserverLocation _location = widget.location ?? ObserverLocation();

  CameraController? _camera;
  _Camera _cameraState = _Camera.loading;

  StarCatalog? _catalog;
  List<SightedStar> _sky = const [];
  Timer? _skyTimer;

  SightedStar? _target;
  double _separation = 0;

  @override
  void initState() {
    super.initState();
    _orientation
      ..addListener(_onOrientation)
      ..start();
    _location.addListener(_onLocation);
    if (widget.catalog != null) {
      _catalog = widget.catalog;
    } else {
      _loadCatalog();
    }
    if (widget.enableCamera) {
      _startCamera();
    } else {
      _cameraState = _Camera.ready;
    }
    if (!_location.hasFix) unawaited(_location.resolve());
    _rebuildSky();
    _skyTimer = Timer.periodic(_skyRefresh, (_) => _rebuildSky());
  }

  @override
  void dispose() {
    _skyTimer?.cancel();
    _orientation
      ..removeListener(_onOrientation)
      ..dispose();
    _location
      ..removeListener(_onLocation)
      ..dispose();
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    final c = await StarCatalog.load();
    if (!mounted) return;
    setState(() => _catalog = c);
    _rebuildSky();
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras().timeout(_cameraTimeout);
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraState = _Camera.unavailable);
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
        _cameraState = _Camera.ready;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(
        () => _cameraState = e.code == 'CameraAccessDenied'
            ? _Camera.denied
            : _Camera.unavailable,
      );
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _cameraState = _Camera.unavailable);
    }
  }

  void _onLocation() {
    if (_location.hasFix) _rebuildSky();
    if (mounted) setState(() {});
  }

  /// Menghitung ulang posisi seluruh katalog untuk posisi dan waktu sekarang.
  void _rebuildSky() {
    final catalog = _catalog;
    final lat = _location.latitude;
    final lon = _location.longitude;
    if (catalog == null || lat == null || lon == null) return;
    final now = DateTime.now().toUtc();
    final sky = catalog.snapshot(latitudeDeg: lat, longitudeDeg: lon, utc: now);
    if (!mounted) return;
    setState(() => _sky = sky);
    _match();
  }

  void _onOrientation() => _match();

  /// Mencocokkan arah bidikan sekarang dengan bintang terdekat.
  ///
  /// Selalu membangun ulang saat arah berubah, bukan hanya saat bintangnya
  /// berganti: pembacaan kompas di atas layar ikut arah bidik, dan kalau
  /// langitnya sedang kosong ia akan membeku di angka lama.
  /// Pembangunan ulangnya sudah dijaga ambang sudut di [SkyOrientation].
  void _match() {
    if (!mounted) return;
    final look = _orientation.direction;
    final hit = look == null || _sky.isEmpty ? null : nearestStar(_sky, look);
    if (hit != null && hit.star.displayName != _target?.star.displayName) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _target = hit;
      _separation = hit == null || look == null
          ? 0
          : angularSeparation(look, hit.point);
    });
  }

  bool get _ready =>
      _catalog != null && _location.hasFix && _orientation.available;

  @override
  Widget build(BuildContext context) {
    // Layar ini selalu gelap karena isinya umpan kamera malam hari.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBody: true,
        // Tiga kaca di layar ini berbagi satu lintasan backdrop. Tanpa ini
        // setiap kaca memicu saveLayer sendiri di atas umpan kamera yang
        // bergerak terus, tiga kali per frame.
        body: BackdropGroup(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _cameraLayer(),
              const _BottomScrim(),
              if (_ready) _Crosshair(locked: _target != null),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.md),
                  child: _topBar(),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.md,
                      0,
                      AppSpace.md,
                      kTabBarInset,
                    ),
                    child: _panel(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cameraLayer() {
    final controller = _camera;
    if (_cameraState == _Camera.ready && controller != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width,
            height:
                MediaQuery.sizeOf(context).width * controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
      );
    }
    return const ColoredBox(color: Colors.black);
  }

  /// Pembacaan kompas kecil di atas: berguna sekaligus jadi bukti bahwa
  /// sensornya memang hidup.
  Widget _topBar() {
    final look = _orientation.direction;
    if (look == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.topCenter,
      child: GlassCard(
        tint: AppNight.scrim,
        grouped: true,
        radius: 999,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          '${_compassPoint(look.azimuth)}  ${look.azimuth.round()}°   '
          '${look.altitude.round()}°',
          style: AppText.caption.copyWith(color: AppNight.onSurface),
        ),
      ),
    );
  }

  static String _compassPoint(double azimuth) {
    const names = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return names[(((azimuth % 360) + 22.5) ~/ 45) % 8];
  }

  Widget _panel() {
    final l10n = context.l10n;

    if (_orientation.unsupported) {
      return _Message(
        icon: Icons.explore_off_rounded,
        title: l10n.starNoCompass,
        body: l10n.starNoCompassBody,
      );
    }
    if (_cameraState == _Camera.denied || _cameraState == _Camera.unavailable) {
      return _Message(
        icon: Icons.no_photography_rounded,
        title: _cameraState == _Camera.denied
            ? l10n.arCameraDenied
            : l10n.arCameraUnavailable,
        body: _cameraState == _Camera.denied ? l10n.arCameraDeniedHint : null,
        action: l10n.arCameraRetry,
        onAction: _startCamera,
      );
    }
    if (!_location.hasFix) return _locationPanel();
    if (_catalog == null || _orientation.direction == null) {
      return _Message(
        icon: Icons.hourglass_empty_rounded,
        title: l10n.starSearching,
      );
    }

    final hit = _target;
    return AnimatedSwitcher(
      duration: context.calm(const Duration(milliseconds: 320)),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: hit == null
          ? _Message(
              key: const ValueKey('kosong'),
              icon: Icons.filter_center_focus_rounded,
              title: l10n.starNothingHere,
              // Keadaan kosong inilah yang pertama dilihat pengguna, jadi di
              // sinilah layar menjelaskan dirinya sendiri.
              body: '${l10n.starCatcherPurpose}\n\n${l10n.starNothingHereBody}',
            )
          : _StarCard(
              key: ValueKey(hit.star.displayName),
              sighted: hit,
              separationDeg: _separation,
            ),
    );
  }

  Widget _locationPanel() {
    final l10n = context.l10n;
    final (body, action, onAction) = switch (_location.state) {
      LocationState.deniedForever => (
        l10n.starLocationDenied,
        l10n.starOpenSettings,
        _location.openSettings,
      ),
      LocationState.serviceOff => (
        l10n.starLocationServiceOff,
        l10n.arCameraRetry,
        _location.resolve,
      ),
      LocationState.denied || LocationState.unavailable => (
        l10n.starLocationDenied,
        l10n.starAllowLocation,
        _location.resolve,
      ),
      LocationState.resolving => (l10n.starSearching, null, null),
      _ => (
        l10n.starNeedsLocationBody,
        l10n.starAllowLocation,
        _location.resolve,
      ),
    };
    return _Message(
      icon: Icons.my_location_rounded,
      title: l10n.starNeedsLocationTitle,
      body: body,
      action: action,
      onAction: onAction,
    );
  }
}

/// Gelap bertingkat di bawah, supaya teks kartu tetap terbaca di atas umpan
/// kamera apa pun isinya.
class _BottomScrim extends StatelessWidget {
  const _BottomScrim();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.center,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0xCC000000)],
          ),
        ),
      ),
    );
  }
}

class _Crosshair extends StatelessWidget {
  const _Crosshair({required this.locked});

  final bool locked;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: locked ? 1 : 0),
          duration: context.calm(const Duration(milliseconds: 260)),
          curve: Curves.easeOutBack,
          builder: (context, t, _) => Transform.scale(
            scale: 1 - 0.12 * t,
            child: CustomPaint(
              size: const Size.square(96),
              painter: _CrosshairPainter(t),
            ),
          ),
        ),
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  const _CrosshairPainter(this.locked);

  /// 0 saat mencari, 1 saat terkunci ke bintang.
  final double locked;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final color = Color.lerp(AppNight.onSurfaceMuted, AppNight.accent, locked)!;
    final ring = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 + locked;
    canvas.drawCircle(c, size.width * 0.34, ring);

    // Empat siku di sudut, memendek saat terkunci.
    final arm = size.width * (0.12 - 0.05 * locked);
    final tick = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final d in [
      const Offset(0, -1),
      const Offset(0, 1),
      const Offset(-1, 0),
      const Offset(1, 0),
    ]) {
      final from = c + d * (size.width * 0.34 + 6);
      canvas.drawLine(from, from + d * arm, tick);
    }
    if (locked > 0) {
      canvas.drawCircle(c, 3 * locked, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_CrosshairPainter old) => old.locked != locked;
}

/// Kartu data bintang yang sedang dibidik.
class _StarCard extends StatelessWidget {
  const _StarCard({
    super.key,
    required this.sighted,
    required this.separationDeg,
  });

  final SightedStar sighted;
  final double separationDeg;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = sighted.star;
    final alt = sighted.point.altitude;
    return GlassCard(
      tint: AppNight.scrim,
      grouped: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  s.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title2.copyWith(color: AppNight.onSurface),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                l10n.starOffBy(separationDeg.toStringAsFixed(1)),
                style: AppText.caption.copyWith(color: AppNight.onSurfaceMuted),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            s.constellationName,
            style: AppText.subhead.copyWith(color: AppNight.accent),
          ),
          const SizedBox(height: AppSpace.md),
          _row(
            context,
            l10n.starDistance,
            s.hasDistance
                ? l10n.starLightYears(_formatLy(s.lightYears))
                : l10n.starDistanceUnknown,
          ),
          _row(context, l10n.starMagnitude, s.magnitude.toStringAsFixed(2)),
          if (s.spectral.isNotEmpty)
            _row(context, l10n.starSpectralType, s.spectral),
          _row(
            context,
            l10n.starAltitude,
            alt >= 0
                ? '${alt.round()}°'
                : '${alt.round()}° · ${l10n.starBelowHorizon}',
          ),
        ],
      ),
    );
  }

  static String _formatLy(double ly) =>
      ly >= 100 ? ly.round().toString() : ly.toStringAsFixed(1);

  Widget _row(BuildContext context, String label, String value) {
    final labelStyle = AppText.caption.copyWith(color: AppNight.onSurfaceMuted);
    final valueStyle = AppText.caption.copyWith(color: AppNight.onSurface);

    // Kolom label berlebar tetap patah pada Dynamic Type besar, dan label
    // Indonesia lebih panjang dari Inggris ("Tipe spektral" lawan "Spectral
    // type"). Di atas ambang ini label pindah ke atas nilainya.
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    if (stacked) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: labelStyle),
            Text(value, style: valueStyle),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lebarnya mengikuti label terpanjang, bukan angka yang dipatok.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: IntrinsicWidth(child: Text(label, style: labelStyle)),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: Text(value, style: valueStyle)),
        ],
      ),
    );
  }
}

/// Panel penjelasan untuk keadaan selain "sedang membidik".
class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? action;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tint: AppNight.scrim,
      grouped: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppNight.accent),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppText.subhead.copyWith(
                    color: AppNight.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (body != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              body!,
              style: AppText.caption.copyWith(color: AppNight.onSurfaceMuted),
            ),
          ],
          if (action != null && onAction != null) ...[
            const SizedBox(height: AppSpace.md),
            PillButton(
              label: action!,
              color: AppNight.accent,
              labelColor: AppNight.onAccent,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
