import 'package:constella_app/sky/sky_math.dart';
import 'package:constella_app/sky/star_catalog.dart';
import 'package:constella_app/widgets/real_sky_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ponsel tegak, kamera belakang menghadap utara mendatar.
final frameUtara = lookFrame(ax: 0, ay: 9.81, az: 0, mx: 0, my: 0, mz: -25)!;

const sirius = Star(
  raHours: 6.75,
  decDeg: -16.7,
  magnitude: -1.44,
  proper: 'Sirius',
  bayer: 'α',
  constellation: 'CMa',
  spectral: 'A0m',
  lightYears: 8.6,
);

/// Bintang di arah [azimuth] dan ketinggian [altitude], tanpa perlu menghitung
/// posisi sebenarnya: lapisan ini menerima arah yang sudah jadi.
SightedStar di(double altitude, double azimuth, {Star star = sirius}) =>
    (star: star, point: (altitude: altitude, azimuth: azimuth));

Future<void> pump(
  WidgetTester tester, {
  required SkyFrame? frame,
  required List<SightedStar> sky,
  double reveal = 1,
}) async {
  // Ukuran ponsel sungguhan, dan tanpa kotak berukuran tetap di sekelilingnya:
  // lapisan ini harus bebas menyusut jadi nol saat tidak ada yang digambar.
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: RealSkyLayer(sky: sky, frame: frame, reveal: reveal),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('tanpa kompas tidak menggambar apa pun', (tester) async {
    await pump(tester, frame: null, sky: [di(30, 0)]);

    // Menebak arah lebih buruk daripada diam: tanpa kerangka, lapisannya
    // menyusut jadi nol alih-alih menaruh bintang di tempat karangan.
    expect(tester.getSize(find.byType(RealSkyLayer)), Size.zero);
    expect(tester.takeException(), isNull);
  });

  testWidgets('portal tertutup tidak menggambar apa pun', (tester) async {
    await pump(tester, frame: frameUtara, sky: [di(30, 0)], reveal: 0);

    expect(tester.getSize(find.byType(RealSkyLayer)), Size.zero);
  });

  testWidgets('langit penuh bintang digambar tanpa galat', (tester) async {
    await pump(
      tester,
      frame: frameUtara,
      sky: [
        for (var alt = -10.0; alt < 90; alt += 5)
          for (var az = 0.0; az < 360; az += 10) di(alt, az),
      ],
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('langit kosong tetap menggambar selubung malam', (tester) async {
    await pump(tester, frame: frameUtara, sky: const []);

    expect(tester.getSize(find.byType(RealSkyLayer)), const Size(390, 844));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bintang di belakang punggung tidak menggagalkan apa pun', (
    tester,
  ) async {
    await pump(tester, frame: frameUtara, sky: [di(10, 180), di(10, 0)]);

    expect(tester.takeException(), isNull);
  });
}
