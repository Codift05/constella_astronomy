import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

/// Preferensi yang bertahan antar peluncuran. Disimpan di baris `profile`
/// yang sama dengan Stardust, karena isinya sedikit dan selalu satu baris.
class AppSettings extends ChangeNotifier {
  AppSettings(this._db);

  final Database _db;

  bool _onboardingDone = false;
  bool get onboardingDone => _onboardingDone;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final rows = await _db.query('profile', where: 'id = 1', limit: 1);
    final row = rows.firstOrNull;
    _onboardingDone = (row?['onboarding_done'] as int? ?? 0) == 1;
    _themeMode = _decodeThemeMode(row?['theme_mode'] as String?);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    if (_onboardingDone) return;
    await _db.update('profile', {'onboarding_done': 1}, where: 'id = 1');
    _onboardingDone = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _db.update('profile', {
      'theme_mode': _encodeThemeMode(mode),
    }, where: 'id = 1');
  }

  /// Memutar tema: ikut sistem -> terang -> gelap -> ikut sistem.
  Future<void> cycleThemeMode() => setThemeMode(switch (_themeMode) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  });

  static ThemeMode _decodeThemeMode(String? raw) => switch (raw) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    // Termasuk null dan nilai tak dikenal: ikut sistem adalah default
    // yang diminta Apple (dark-mode.md > "match the system setting").
    _ => ThemeMode.system,
  };

  static String _encodeThemeMode(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
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
