/// Sesi fokus yang sedang berjalan.
///
/// Sisa waktu dihitung dari jam dinding, bukan dari akumulasi tick, supaya
/// tetap akurat saat aplikasi masuk background dan tick-nya berhenti
/// (docs/04-features-mvp.md §4.4).
class FocusSession {
  const FocusSession({
    required this.totalMinutes,
    required this.startedAt,
    this.pausedAt,
    this.pausedTotal = Duration.zero,
  });

  factory FocusSession.start(int minutes, {DateTime? now}) =>
      FocusSession(totalMinutes: minutes, startedAt: now ?? DateTime.now());

  final int totalMinutes;
  final DateTime startedAt;

  /// Kapan jeda dimulai. null berarti sesi sedang berjalan.
  final DateTime? pausedAt;

  /// Akumulasi durasi jeda yang sudah selesai.
  final Duration pausedTotal;

  bool get isPaused => pausedAt != null;

  Duration get total => Duration(minutes: totalMinutes);

  /// Waktu yang sudah berjalan, tidak menghitung jeda.
  Duration elapsed(DateTime now) {
    final paused = pausedAt == null ? Duration.zero : now.difference(pausedAt!);
    final raw = now.difference(startedAt) - pausedTotal - paused;
    return raw.isNegative ? Duration.zero : raw;
  }

  Duration remaining(DateTime now) {
    final left = total - elapsed(now);
    return left.isNegative ? Duration.zero : left;
  }

  /// 0.0 sampai 1.0.
  double progress(DateTime now) {
    if (total.inMicroseconds == 0) return 1;
    return (elapsed(now).inMicroseconds / total.inMicroseconds).clamp(0.0, 1.0);
  }

  bool isComplete(DateTime now) => remaining(now) == Duration.zero;

  FocusSession pause(DateTime now) => isPaused ? this : _copy(pausedAt: now);

  FocusSession resume(DateTime now) {
    final since = pausedAt;
    if (since == null) return this;
    return FocusSession(
      totalMinutes: totalMinutes,
      startedAt: startedAt,
      pausedTotal: pausedTotal + now.difference(since),
    );
  }

  FocusSession _copy({DateTime? pausedAt}) => FocusSession(
    totalMinutes: totalMinutes,
    startedAt: startedAt,
    pausedAt: pausedAt,
    pausedTotal: pausedTotal,
  );

  /// Baris untuk tabel `focus_sessions` (docs/05-data-models.md).
  Map<String, Object?> toRow(String userId, DateTime completedAt) => {
    'user_id': userId,
    'duration_minutes': totalMinutes,
    'completed_at': completedAt.toIso8601String(),
  };
}

/// Memformat sisa waktu sebagai mm:ss, atau h:mm:ss bila lewat satu jam.
String formatRemaining(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}
