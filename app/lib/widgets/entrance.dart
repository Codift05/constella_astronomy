import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// Memunculkan anak-anaknya satu per satu, dari bawah ke tempatnya.
///
/// Urutannya bukan hiasan: mata mengikuti benda yang bergerak, jadi urutan
/// masuk menentukan apa yang dibaca lebih dulu. Yang paling penting di layar
/// ditaruh paling awal.
///
/// Berhenti total saat Kurangi Gerak menyala — isinya langsung berada di
/// tempatnya, tanpa gerak sama sekali.
class EntranceList extends StatelessWidget {
  const EntranceList({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 520),
    this.gap = const Duration(milliseconds: 70),
    this.offset = 18,
  });

  final List<Widget> children;

  /// Lama satu anak masuk.
  final Duration duration;

  /// Jarak mulai antar anak berurutan.
  final Duration gap;

  /// Seberapa jauh ke bawah posisi awalnya, dalam piksel.
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return Column(children: children);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++)
          Entrance(
            delay: gap * i,
            duration: duration,
            offset: offset,
            child: children[i],
          ),
      ],
    );
  }
}

/// Satu benda yang naik ke tempatnya sambil memunculkan diri.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.offset = 18,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration + widget.delay,
  );

  /// Penundaan dibuat sebagai bagian depan satu animasi, bukan sebagai timer
  /// terpisah. Timer yang masih hidup saat layarnya ditutup menggantung;
  /// bagian depan animasi ikut mati bersama widgetnya.
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      widget.delay.inMicroseconds / _c.duration!.inMicroseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return widget.child;
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _t.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Angka yang berjalan naik ke nilainya, bukan melompat.
///
/// Dipakai untuk Stardust: melihat angkanya bergerak naik memberi tahu bahwa
/// ia bertambah, dan seberapa banyak, tanpa satu kata pun.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 900),
    this.textAlign,
  });

  final int value;
  final TextStyle style;
  final Duration duration;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: context.calm(duration),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        v.round().toString(),
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}
