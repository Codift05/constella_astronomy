import 'dart:async';

import 'package:constella_app/constellations/constellation_store.dart';
import 'package:constella_app/main.dart';
import 'package:constella_app/stardust/stardust_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Regresi: scope pernah dipasang di `MaterialApp.home`, sehingga rute yang
/// di-push (layar AR) tidak bisa membacanya dan bentuk tersimpan tidak pernah
/// sampai ke daftar.
///
/// Tes ini sengaja tidak menyentuh database: badan testWidgets berjalan di
/// zona FakeAsync, dan I/O sqflite yang nyata tidak pernah selesai di sana.
/// Penulisan ke database diuji di `constellation_store_test.dart`.
void main() {
  sqfliteFfiInit();

  late ConstellaApp app;

  setUp(() async {
    app = await ConstellaApp.inMemory(factory: databaseFactoryFfi);
  });

  testWidgets('Rute yang di-push bisa membaca kedua scope', (tester) async {
    await tester.pumpWidget(app);
    await tester.pump(const Duration(milliseconds: 600));

    final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);

    ConstellationStore? constellations;
    StardustStore? stardust;

    // Jangan di-await: Future dari push baru selesai saat rute ditutup.
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (routeContext) {
            constellations = ConstellationScope.of(routeContext);
            stardust = StardustScope.of(routeContext);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(constellations, isNotNull);
    expect(stardust, isNotNull);
    expect(identical(constellations, app.constellations), isTrue);
    expect(identical(stardust, app.stardust), isTrue);
  });
}
