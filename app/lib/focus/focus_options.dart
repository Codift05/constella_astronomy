/// Pilihan durasi sesi fokus. Logika murni supaya bisa diuji tanpa widget.
abstract final class FocusDuration {
  static const presets = <int>[5, 10, 15, 25, 30, 45, 60];
  static const min = 5;
  static const max = 120;
  static const step = 5;
  static const defaultMinutes = 25;

  /// Menaikkan atau menurunkan durasi satu langkah, dijepit ke [min]..[max].
  static int shift(int minutes, int steps) =>
      (minutes + steps * step).clamp(min, max);

  static bool canDecrease(int minutes) => minutes > min;
  static bool canIncrease(int minutes) => minutes < max;
}
