import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Satu tuas untuk seluruh gerak di aplikasi.
///
/// iOS dan Android punya setelan "Kurangi Gerak" untuk orang yang mabuk gerak.
/// Flutter meneruskannya lewat `MediaQuery.disableAnimations`, tapi hanya
/// transisi bawaan yang menghormatinya; animasi buatan sendiri tidak, kecuali
/// diperiksa seperti di sini.
///
/// `accessibility.md`: gerak harus opsional dan tidak pernah jadi satu-satunya
/// pembawa makna.
extension CalmMotion on BuildContext {
  /// True saat pengguna meminta gerak dikurangi.
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;

  /// Durasi yang runtuh jadi nol saat Kurangi Gerak aktif, sehingga
  /// perpindahannya tetap terjadi tapi tanpa gerak antara.
  Duration calm(Duration d) => reduceMotion ? Duration.zero : d;

  /// Kurva yang diratakan saat Kurangi Gerak aktif. Dipakai untuk kurva
  /// memantul seperti `easeOutBack`, yang justru paling mengganggu.
  Curve calmCurve(Curve c) => reduceMotion ? Curves.linear : c;
}

/// Menjalankan [controller] menuju [target] dengan spring, atau melompat
/// langsung ke sana saat pengguna meminta gerak dikurangi.
///
/// Dipakai menggantikan `animateWith(SpringSimulation(...))` di seluruh
/// aplikasi, supaya tidak ada satu pun spring yang lolos dari setelan itu.
void springTo(
  AnimationController controller,
  SpringDescription spring,
  double target, {
  required bool reduceMotion,
}) {
  if (reduceMotion) {
    controller.stop();
    controller.value = target;
    return;
  }
  controller.animateWith(
    SpringSimulation(spring, controller.value, target, controller.velocity),
  );
}

/// Menjaga animasi berulang tanpa henti agar berhenti saat Kurangi Gerak
/// aktif, dan berjalan lagi saat dimatikan.
///
/// R-39: apa pun yang bergerak lebih dari lima detik harus bisa dihentikan.
/// Napas maskot dan denyut orb berjalan selamanya, jadi setelan sistem itulah
/// kendali hentinya.
void holdOrRepeat(
  AnimationController controller, {
  required bool reduceMotion,
  double restingValue = 0.5,
}) {
  if (reduceMotion) {
    if (controller.isAnimating) controller.stop();
    controller.value = restingValue;
  } else if (!controller.isAnimating) {
    controller.repeat(reverse: true);
  }
}
