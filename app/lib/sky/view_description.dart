import 'sky_math.dart';
import 'star_catalog.dart';

/// Apa yang sedang dihadapi kamera, disusun dari data nyata.
///
/// Tidak ada yang dikarang di sini: arah datang dari kompas, ketinggian dari
/// akselerometer, dan bintangnya dari katalog yang posisinya dihitung untuk
/// tempat dan waktu pengamat.
class ViewDescription {
  const ViewDescription({
    required this.azimuth,
    required this.altitude,
    required this.compassPoint,
    this.brightest,
  });

  final double azimuth;
  final double altitude;

  /// Singkatan arah mata angin, misalnya "NE".
  final String compassPoint;

  /// Bintang paling terang yang berada di dalam bidang pandang, kalau ada.
  final Star? brightest;

  /// Nama rasi yang sedang dihadapi, dari bintang paling terang di bingkai.
  /// Null kalau tidak ada bintang yang cukup terang di sana.
  String? get constellation => brightest?.constellationName;

  bool get aboveHorizon => altitude >= 0;
}

const _points = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];

/// Singkatan arah mata angin untuk sebuah azimut.
String compassPointFor(double azimuth) =>
    _points[(((azimuth % 360) + 360) % 360 + 22.5) ~/ 45 % 8];

/// Menyusun keterangan arah pandang sekarang.
///
/// [fovDeg] adalah lebar bidang pandang yang dianggap "di dalam bingkai".
/// Bintang di luar itu diabaikan, sehingga keterangan tidak menyebut rasi yang
/// sebenarnya tidak terlihat di foto.
ViewDescription describeView({
  required SkyPoint look,
  required List<SightedStar> sky,
  double fovDeg = 45,
}) {
  Star? brightest;
  var bestMagnitude = double.infinity;

  for (final s in sky) {
    if (s.point.altitude < 0) continue;
    if (angularSeparation(look, s.point) > fovDeg / 2) continue;
    if (s.star.magnitude < bestMagnitude) {
      bestMagnitude = s.star.magnitude;
      brightest = s.star;
    }
  }

  return ViewDescription(
    azimuth: normalize360(look.azimuth),
    altitude: look.altitude,
    compassPoint: compassPointFor(look.azimuth),
    brightest: brightest,
  );
}
