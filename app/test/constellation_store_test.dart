import 'package:constella_app/constellations/constellation_draft.dart';
import 'package:constella_app/constellations/constellation_store.dart';
import 'package:constella_app/data/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

ConstellationDraft _shape({int lines = 1}) {
  var d = const ConstellationDraft();
  for (var i = 0; i <= lines; i++) {
    d = d.addNode(Offset(i * 10, 0));
  }
  for (var i = 0; i < lines; i++) {
    d = d.connect(i, i + 1);
  }
  return d;
}

void main() {
  sqfliteFfiInit();

  late ConstellationStore store;

  setUp(() async {
    // ':memory:' di-cache per path, jadi tanpa ini tes berikutnya mewarisi
    // isi tes sebelumnya.
    await databaseFactoryFfi.deleteDatabase(inMemoryDatabasePath);
    final db = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    store = ConstellationStore(db, pageSize: 2);
    await store.load();
  });

  test('database kosong memberi halaman kosong tanpa lanjutan', () async {
    final page = await store.fetchPage();
    expect(page.items, isEmpty);
    expect(page.hasMore, isFalse);
    expect(store.length, 0);
  });

  test('bentuk tersimpan dan bisa dibaca kembali utuh', () async {
    final draft = _shape(lines: 3);
    await store.add(draft, 'Jembatan Kota');

    final page = await store.fetchPage();
    final saved = page.items.single;
    expect(saved.name, 'Jembatan Kota');
    expect(saved.draft.nodes, draft.nodes);
    expect(saved.draft.edges, draft.edges);
    expect(store.length, 1);
  });

  test('membagi ke beberapa halaman dan berhenti di akhir', () async {
    for (var i = 0; i < 5; i++) {
      await store.add(_shape(), 'Bentuk $i');
    }

    final first = await store.fetchPage();
    expect(first.items, hasLength(2));
    expect(first.hasMore, isTrue);

    final second = await store.fetchPage(cursor: first.nextCursor);
    expect(second.items, hasLength(2));

    final third = await store.fetchPage(cursor: second.nextCursor);
    expect(third.items, hasLength(1));
    expect(third.hasMore, isFalse);
  });

  test('halaman berurutan tidak menduplikasi atau melewati baris', () async {
    for (var i = 0; i < 5; i++) {
      await store.add(_shape(), 'Bentuk $i');
    }

    final names = <String>[];
    String? cursor;
    do {
      final page = await store.fetchPage(cursor: cursor);
      names.addAll(page.items.map((e) => e.name));
      cursor = page.nextCursor;
    } while (cursor != null);

    expect(names, hasLength(5));
    expect(names.toSet(), hasLength(5));
  });

  test('yang terbaru berada di urutan pertama', () async {
    await store.add(_shape(), 'Lama');
    await store.add(_shape(), 'Baru');
    final page = await store.fetchPage();
    expect(page.items.first.name, 'Baru');
  });

  test('ganti nama menulis ke database', () async {
    await store.add(_shape(), 'Nama Lama');
    final before = (await store.fetchPage()).items.single;
    await store.rename(before.id, 'Nama Baru');
    expect((await store.fetchPage()).items.single.name, 'Nama Baru');
  });

  test('hapus membuang baris dan mengurangi hitungan', () async {
    await store.add(_shape(), 'A');
    await store.add(_shape(), 'B');
    final b = (await store.fetchPage()).items.first;

    await store.remove(b.id);
    final page = await store.fetchPage();
    expect(page.items, hasLength(1));
    expect(page.items.single.name, 'A');
    expect(store.length, 1);
  });

  test('toRow memakai bentuk kolom tabel constellations', () async {
    await store.add(_shape(), 'Jembatan Kota');
    final row = (await store.fetchPage()).items.single.toRow('user-1');
    expect(row['user_id'], 'user-1');
    expect(row['name'], 'Jembatan Kota');
    expect((row['node_coordinates']! as Map)['space'], 'screen');
  });
}
