import 'package:sqflite/sqflite.dart';

/// Penyimpanan lokal. Skemanya sengaja dibuat mencerminkan tabel Supabase di
/// docs/05-data-models.md supaya pindah ke backend nanti hanya mengganti
/// lapisan akses, bukan bentuk datanya.
///
/// Perbedaan yang disengaja dari skema Supabase:
/// - Tidak ada `user_id`. Perangkat ini satu pengguna sampai auth ada.
/// - `node_coordinates` disimpan sebagai TEXT berisi JSON, karena SQLite
///   tidak punya tipe JSONB.
abstract final class AppDatabase {
  static const fileName = 'constella.db';
  static const version = 4;

  static Future<Database> open({DatabaseFactory? factory, String? path}) async {
    final db = factory ?? databaseFactory;
    return db.openDatabase(
      path ?? await _defaultPath(db),
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
        onCreate: _create,
        onUpgrade: _upgrade,
      ),
    );
  }

  static Future<String> _defaultPath(DatabaseFactory factory) async {
    final dir = await factory.getDatabasesPath();
    return '$dir/$fileName';
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE constellations (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        node_coordinates TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    // Dibaca per halaman urut terbaru; indeks ini yang membuat keyset
    // pagination tetap murah saat isinya banyak.
    await db.execute(
      'CREATE INDEX idx_constellations_created_at '
      'ON constellations (created_at DESC, id DESC)',
    );

    await db.execute('''
      CREATE TABLE focus_sessions (
        id TEXT PRIMARY KEY,
        duration_minutes INTEGER NOT NULL,
        completed_at TEXT NOT NULL
      )
    ''');

    // Padanan kolom `users.stardust_energy`. Satu baris, karena perangkat ini
    // belum mengenal banyak pengguna.
    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        stardust_energy INTEGER NOT NULL DEFAULT 0,
        onboarding_done INTEGER NOT NULL DEFAULT 0,
        theme_mode TEXT NOT NULL DEFAULT 'system'
      )
    ''');
    await _createCaughtStars(db);

    await db.insert('profile', {
      'id': 1,
      'stardust_energy': 0,
      'onboarding_done': 0,
      'theme_mode': 'system',
    });
  }

  /// Bintang yang sudah ditangkap pengguna.
  ///
  /// Kuncinya nama tampilan, jadi satu bintang hanya bisa masuk koleksi
  /// sekali. Tanpa itu, mengetuk bintang yang sama berulang kali akan jadi
  /// cara termudah mengumpulkan Stardust, dan koleksinya kehilangan arti.
  static Future<void> _createCaughtStars(Database db) async {
    await db.execute('''
      CREATE TABLE caught_stars (
        name TEXT PRIMARY KEY,
        constellation TEXT NOT NULL,
        magnitude REAL NOT NULL,
        light_years REAL NOT NULL,
        caught_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_caught_stars_caught_at '
      'ON caught_stars (caught_at DESC)',
    );
  }

  static Future<void> _upgrade(Database db, int from, int to) async {
    if (from < 2) {
      await db.execute(
        'ALTER TABLE profile ADD COLUMN onboarding_done INTEGER NOT NULL '
        'DEFAULT 0',
      );
    }
    if (from < 3) {
      await db.execute(
        "ALTER TABLE profile ADD COLUMN theme_mode TEXT NOT NULL "
        "DEFAULT 'system'",
      );
    }
    if (from < 4) {
      await _createCaughtStars(db);
    }
  }
}
