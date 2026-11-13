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
  static const version = 1;

  static Future<Database> open({DatabaseFactory? factory, String? path}) async {
    final db = factory ?? databaseFactory;
    return db.openDatabase(
      path ?? await _defaultPath(db),
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
        onCreate: _create,
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
        stardust_energy INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.insert('profile', {
      'id': 1,
      'stardust_energy': 0,
    });
  }

}
