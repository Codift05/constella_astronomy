import 'package:constella_app/data/app_database.dart';
import 'package:constella_app/focus/focus_session.dart';
import 'package:constella_app/stardust/stardust_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late StardustStore store;

  setUp(() async {
    // ':memory:' di-cache per path, jadi tanpa ini tes berikutnya mewarisi
    // isi tes sebelumnya.
    await databaseFactoryFfi.deleteDatabase(inMemoryDatabasePath);
    final db = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    store = StardustStore(db);
    await store.load();
  });

  test('mulai dari nol, bukan angka karangan', () {
    expect(store.energy, 0);
    expect(store.focusMinutes, 0);
    expect(store.focusSessions, 0);
  });

  test('sesi selesai menambah energy dan menit fokus', () async {
    await store.completeSession(FocusSession.start(25, now: DateTime(2026)));
    expect(store.energy, 25);
    expect(store.focusMinutes, 25);
    expect(store.focusSessions, 1);
  });

  test('menggambar rasi bintang juga memberi Stardust', () async {
    await store.awardConstellation(4);
    // 20 dasar + 4 garis x 5.
    expect(store.energy, 40);
    // Tapi tidak dihitung sebagai menit fokus.
    expect(store.focusMinutes, 0);
  });

  test('dua sumber menumpuk', () async {
    await store.completeSession(FocusSession.start(10, now: DateTime(2026)));
    await store.awardConstellation(2);
    expect(store.energy, 10 + 30);
  });

  test(
    'nilai bertahan setelah store dibuat ulang dari database yang sama',
    () async {
      final db = await AppDatabase.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      final first = StardustStore(db);
      await first.load();
      await first.completeSession(FocusSession.start(15, now: DateTime(2026)));

      final second = StardustStore(db);
      await second.load();
      expect(second.energy, 15);
      expect(second.focusMinutes, 15);
      expect(second.focusSessions, 1);
    },
  );

  test('memberi tahu pendengarnya', () async {
    var calls = 0;
    store.addListener(() => calls++);
    await store.completeSession(FocusSession.start(5, now: DateTime(2026)));
    expect(calls, greaterThan(0));
  });
}
