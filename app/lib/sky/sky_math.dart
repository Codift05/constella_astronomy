import 'dart:math' as math;

/// Arah sebuah titik di langit dilihat dari permukaan bumi.
typedef SkyPoint = ({double altitude, double azimuth});

const _degPerRad = 180 / math.pi;
double _rad(double deg) => deg / _degPerRad;
double _deg(double rad) => rad * _degPerRad;

double normalize360(double deg) {
  final v = deg % 360;
  return v < 0 ? v + 360 : v;
}

double _norm180(double deg) {
  final v = normalize360(deg);
  return v > 180 ? v - 360 : v;
}

/// Hari Julian dari waktu UTC.
///
/// Memakai algoritma kalender Gregorian baku; berlaku jauh melampaui rentang
/// pakai aplikasi ini. Titik rujukannya: 1 Januari 2000 pukul 12:00 UTC
/// bernilai tepat 2451545.0.
double julianDay(DateTime utc) {
  final t = utc.toUtc();
  final a = (14 - t.month) ~/ 12;
  final y = t.year + 4800 - a;
  final m = t.month + 12 * a - 3;
  final jdn =
      t.day +
      (153 * m + 2) ~/ 5 +
      365 * y +
      y ~/ 4 -
      y ~/ 100 +
      y ~/ 400 -
      32045;
  final fraction =
      (t.hour - 12) / 24 +
      t.minute / 1440 +
      (t.second + t.millisecond / 1000) / 86400;
  return jdn + fraction;
}

/// Waktu sideris rata-rata Greenwich, dalam derajat.
///
/// Inilah yang membuat langit berputar: nilainya bertambah sekitar 360,9856
/// derajat per hari, bukan 360 — selisih itulah sebabnya bintang terbit
/// hampir empat menit lebih awal setiap malam.
double greenwichSiderealDegrees(DateTime utc) {
  final d = julianDay(utc) - 2451545.0;
  return normalize360(280.46061837 + 360.98564736629 * d);
}

/// Waktu sideris lokal dalam derajat, untuk bujur [longitudeDeg] (timur positif).
double localSiderealDegrees(DateTime utc, double longitudeDeg) =>
    normalize360(greenwichSiderealDegrees(utc) + longitudeDeg);

/// Mengubah koordinat ekuatorial sebuah bintang menjadi arah pandang dari
/// sebuah titik di bumi pada sebuah saat.
///
/// [raHours] asensio rekta dalam jam (0..24), [decDeg] deklinasi dalam derajat.
/// Azimut dihitung dari utara ke arah timur, jadi 90 berarti timur.
///
/// Presesi diabaikan: katalognya berpatokan J2000 dan pergeserannya sekitar
/// 0,4 derajat untuk 2026. Itu jauh di bawah ketelitian kompas ponsel, jadi
/// mengoreksinya tidak akan terasa.
SkyPoint horizontalFromEquatorial({
  required double raHours,
  required double decDeg,
  required double latitudeDeg,
  required double longitudeDeg,
  required DateTime utc,
}) {
  final lst = localSiderealDegrees(utc, longitudeDeg);
  final ha = _rad(_norm180(lst - raHours * 15));
  final dec = _rad(decDeg);
  final lat = _rad(latitudeDeg);

  final sinAlt =
      math.sin(dec) * math.sin(lat) +
      math.cos(dec) * math.cos(lat) * math.cos(ha);
  final altitude = math.asin(sinAlt.clamp(-1.0, 1.0));

  // Bentuk atan2 dipakai, bukan acos: ia tidak meledak di kutub langit dan
  // tidak butuh pemeriksaan kuadran terpisah.
  final azimuth = math.atan2(
    -math.sin(ha) * math.cos(dec),
    math.cos(lat) * math.sin(dec) -
        math.sin(lat) * math.cos(dec) * math.cos(ha),
  );

  return (altitude: _deg(altitude), azimuth: normalize360(_deg(azimuth)));
}

/// Jarak sudut antara dua arah langit, dalam derajat.
double angularSeparation(SkyPoint a, SkyPoint b) {
  final a1 = _rad(a.altitude);
  final a2 = _rad(b.altitude);
  final dAz = _rad(a.azimuth - b.azimuth);
  final cosSep =
      math.sin(a1) * math.sin(a2) + math.cos(a1) * math.cos(a2) * math.cos(dAz);
  return _deg(math.acos(cosSep.clamp(-1.0, 1.0)));
}

/// Arah bidikan kamera belakang, dari satu pembacaan akselerometer dan
/// magnetometer.
///
/// Akselerometer memberi arah atas, magnetometer memberi arah utara. Hasil
/// kali silang keduanya menghasilkan kerangka timur-utara-atas, lalu arah
/// pandang kamera (sumbu -z perangkat) diproyeksikan ke kerangka itu.
///
/// **Utaranya utara magnetik, bukan utara sejati.** Selisih keduanya
/// (deklinasi magnetik) bergantung tempat: di Indonesia sekitar 1 derajat,
/// tapi di sebagian Amerika Utara bisa belasan derajat. Mengoreksinya butuh
/// model medan magnet bumi, dan itu belum dibangun.
///
/// Mengembalikan null kalau pembacaannya tidak bisa dipercaya: perangkat
/// jatuh bebas, atau medan magnetnya sejajar gravitasi sehingga arah timur
/// tidak terdefinisi.
SkyPoint? lookDirection({
  required double ax,
  required double ay,
  required double az,
  required double mx,
  required double my,
  required double mz,
}) {
  final aLen = math.sqrt(ax * ax + ay * ay + az * az);
  if (aLen < 1.0) return null; // jatuh bebas: arah atas tidak terdefinisi
  final ux = ax / aLen, uy = ay / aLen, uz = az / aLen;

  // timur = medan magnet x atas
  var ex = my * uz - mz * uy;
  var ey = mz * ux - mx * uz;
  var ez = mx * uy - my * ux;
  final eLen = math.sqrt(ex * ex + ey * ey + ez * ez);
  if (eLen < 1e-6) return null; // magnet sejajar gravitasi
  ex /= eLen;
  ey /= eLen;
  ez /= eLen;

  // Kamera belakang memandang ke arah -z perangkat, jadi proyeksinya ke tiap
  // sumbu dunia cukup memakai komponen z masing-masing vektor. Komponen x dan
  // y dari vektor utara tidak pernah terpakai, jadi tidak dihitung.
  final nz = ux * ey - uy * ex; // utara = atas x timur, komponen z saja
  final upComponent = -uz;
  final eastComponent = -ez;
  final northComponent = -nz;

  return (
    altitude: _deg(math.asin(upComponent.clamp(-1.0, 1.0))),
    azimuth: normalize360(_deg(math.atan2(eastComponent, northComponent))),
  );
}
