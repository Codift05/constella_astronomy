/// Dari mana Stardust Energy didapat.
///
/// PRD §4.4 menyebutnya "poin eksplorasi", bukan poin produktivitas, jadi
/// menggambar rasi bintang ikut memberi poin — bukan hanya sesi fokus.
///
/// shortcut: angka-angka di bawah adalah usulan, menunggu keputusan pada
/// docs/06-open-questions.md #10 dan #11.
abstract final class StardustRules {
  /// Satu poin per menit fokus yang benar-benar selesai.
  static const perFocusMinute = 1;

  /// Dasar untuk satu rasi bintang yang disimpan.
  static const perConstellation = 20;

  /// Tambahan per garis, supaya bentuk yang lebih kaya lebih dihargai.
  static const perConstellationLine = 5;

  /// Jarak antar tingkat pada progress bar melengkung.
  static const tierSize = 500;

  static int forFocusSession(int minutes) => minutes * perFocusMinute;

  static int forConstellation(int lines) =>
      perConstellation + lines * perConstellationLine;

  /// Ambang tingkat berikutnya untuk [energy].
  static int nextTier(int energy) => ((energy ~/ tierSize) + 1) * tierSize;

  /// Posisi 0.0–1.0 di dalam tingkat berjalan.
  static double tierProgress(int energy) => (energy % tierSize) / tierSize;
}
