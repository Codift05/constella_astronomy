import 'package:constella_app/stardust/stardust_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  _starCatchTests();
  test('sesi fokus memberi satu poin per menit', () {
    expect(StardustRules.forFocusSession(25), 25);
    expect(StardustRules.forFocusSession(5), 5);
  });

  test('rasi bintang memberi dasar plus per garis', () {
    expect(StardustRules.forConstellation(0), 20);
    expect(StardustRules.forConstellation(4), 40);
  });

  test('bentuk yang lebih kaya memberi lebih banyak', () {
    expect(
      StardustRules.forConstellation(8),
      greaterThan(StardustRules.forConstellation(3)),
    );
  });

  test('tingkat berikutnya selalu di atas energy sekarang', () {
    for (final e in [0, 1, 499, 500, 501, 1200]) {
      expect(StardustRules.nextTier(e), greaterThan(e));
    }
  });

  test('progress tingkat berputar 0 sampai mendekati 1', () {
    expect(StardustRules.tierProgress(0), 0);
    expect(StardustRules.tierProgress(250), closeTo(0.5, 0.001));
    expect(StardustRules.tierProgress(500), 0);
    expect(StardustRules.tierProgress(750), closeTo(0.5, 0.001));
  });
}

void _starCatchTests() {
  group('hadiah menangkap bintang', () {
    test('bintang paling terang memberi paling sedikit', () {
      expect(StardustRules.perStarCaught(-1.44), 5);
    });

    test('bintang redup di batas katalog memberi paling banyak', () {
      expect(StardustRules.perStarCaught(5.0), 30);
    });

    test('naik seiring magnitudo, tidak pernah turun', () {
      var prev = -1;
      for (var m = -1.5; m <= 5.0; m += 0.5) {
        final v = StardustRules.perStarCaught(m);
        expect(v, greaterThanOrEqualTo(prev), reason: 'pada magnitudo $m');
        prev = v;
      }
    });

    test('selalu di rentang yang wajar', () {
      for (var m = -30.0; m <= 30.0; m += 1) {
        expect(StardustRules.perStarCaught(m), inInclusiveRange(5, 40));
      }
    });
  });
}
