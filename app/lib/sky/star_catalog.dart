import 'package:flutter/services.dart' show rootBundle;

import 'sky_math.dart';

/// Satu bintang dari katalog yang dibundel.
class Star {
  const Star({
    required this.raHours,
    required this.decDeg,
    required this.magnitude,
    required this.proper,
    required this.bayer,
    required this.constellation,
    required this.spectral,
    required this.lightYears,
  });

  /// Asensio rekta J2000, dalam jam.
  final double raHours;

  /// Deklinasi J2000, dalam derajat.
  final double decDeg;

  /// Magnitudo tampak. Makin kecil makin terang; Sirius -1,44.
  final double magnitude;

  /// Nama diri, misalnya "Sirius". Kosong untuk sebagian besar bintang.
  final String proper;

  /// Huruf Yunani Bayer, misalnya "α". Kosong kalau tidak punya.
  final String bayer;

  /// Singkatan rasi tiga huruf, misalnya "CMa".
  final String constellation;

  /// Tipe spektral, misalnya "A0m...".
  final String spectral;

  /// Jarak dalam tahun cahaya. Nol berarti tidak diketahui.
  final double lightYears;

  /// Nama yang ditampilkan: nama diri kalau ada, kalau tidak sebutan Bayer.
  String get displayName {
    if (proper.isNotEmpty) return proper;
    if (bayer.isNotEmpty) return '$bayer $constellation';
    return constellation;
  }

  /// Nama rasi lengkap dalam bahasa Latin, atau singkatannya kalau tidak
  /// dikenali.
  String get constellationName =>
      constellationNames[constellation] ?? constellation;

  bool get hasDistance => lightYears > 0;
}

/// Sebuah bintang beserta arahnya di langit pada saat tertentu.
typedef SightedStar = ({Star star, SkyPoint point});

/// Katalog bintang yang dibundel bersama aplikasi.
///
/// Sengaja tidak diambil dari jaringan: identifikasi bintang dipakai di atap
/// pada malam hari, tempat sinyal sering buruk, dan jawabannya harus muncul
/// seketika saat ponsel diarahkan.
class StarCatalog {
  const StarCatalog(this.stars);

  final List<Star> stars;

  static const assetPath = 'assets/stars.csv';

  /// Memuat dan mengurai katalog. Baris yang rusak dilewati, bukan membuat
  /// seluruh pemuatan gagal.
  static Future<StarCatalog> load() async {
    final raw = await rootBundle.loadString(assetPath);
    return StarCatalog(parse(raw));
  }

  static List<Star> parse(String csv) {
    final out = <Star>[];
    final lines = csv.split('\n');
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final f = line.split(',');
      if (f.length < 8) continue;
      final ra = double.tryParse(f[0]);
      final dec = double.tryParse(f[1]);
      final mag = double.tryParse(f[2]);
      if (ra == null || dec == null || mag == null) continue;
      out.add(
        Star(
          raHours: ra,
          decDeg: dec,
          magnitude: mag,
          proper: f[3],
          bayer: f[4],
          constellation: f[5],
          spectral: f[6],
          lightYears: double.tryParse(f[7]) ?? 0,
        ),
      );
    }
    return out;
  }

  /// Menghitung arah setiap bintang yang sedang berada di atas ufuk.
  ///
  /// Hasilnya dipakai berulang kali untuk banyak pembacaan sensor: langit
  /// hanya bergeser seperempat derajat per menit, jadi menghitung ulang tiap
  /// frame hanya membuang tenaga.
  List<SightedStar> snapshot({
    required double latitudeDeg,
    required double longitudeDeg,
    required DateTime utc,
  }) {
    final out = <SightedStar>[];
    for (final s in stars) {
      final p = horizontalFromEquatorial(
        raHours: s.raHours,
        decDeg: s.decDeg,
        latitudeDeg: latitudeDeg,
        longitudeDeg: longitudeDeg,
        utc: utc,
      );
      // Sedikit di bawah ufuk tetap disimpan supaya bintang yang baru terbit
      // tidak berkedip hilang-muncul di tepi layar.
      if (p.altitude > -3) out.add((star: s, point: p));
    }
    return out;
  }
}

/// Mencari bintang yang paling masuk akal sedang dibidik.
///
/// Bukan sekadar yang terdekat: di antara beberapa bintang yang berdekatan,
/// yang lebih terang lebih mungkin jadi maksud pengguna, karena bintang redup
/// sering tidak terlihat sama sekali dari kota. [brightnessWeight] mengatur
/// seberapa besar keterangan boleh mengalahkan kedekatan.
SightedStar? nearestStar(
  List<SightedStar> sky,
  SkyPoint look, {
  double maxSeparationDeg = 9,
  double brightnessWeight = 0.55,
}) {
  SightedStar? best;
  var bestScore = double.infinity;
  for (final s in sky) {
    // Selisih ketinggian adalah batas bawah jarak sudut, dan menghitungnya
    // tidak perlu trigonometri sama sekali. Ini membuang sebagian besar
    // katalog sebelum hitungan penuh dijalankan.
    if ((s.point.altitude - look.altitude).abs() > maxSeparationDeg) continue;
    final sep = angularSeparation(look, s.point);
    if (sep > maxSeparationDeg) continue;
    final score = sep + s.star.magnitude * brightnessWeight;
    if (score < bestScore) {
      bestScore = score;
      best = s;
    }
  }
  return best;
}

/// Singkatan rasi tiga huruf ke nama Latinnya. Nama rasi adalah nama diri,
/// jadi tidak diterjemahkan.
const constellationNames = <String, String>{
  'And': 'Andromeda',
  'Ant': 'Antlia',
  'Aps': 'Apus',
  'Aqr': 'Aquarius',
  'Aql': 'Aquila',
  'Ara': 'Ara',
  'Ari': 'Aries',
  'Aur': 'Auriga',
  'Boo': 'Boötes',
  'Cae': 'Caelum',
  'Cam': 'Camelopardalis',
  'Cnc': 'Cancer',
  'CVn': 'Canes Venatici',
  'CMa': 'Canis Major',
  'CMi': 'Canis Minor',
  'Cap': 'Capricornus',
  'Car': 'Carina',
  'Cas': 'Cassiopeia',
  'Cen': 'Centaurus',
  'Cep': 'Cepheus',
  'Cet': 'Cetus',
  'Cha': 'Chamaeleon',
  'Cir': 'Circinus',
  'Col': 'Columba',
  'Com': 'Coma Berenices',
  'CrA': 'Corona Australis',
  'CrB': 'Corona Borealis',
  'Crv': 'Corvus',
  'Crt': 'Crater',
  'Cru': 'Crux',
  'Cyg': 'Cygnus',
  'Del': 'Delphinus',
  'Dor': 'Dorado',
  'Dra': 'Draco',
  'Equ': 'Equuleus',
  'Eri': 'Eridanus',
  'For': 'Fornax',
  'Gem': 'Gemini',
  'Gru': 'Grus',
  'Her': 'Hercules',
  'Hor': 'Horologium',
  'Hya': 'Hydra',
  'Hyi': 'Hydrus',
  'Ind': 'Indus',
  'Lac': 'Lacerta',
  'Leo': 'Leo',
  'LMi': 'Leo Minor',
  'Lep': 'Lepus',
  'Lib': 'Libra',
  'Lup': 'Lupus',
  'Lyn': 'Lynx',
  'Lyr': 'Lyra',
  'Men': 'Mensa',
  'Mic': 'Microscopium',
  'Mon': 'Monoceros',
  'Mus': 'Musca',
  'Nor': 'Norma',
  'Oct': 'Octans',
  'Oph': 'Ophiuchus',
  'Ori': 'Orion',
  'Pav': 'Pavo',
  'Peg': 'Pegasus',
  'Per': 'Perseus',
  'Phe': 'Phoenix',
  'Pic': 'Pictor',
  'Psc': 'Pisces',
  'PsA': 'Piscis Austrinus',
  'Pup': 'Puppis',
  'Pyx': 'Pyxis',
  'Ret': 'Reticulum',
  'Sge': 'Sagitta',
  'Sgr': 'Sagittarius',
  'Sco': 'Scorpius',
  'Scl': 'Sculptor',
  'Sct': 'Scutum',
  'Ser': 'Serpens',
  'Sex': 'Sextans',
  'Tau': 'Taurus',
  'Tel': 'Telescopium',
  'Tri': 'Triangulum',
  'TrA': 'Triangulum Australe',
  'Tuc': 'Tucana',
  'UMa': 'Ursa Major',
  'UMi': 'Ursa Minor',
  'Vel': 'Vela',
  'Vir': 'Virgo',
  'Vol': 'Volans',
  'Vul': 'Vulpecula',
};
