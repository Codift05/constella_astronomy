import 'package:constella_app/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:constella_app/widgets/soft_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Animasi idle maskot dan denyut orb berulang tanpa henti, jadi
/// pumpAndSettle tidak pernah selesai. Semua tes memakai pump berdurasi tetap.
/// Dibangun di setUp, bukan di dalam testWidgets: badan testWidgets berjalan
/// di zona FakeAsync, dan I/O sqflite yang nyata tidak pernah selesai di sana.
late ConstellaApp _app;

Future<void> _settle(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 600));

/// Pindah tab di dalam runAsync: layar Rasi membaca database sungguhan, dan
/// I/O itu hanya berjalan di luar zona FakeAsync.
Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.runAsync(() async {
    await tester.tap(find.text(label));
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await tester.pump();
  });
  await _settle(tester);
}

/// Fokus bukan tab lagi. PRD 4.4 menempatkannya sebagai cara masuk Malam
/// Kosmik, jadi pintunya ada di layar Langit dan membuka rute baru.
Future<void> _openFocus(WidgetTester tester) async {
  final entry = find.widgetWithText(PillButton, 'Start a focus session');
  await tester.runAsync(() async {
    // ListView membangun anaknya secara malas: pada teks 200 persen tombol
    // ini belum ada di pohon sampai digulir ke sana, dan ensureVisible saja
    // melempar "No element".
    if (entry.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        entry,
        240,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(entry);
    await tester.pump();
    await tester.tap(entry);
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await tester.pump();
  });
  await _settle(tester);
}

/// Kembali ke kerangka tab dari rute yang di-push.
Future<void> _closeFocus(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.tap(find.byIcon(Icons.chevron_left_rounded).first);
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await tester.pump();
  });
  await _settle(tester);
}

void main() {
  sqfliteFfiInit();

  setUp(() async {
    _app = await ConstellaApp.inMemory(factory: databaseFactoryFfi);
  });

  _dynamicTypeTests();
  _chipWidthTest();

  testWidgets('Tab pertama adalah landasan AR, bukan timer', (tester) async {
    await tester.pumpWidget(_app);
    await _settle(tester);

    expect(
      find.widgetWithText(PillButton, 'Enter the Cosmic Night'),
      findsOneWidget,
    );
    expect(find.text('Stardust Energy'), findsOneWidget);
    // Timer tidak boleh muncul di layar utama.
    expect(find.text('Focus time'), findsNothing);
    // Kategori fokus berasal dari gambar referensi, bukan PRD.
    expect(find.text('Study'), findsNothing);
    expect(find.text('What are you focusing on?'), findsNothing);
  });

  testWidgets('Keempat tab terbuka tanpa error', (tester) async {
    await tester.pumpWidget(_app);
    await _settle(tester);

    await _openTab(tester, 'Shapes');
    expect(find.text('No constellations yet'), findsOneWidget);

    await _openTab(tester, 'Sky');
    await _openFocus(tester);
    expect(find.text('Focus Session'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Stepper dan chip durasi mengubah angka', (tester) async {
    await tester.pumpWidget(_app);
    await _settle(tester);
    await _openFocus(tester);

    expect(find.text('25'), findsOneWidget);

    final plus = find.byIcon(Icons.add_rounded);
    await tester.ensureVisible(plus);
    await _settle(tester);
    await tester.tap(plus);
    await _settle(tester);
    expect(find.text('30'), findsOneWidget);

    final chip45 = find.widgetWithText(SoftChip, '45m');
    await tester.ensureVisible(chip45);
    await _settle(tester);
    await tester.tap(chip45);
    await _settle(tester);
    expect(find.text('45'), findsOneWidget);
  });

  testWidgets('Tidak ada overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app);
    await _settle(tester);
    expect(tester.takeException(), isNull);

    for (final tab in ['Shapes', 'Sky']) {
      await _openTab(tester, tab);
      expect(tester.takeException(), isNull, reason: 'tab $tab');
    }
    await _openFocus(tester);
    expect(tester.takeException(), isNull, reason: 'layar Fokus');
    await _closeFocus(tester);
  });
}

/// Dynamic Type: iOS mengizinkan pembesaran teks sampai jauh di atas 100%.
/// Layout harus tetap utuh, bukan hanya tidak crash.
void _dynamicTypeTests() {
  testWidgets('Bertahan pada teks 200 persen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: _app,
      ),
    );
    await _settle(tester);
    expect(tester.takeException(), isNull, reason: 'tab Sky');

    await _openTab(tester, 'Shapes');
    expect(tester.takeException(), isNull, reason: 'tab Shapes');
    await _openTab(tester, 'Sky');
    await _openFocus(tester);
    expect(tester.takeException(), isNull, reason: 'layar Fokus');
  });
}

/// Regresi: `alignment` pada container chip membuatnya memuai selebar
/// Wrap-nya, sehingga chip kategori tampil sebagai baris penuh, bukan pil.
void _chipWidthTest() {
  testWidgets('Chip kategori tetap sempit, tidak selebar layar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app);
    await _settle(tester);
    await _openFocus(tester);

    final chip = tester.getSize(find.widgetWithText(SoftChip, '25m'));
    expect(chip.height, greaterThanOrEqualTo(44));
    // Lebar kartu dikurangi padding jauh di atas 200; chip harus jauh di bawah.
    expect(chip.width, lessThan(200));
  });
}
