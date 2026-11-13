import 'package:constella_app/focus/focus_session.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime(2026, 11, 14, 10);

void main() {
  test('sisa waktu berkurang sesuai jam dinding', () {
    final s = FocusSession.start(25, now: _t0);
    expect(s.remaining(_t0), const Duration(minutes: 25));
    expect(
      s.remaining(_t0.add(const Duration(minutes: 10))),
      const Duration(minutes: 15),
    );
  });

  test('sisa waktu tidak pernah negatif', () {
    final s = FocusSession.start(5, now: _t0);
    expect(s.remaining(_t0.add(const Duration(hours: 2))), Duration.zero);
    expect(s.isComplete(_t0.add(const Duration(hours: 2))), isTrue);
  });

  test('jeda menahan hitungan', () {
    var s = FocusSession.start(25, now: _t0);
    s = s.pause(_t0.add(const Duration(minutes: 5)));
    // Lima menit berlalu dalam keadaan jeda: sisa tetap 20 menit.
    final later = _t0.add(const Duration(minutes: 10));
    expect(s.remaining(later), const Duration(minutes: 20));
    expect(s.isPaused, isTrue);
  });

  test('lanjut setelah jeda tidak menghitung waktu jeda', () {
    var s = FocusSession.start(25, now: _t0);
    s = s.pause(_t0.add(const Duration(minutes: 5)));
    s = s.resume(_t0.add(const Duration(minutes: 15)));
    expect(s.isPaused, isFalse);
    // 5 menit berjalan, 10 menit jeda: sisa 20 menit.
    expect(
      s.remaining(_t0.add(const Duration(minutes: 15))),
      const Duration(minutes: 20),
    );
  });

  test('jeda berulang menumpuk dengan benar', () {
    var s = FocusSession.start(10, now: _t0);
    s = s.pause(_t0.add(const Duration(minutes: 2)));
    s = s.resume(_t0.add(const Duration(minutes: 4)));
    s = s.pause(_t0.add(const Duration(minutes: 5)));
    s = s.resume(_t0.add(const Duration(minutes: 9)));
    // Berjalan: 0-2 dan 4-5 dan 9-9 = 3 menit.
    expect(
      s.remaining(_t0.add(const Duration(minutes: 9))),
      const Duration(minutes: 7),
    );
  });

  test('progress bergerak 0 sampai 1', () {
    final s = FocusSession.start(10, now: _t0);
    expect(s.progress(_t0), 0);
    expect(
      s.progress(_t0.add(const Duration(minutes: 5))),
      closeTo(0.5, 0.001),
    );
    expect(s.progress(_t0.add(const Duration(minutes: 99))), 1);
  });

  test('format sisa waktu', () {
    expect(formatRemaining(const Duration(minutes: 25)), '25:00');
    expect(formatRemaining(const Duration(seconds: 9)), '00:09');
    expect(
      formatRemaining(const Duration(hours: 1, minutes: 5, seconds: 3)),
      '1:05:03',
    );
  });

  test('toRow memakai bentuk kolom focus_sessions', () {
    final s = FocusSession.start(25, now: _t0);
    final row = s.toRow('user-1', _t0.add(const Duration(minutes: 25)));
    expect(row['duration_minutes'], 25);
    expect(row['user_id'], 'user-1');
  });
}
