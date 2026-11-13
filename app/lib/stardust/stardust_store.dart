import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';

import '../focus/focus_session.dart';
import 'stardust_rules.dart';

/// Stardust Energy — poin eksplorasi (PRD §4.4 "Status Bar").
///
/// Sumber kebenarannya ada di SQLite; nilai di sini hanya salinan untuk
/// digambar. Setiap penambahan menulis ke database lebih dulu, baru
/// memberi tahu pendengarnya.
class StardustStore extends ChangeNotifier {
  StardustStore(this._db);

  final Database _db;

  int _energy = 0;
  int _focusMinutes = 0;
  int _focusSessions = 0;
  bool _loaded = false;

  int get energy => _energy;
  int get focusMinutes => _focusMinutes;
  int get focusSessions => _focusSessions;
  bool get isLoaded => _loaded;

  int get nextTier => StardustRules.nextTier(_energy);
  double get tierProgress => StardustRules.tierProgress(_energy);

  Future<void> load() async {
    final profile = await _db.query('profile', where: 'id = 1', limit: 1);
    final totals = await _db.rawQuery(
      'SELECT COUNT(*) AS n, COALESCE(SUM(duration_minutes), 0) AS m '
      'FROM focus_sessions',
    );
    _energy = (profile.firstOrNull?['stardust_energy'] as int?) ?? 0;
    _focusSessions = (totals.first['n'] as int?) ?? 0;
    _focusMinutes = (totals.first['m'] as int?) ?? 0;
    _loaded = true;
    notifyListeners();
  }

  /// Dipanggil hanya saat sesi benar-benar selesai. Sesi yang dibatalkan
  /// tidak memberi Stardust (docs/04-features-mvp.md §4.4).
  Future<void> completeSession(FocusSession session, {DateTime? at}) async {
    final when = at ?? DateTime.now();
    await _db.insert('focus_sessions', {
      'id': when.microsecondsSinceEpoch.toString(),
      'duration_minutes': session.totalMinutes,
      'completed_at': when.toIso8601String(),
    });
    await _award(StardustRules.forFocusSession(session.totalMinutes));
    _focusSessions += 1;
    _focusMinutes += session.totalMinutes;
    notifyListeners();
  }

  /// Hadiah untuk satu rasi bintang yang disimpan.
  Future<void> awardConstellation(int lines) async {
    await _award(StardustRules.forConstellation(lines));
    notifyListeners();
  }

  Future<void> _award(int amount) async {
    if (amount <= 0) return;
    await _db.rawUpdate(
      'UPDATE profile SET stardust_energy = stardust_energy + ? WHERE id = 1',
      [amount],
    );
    _energy += amount;
  }
}

class StardustScope extends InheritedNotifier<StardustStore> {
  const StardustScope({
    super.key,
    required StardustStore super.notifier,
    required super.child,
  });

  static StardustStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StardustScope>();
    assert(scope?.notifier != null, 'StardustScope tidak ditemukan');
    return scope!.notifier!;
  }
}
