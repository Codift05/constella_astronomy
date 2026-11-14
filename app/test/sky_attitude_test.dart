import 'dart:async';
import 'dart:math' as math;

import 'package:constella_app/ar/sky_attitude.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

const g = 9.81;

/// Derajat ke radian, supaya ekspektasi tes terbaca sebagai sudut.
double deg(double d) => d * math.pi / 180;

void main() {
  group('skyElevation', () {
    test('ponsel tegak, kamera menghadap cakrawala, elevasi 0', () {
      // Diam dan tegak: gravitasi ke bawah, akselerometer membaca +y.
      expect(skyElevation(0, g, 0), closeTo(0, 1e-9));
    });

    test('kamera lurus ke zenit, elevasi +90', () {
      // Layar menghadap tanah: akselerometer membaca -z.
      expect(skyElevation(0, 0, -g), closeTo(math.pi / 2, 1e-9));
    });

    test('kamera lurus ke tanah, elevasi -90', () {
      expect(skyElevation(0, 0, g), closeTo(-math.pi / 2, 1e-9));
    });

    test('miring 45 derajat ke atas', () {
      final c = g / math.sqrt2;
      expect(skyElevation(0, c, -c), closeTo(deg(45), 1e-9));
    });

    test('kemiringan samping tidak mengubah elevasi', () {
      // Berputar pada sumbu pandang: x dan y bertukar, z tetap.
      expect(skyElevation(g, 0, 0), closeTo(0, 1e-9));
    });

    test('jatuh bebas tidak punya arah bawah', () {
      expect(skyElevation(0, 0, 0), isNull);
      expect(skyElevation(0.3, 0.2, 0.1), isNull);
    });

    test('besaran tidak memengaruhi hasil, hanya arahnya', () {
      expect(skyElevation(0, 0, -g), closeTo(skyElevation(0, 0, -1000)!, 1e-9));
    });
  });

  group('horizonY', () {
    const h = 2000.0;

    test('menghadap cakrawala, garisnya di tengah layar', () {
      expect(horizonY(elevation: 0, height: h), closeTo(h / 2, 1e-9));
    });

    test(
      'menengadah setengah bidang pandang, cakrawala jatuh ke tepi bawah',
      () {
        // Bidang pandang bawaan 65 derajat, jadi setengahnya 32,5.
        expect(horizonY(elevation: deg(32.5), height: h), closeTo(h, 1e-6));
      },
    );

    test('menengadah lebih jauh, cakrawala keluar bingkai bawah', () {
      // Seluruh bingkai berisi langit.
      expect(horizonY(elevation: deg(60), height: h), greaterThan(h));
    });

    test('menunduk setengah bidang pandang, cakrawala naik ke tepi atas', () {
      expect(horizonY(elevation: -deg(32.5), height: h), closeTo(0, 1e-6));
    });

    test('menunduk jauh, cakrawala di atas bingkai: tidak ada langit', () {
      expect(horizonY(elevation: -deg(70), height: h), lessThan(0));
    });

    test('monoton naik terhadap elevasi', () {
      var prev = double.negativeInfinity;
      for (var d = -80.0; d <= 80.0; d += 5) {
        final y = horizonY(elevation: deg(d), height: h);
        expect(y, greaterThan(prev), reason: 'turun di $d derajat');
        prev = y;
      }
    });

    test('tetap terhingga di sudut ekstrem', () {
      expect(horizonY(elevation: math.pi / 2, height: h).isFinite, isTrue);
      expect(horizonY(elevation: -math.pi / 2, height: h).isFinite, isTrue);
    });

    test('bidang pandang lebih sempit menggeser cakrawala lebih jauh', () {
      final wide = horizonY(
        elevation: deg(20),
        height: h,
        verticalFov: deg(90),
      );
      final narrow = horizonY(
        elevation: deg(20),
        height: h,
        verticalFov: deg(40),
      );
      expect(narrow, greaterThan(wide));
    });
  });

  group('SkyAttitude', () {
    late StreamController<AccelerometerEvent> controller;
    late SkyAttitude attitude;

    AccelerometerEvent event(double x, double y, double z) =>
        AccelerometerEvent(x, y, z, DateTime.now());

    setUp(() {
      controller = StreamController<AccelerometerEvent>.broadcast();
      attitude = SkyAttitude(
        stream: controller.stream,
        settleTimeout: const Duration(milliseconds: 40),
      );
    });

    tearDown(() async {
      attitude.dispose();
      await controller.close();
    });

    test('belum tersedia sebelum pembacaan pertama', () {
      attitude.start();
      expect(attitude.available, isFalse);
      expect(attitude.elevation, 0);
    });

    test('pembacaan pertama dipakai utuh, tanpa pelicin', () async {
      attitude.start();
      controller.add(event(0, 0, -g));
      await Future<void>.delayed(Duration.zero);
      expect(attitude.available, isTrue);
      expect(attitude.elevation, closeTo(math.pi / 2, 1e-9));
    });

    test('pembacaan berikutnya dilicinkan, tidak melompat', () async {
      attitude.start();
      controller.add(event(0, g, 0)); // elevasi 0
      await Future<void>.delayed(Duration.zero);
      controller.add(event(0, 0, -g)); // lompat ke 90 derajat
      await Future<void>.delayed(Duration.zero);
      // Low-pass menahan lompatan: jauh di bawah target.
      expect(attitude.elevation, lessThan(deg(20)));
      expect(attitude.elevation, greaterThan(0));
    });

    test('derau kecil tidak memberi tahu pendengar', () async {
      attitude.start();
      controller.add(event(0, g, 0));
      await Future<void>.delayed(Duration.zero);

      var calls = 0;
      attitude.addListener(() => calls++);
      // Getaran jauh di bawah ambang 0,7 derajat.
      for (var i = 0; i < 20; i++) {
        controller.add(event(0.002 * i, g, 0.001));
        await Future<void>.delayed(Duration.zero);
      }
      expect(calls, 0);
    });

    test('gerakan nyata memberi tahu pendengar', () async {
      attitude.start();
      controller.add(event(0, g, 0));
      await Future<void>.delayed(Duration.zero);

      var calls = 0;
      attitude.addListener(() => calls++);
      for (var i = 0; i < 20; i++) {
        controller.add(event(0, 0, -g));
        await Future<void>.delayed(Duration.zero);
      }
      expect(calls, greaterThan(0));
    });

    test('tanpa sensor, tetap tidak tersedia setelah tenggat', () async {
      attitude.start();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(attitude.available, isFalse);
      expect(attitude.elevation, 0);
    });

    test('pembacaan jatuh bebas diabaikan, bukan merusak sudut', () async {
      attitude.start();
      controller.add(event(0, g, 0));
      await Future<void>.delayed(Duration.zero);
      final before = attitude.elevation;
      controller.add(event(0, 0, 0));
      await Future<void>.delayed(Duration.zero);
      expect(attitude.elevation, before);
    });

    test('start dua kali tidak membuat langganan ganda', () async {
      attitude.start();
      attitude.start();
      controller.add(event(0, g, 0));
      await Future<void>.delayed(Duration.zero);

      var calls = 0;
      attitude.addListener(() => calls++);
      controller.add(event(0, 0, -g));
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);
    });
  });
}
