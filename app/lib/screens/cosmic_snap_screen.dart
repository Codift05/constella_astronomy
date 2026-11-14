import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/l10n_ext.dart';
import '../sky/view_description.dart';
import '../theme/tokens.dart';
import '../widgets/soft_ui.dart';

/// Satu potret kosmik beserta data yang menyertainya.
class CosmicSnap {
  const CosmicSnap({
    required this.image,
    required this.takenAt,
    required this.view,
    this.latitude,
    this.longitude,
  });

  /// PNG hasil tangkapan layar AR, lengkap dengan langit malamnya.
  final Uint8List image;

  final DateTime takenAt;
  final ViewDescription view;
  final double? latitude;
  final double? longitude;

  bool get hasLocation => latitude != null && longitude != null;

  /// Koordinat dalam bentuk yang terbaca, misalnya `1.47°N 124.84°E`.
  String? get coordinates {
    final lat = latitude, lon = longitude;
    if (lat == null || lon == null) return null;
    final ns = lat >= 0 ? 'N' : 'S';
    final ew = lon >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(2)}°$ns  '
        '${lon.abs().toStringAsFixed(2)}°$ew';
  }
}

/// Bingkai potret: foto di atas, keterangan ilmiah di bawah.
///
/// Sengaja **tidak** ditampilkan layar penuh seperti galeri biasa. Foto
/// dibingkai bersama data yang membuatnya berarti — arah, ketinggian, waktu,
/// dan bintang yang benar-benar ada di bingkai itu. Tanpa keterangan itu, yang
/// tersisa hanya foto langit gelap yang bisa diambil siapa saja.
class CosmicSnapScreen extends StatelessWidget {
  const CosmicSnapScreen({super.key, required this.snap});

  final CosmicSnap snap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.backgroundSecondary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpace.md),
                child: _Frame(snap: snap),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                0,
                AppSpace.md,
                AppSpace.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    // Builder supaya tombolnya punya context sendiri. Di iPad
                    // lembar bagikan muncul sebagai popover, dan popover harus
                    // tahu dari kotak mana ia keluar.
                    child: Builder(
                      builder: (buttonContext) => PillButton(
                        label: l10n.snapShare,
                        onPressed: () => _share(buttonContext),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: PillButton(
                      label: l10n.snapClose,
                      color: p.accentWash,
                      labelColor: p.textPrimary,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Menulis potret ke berkas sementara, lalu menyerahkannya ke lembar bagikan
  /// bawaan sistem bersama kalimat keterangannya.
  ///
  /// [context] harus milik tombolnya, bukan layarnya. Di iPhone lembar itu
  /// naik dari bawah dan asalnya tidak ditanya, tapi di iPad ia popover yang
  /// harus menunjuk ke sesuatu; tanpa kotak asal, permintaannya berakhir
  /// sebagai galat dan tidak ada lembar yang terbuka.
  Future<void> _share(BuildContext context) async {
    final caption = snapCaption(context, snap);
    final messenger = ScaffoldMessenger.of(context);
    final p = context.palette;
    final failed = context.l10n.snapFailed;
    final box = context.findRenderObject() as RenderBox?;

    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/constella-${snap.takenAt.millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(snap.image);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: caption,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      // Menulis berkas bisa gagal saat penyimpanan penuh, dan lembar bagikan
      // bisa ditolak sistem. Keduanya bukan alasan untuk menjatuhkan layar.
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: p.backgroundPrimary,
          shape: const StadiumBorder(),
          margin: const EdgeInsets.all(AppSpace.md),
          content: Text(failed, style: p.body),
        ),
      );
    }
  }
}

/// Kalimat ilmiah yang menyertai potret, disusun dari data nyata.
String snapCaption(BuildContext context, CosmicSnap snap) {
  final l10n = context.l10n;
  final v = snap.view;
  final degrees = v.altitude.round().abs().toString();

  final facing = !v.aboveHorizon
      ? l10n.snapBelowHorizon(v.compassPoint)
      : v.constellation != null
      ? l10n.snapFacingStar(v.constellation!, degrees)
      : l10n.snapFacingPlain(v.compassPoint, degrees);

  final star = v.brightest;
  final detail = star == null
      ? l10n.snapNoStar
      : l10n.snapBrightest(
          star.displayName,
          star.hasDistance
              ? (star.lightYears >= 100
                    ? star.lightYears.round().toString()
                    : star.lightYears.toStringAsFixed(1))
              : '?',
        );

  return '$facing $detail';
}

class _Frame extends StatelessWidget {
  const _Frame({required this.snap});

  final CosmicSnap snap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = snap.takenAt.toLocal();
    final stamp =
        '${t.year}-${_two(t.month)}-${_two(t.day)}  '
        '${_two(t.hour)}:${_two(t.minute)}';

    return SoftCard(
      padding: const EdgeInsets.all(AppSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRSuperellipse(
            borderRadius: BorderRadius.circular(AppRadius.cardInner),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Image.memory(
                snap.image,
                fit: BoxFit.cover,
                // Tanpa ini, gambar besar digambar ulang tiap frame.
                gaplessPlayback: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.sm,
              AppSpace.md,
              AppSpace.sm,
              AppSpace.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.snapTitle, style: p.title),
                const SizedBox(height: AppSpace.xs),
                Text(
                  snap.hasLocation ? '${snap.coordinates}  ·  $stamp' : stamp,
                  style: p.caption,
                ),
                const SizedBox(height: AppSpace.sm),
                Text(snapCaption(context, snap), style: p.body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}
