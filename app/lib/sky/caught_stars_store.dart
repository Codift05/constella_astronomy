import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';

import 'star_catalog.dart';

/// Satu bintang yang sudah masuk koleksi.
class CaughtStar {
  const CaughtStar({
    required this.name,
    required this.constellation,
    required this.magnitude,
    required this.lightYears,
    required this.caughtAt,
  });

  final String name;
  final String constellation;
  final double magnitude;
  final double lightYears;
  final DateTime caughtAt;

  static CaughtStar fromRow(Map<String, Object?> row) => CaughtStar(
    name: row['name']! as String,
    constellation: row['constellation']! as String,
    magnitude: (row['magnitude']! as num).toDouble(),
    lightYears: (row['light_years']! as num).toDouble(),
    caughtAt: DateTime.parse(row['caught_at']! as String),
  );
}

/// Hasil satu usaha menangkap bintang.
enum CatchOutcome {
  /// Baru pertama kali, dan Stardust diberikan.
  caught,

  /// Sudah ada di koleksi; tidak ada Stardust tambahan.
  alreadyHad,
}

/// Koleksi bintang yang sudah ditangkap.
class CaughtStarsStore extends ChangeNotifier {
  CaughtStarsStore(this._db);

  final Database _db;

  final _names = <String>{};
  int get count => _names.length;

  /// True kalau bintang ini sudah pernah ditangkap.
  bool has(String name) => _names.contains(name);

  Future<void> load() async {
    final rows = await _db.query('caught_stars', columns: ['name']);
    _names
      ..clear()
      ..addAll(rows.map((r) => r['name']! as String));
    notifyListeners();
  }

  /// Menangkap [star]. Mengembalikan [CatchOutcome.alreadyHad] kalau bintang
  /// itu sudah ada, sehingga pemanggil tahu tidak perlu memberi Stardust lagi.
  Future<CatchOutcome> catchStar(Star star) async {
    final name = star.displayName;
    if (_names.contains(name)) return CatchOutcome.alreadyHad;

    await _db.insert('caught_stars', {
      'name': name,
      'constellation': star.constellation,
      'magnitude': star.magnitude,
      'light_years': star.lightYears,
      'caught_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    _names.add(name);
    notifyListeners();
    return CatchOutcome.caught;
  }

  /// Seluruh koleksi, terbaru lebih dulu.
  Future<List<CaughtStar>> all() async {
    final rows = await _db.query('caught_stars', orderBy: 'caught_at DESC');
    return rows.map(CaughtStar.fromRow).toList();
  }
}

/// Menyediakan [CaughtStarsStore] ke pohon widget.
///
/// Dipasang di atas MaterialApp supaya rute yang di-push ikut membacanya,
/// pelajaran dari bug ConstellationScope yang sempat membuat rasi tak pernah
/// tersimpan.
class CaughtStarsScope extends InheritedNotifier<CaughtStarsStore> {
  const CaughtStarsScope({
    super.key,
    required CaughtStarsStore super.notifier,
    required super.child,
  });

  static CaughtStarsStore of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<CaughtStarsScope>();
    assert(scope?.notifier != null, 'CaughtStarsScope tidak ditemukan');
    return scope!.notifier!;
  }

  static CaughtStarsStore? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CaughtStarsScope>()?.notifier;
}
