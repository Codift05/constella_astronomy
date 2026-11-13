import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Pelaporan waktu frame, dimatikan secara bawaan.
/// Nyalakan dengan: flutter run --profile --dart-define=FRAME_REPORT=true
const kFrameReport = bool.fromEnvironment('FRAME_REPORT');

/// Mengumpulkan waktu build dan raster, lalu mencetak ringkasannya tiap
/// [window] frame. Build = kerja Dart. Raster = kerja GPU.
void startFrameReport({int window = 120}) {
  if (!kFrameReport) return;
  // addTimingsCallback butuh binding yang sudah hidup.
  WidgetsFlutterBinding.ensureInitialized();

  final build = <int>[];
  final raster = <int>[];

  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final t in timings) {
      build.add(t.buildDuration.inMicroseconds);
      raster.add(t.rasterDuration.inMicroseconds);
    }
    if (build.length < window) return;

    String p(List<int> xs, double q) {
      final sorted = [...xs]..sort();
      final i = ((sorted.length - 1) * q).round();
      return (sorted[i] / 1000).toStringAsFixed(1);
    }

    debugPrint(
      'FrameReport frames=${build.length} '
      'build p50=${p(build, 0.5)}ms p90=${p(build, 0.9)}ms p99=${p(build, 0.99)}ms | '
      'raster p50=${p(raster, 0.5)}ms p90=${p(raster, 0.9)}ms p99=${p(raster, 0.99)}ms',
    );
    build.clear();
    raster.clear();
  });
}
