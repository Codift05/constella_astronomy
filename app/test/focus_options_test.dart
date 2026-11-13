import 'package:constella_app/focus/focus_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shift naik dan turun satu langkah', () {
    expect(FocusDuration.shift(25, 1), 30);
    expect(FocusDuration.shift(25, -1), 20);
  });

  test('shift dijepit di batas bawah dan atas', () {
    expect(FocusDuration.shift(FocusDuration.min, -1), FocusDuration.min);
    expect(FocusDuration.shift(FocusDuration.max, 1), FocusDuration.max);
    expect(FocusDuration.shift(7, -5), FocusDuration.min);
  });

  test('semua preset berada di dalam rentang yang diizinkan', () {
    for (final m in FocusDuration.presets) {
      expect(m, inInclusiveRange(FocusDuration.min, FocusDuration.max));
    }
  });

  test('flag tombol mati tepat di batas', () {
    expect(FocusDuration.canDecrease(FocusDuration.min), isFalse);
    expect(FocusDuration.canIncrease(FocusDuration.max), isFalse);
    expect(FocusDuration.canDecrease(FocusDuration.min + 5), isTrue);
  });
}
