import 'package:constella_app/theme/tokens.dart';
import 'package:constella_app/widgets/stardust_burst.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child, {required bool reduce}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduce),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Theme(
      data: buildAppTheme(Brightness.dark),
      child: Stack(children: [child]),
    ),
  ),
);

void main() {
  group('semburan debu bintang', () {
    testWidgets('menggambar partikel lalu selesai sendiri', (tester) async {
      var done = false;
      await tester.pumpWidget(
        wrap(
          StardustBurst(
            origin: const Offset(200, 300),
            onDone: () => done = true,
          ),
          reduce: false,
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.descendant(
          of: find.byType(StardustBurst),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
        reason: 'sedang menggambar di tengah jalan',
      );
      expect(done, isFalse);

      // Satu kali jalan, bukan berulang: harus selesai sendiri.
      await tester.pump(const Duration(milliseconds: 1300));
      expect(done, isTrue);
    });

    testWidgets('tidak menggambar apa pun saat Kurangi Gerak menyala', (
      tester,
    ) async {
      var done = false;
      await tester.pumpWidget(
        wrap(
          StardustBurst(
            origin: const Offset(100, 100),
            onDone: () => done = true,
          ),
          reduce: true,
        ),
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(StardustBurst),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
      // Tetap memberi tahu pemanggil supaya overlaynya dibersihkan.
      expect(done, isTrue);
    });

    testWidgets('tidak menghalangi sentuhan di bawahnya', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => tapped = true,
                ),
              ),
              StardustBurst(origin: const Offset(200, 300)),
            ],
          ),
          reduce: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tapAt(const Offset(200, 300));
      expect(tapped, isTrue, reason: 'semburan harus IgnorePointer');
    });
  });
}
