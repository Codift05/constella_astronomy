import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';

/// Preferensi yang bertahan antar peluncuran. Disimpan di baris `profile`
/// yang sama dengan Stardust, karena isinya sedikit dan selalu satu baris.
class AppSettings extends ChangeNotifier {
  AppSettings(this._db);

  final Database _db;

  bool _onboardingDone = false;
  bool get onboardingDone => _onboardingDone;

  Future<void> load() async {
    final rows = await _db.query('profile', where: 'id = 1', limit: 1);
    _onboardingDone = (rows.firstOrNull?['onboarding_done'] as int? ?? 0) == 1;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    if (_onboardingDone) return;
    await _db.update(
      'profile',
      {'onboarding_done': 1},
      where: 'id = 1',
    );
    _onboardingDone = true;
    notifyListeners();
  }
}

class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({
    super.key,
    required AppSettings super.notifier,
    required super.child,
  });

  static AppSettings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope?.notifier != null, 'SettingsScope tidak ditemukan');
    return scope!.notifier!;
  }
}
