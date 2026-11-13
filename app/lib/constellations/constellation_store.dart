import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';

import 'constellation_draft.dart';
import 'saved_constellation.dart';

/// Rasi bintang tersimpan, dibaca per halaman dari SQLite.
///
/// Paginasinya keyset, bukan OFFSET: cursor membawa `created_at` dan `id`
/// baris terakhir. Bentuk ini sengaja dipilih karena sama persis dengan
/// yang akan dipakai saat pindah ke Supabase.
class ConstellationStore extends ChangeNotifier {
  ConstellationStore(this._db, {this.pageSize = 20});

  final Database _db;
  final int pageSize;

  int _length = 0;
  int get length => _length;

  Future<void> load() async {
    final rows = await _db.rawQuery('SELECT COUNT(*) AS n FROM constellations');
    _length = (rows.first['n'] as int?) ?? 0;
    notifyListeners();
  }

  Future<SavedConstellation> add(ConstellationDraft draft, String name) async {
    final now = DateTime.now();
    final item = SavedConstellation(
      id: now.microsecondsSinceEpoch.toString(),
      name: name,
      draft: draft,
      createdAt: now,
    );
    await _db.insert('constellations', {
      'id': item.id,
      'name': item.name,
      'node_coordinates': jsonEncode(draft.toJson()),
      'created_at': item.createdAt.toIso8601String(),
    });
    _length += 1;
    notifyListeners();
    return item;
  }

  Future<void> rename(String id, String name) async {
    await _db.update(
      'constellations',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  Future<void> remove(String id) async {
    final deleted = await _db.delete(
      'constellations',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deleted > 0) _length -= deleted;
    notifyListeners();
  }

  /// Mengambil satu halaman, terbaru lebih dulu.
  /// [cursor] null berarti halaman pertama.
  Future<ConstellationPage> fetchPage({String? cursor}) async {
    final where = <String>[];
    final args = <Object?>[];
    if (cursor != null) {
      final (createdAt, id) = _decodeCursor(cursor);
      where.add('(created_at < ? OR (created_at = ? AND id < ?))');
      args.addAll([createdAt, createdAt, id]);
    }

    final rows = await _db.query(
      'constellations',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC, id DESC',
      // Satu baris lebih, hanya untuk tahu masih ada halaman berikutnya.
      limit: pageSize + 1,
    );

    final hasMore = rows.length > pageSize;
    final page = rows.take(pageSize).map(_fromRow).toList();
    return ConstellationPage(
      items: page,
      nextCursor: hasMore && page.isNotEmpty
          ? _encodeCursor(page.last.createdAt, page.last.id)
          : null,
    );
  }

  static String _encodeCursor(DateTime createdAt, String id) =>
      '${createdAt.toIso8601String()}|$id';

  static (String, String) _decodeCursor(String cursor) {
    final i = cursor.lastIndexOf('|');
    return (cursor.substring(0, i), cursor.substring(i + 1));
  }

  static SavedConstellation _fromRow(Map<String, Object?> row) =>
      SavedConstellation(
        id: row['id']! as String,
        name: row['name']! as String,
        draft: ConstellationDraft.fromJson(
          jsonDecode(row['node_coordinates']! as String)
              as Map<String, Object?>,
        ),
        createdAt: DateTime.parse(row['created_at']! as String),
      );
}

class ConstellationScope extends InheritedNotifier<ConstellationStore> {
  const ConstellationScope({
    super.key,
    required ConstellationStore super.notifier,
    required super.child,
  });

  static ConstellationStore of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ConstellationScope>();
    assert(scope?.notifier != null, 'ConstellationScope tidak ditemukan');
    return scope!.notifier!;
  }
}
