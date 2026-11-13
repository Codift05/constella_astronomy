import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constellations/constellation_draft.dart';
import '../l10n/l10n_ext.dart';
import '../theme/tokens.dart';
import 'soft_ui.dart';

/// Fitur 4.2 — lapisan tempat pengguna menaruh node dan menarik garis neon
/// di atas tangkapan kamera.
///
/// shortcut: node ditaruh manual lewat ketukan. PRD meminta sistem melabuhkan
/// node otomatis pada sumber cahaya ekstrem, yang butuh pengenalan scene
/// AR — docs/06-open-questions.md #1 sampai #4.
class ConstellationLayer extends StatefulWidget {
  const ConstellationLayer({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final ConstellationDraft draft;
  final ValueChanged<ConstellationDraft> onChanged;

  @override
  State<ConstellationLayer> createState() => _ConstellationLayerState();
}

class _ConstellationLayerState extends State<ConstellationLayer> {
  int? _dragFrom;
  Offset? _dragTo;

  void _handleTap(TapUpDetails d) {
    // Ketukan tepat di atas node yang sudah ada bukan node baru.
    if (widget.draft.nodeAt(d.localPosition) != null) return;
    HapticFeedback.lightImpact();
    widget.onChanged(widget.draft.addNode(d.localPosition));
  }

  void _handlePanStart(DragStartDetails d) {
    final from = widget.draft.nodeAt(d.localPosition);
    if (from == null) return;
    setState(() {
      _dragFrom = from;
      _dragTo = d.localPosition;
    });
  }

  void _handlePanUpdate(DragUpdateDetails d) {
    if (_dragFrom == null) return;
    setState(() => _dragTo = d.localPosition);
  }

  void _handlePanEnd(DragEndDetails d) {
    final from = _dragFrom;
    final to = _dragTo;
    setState(() {
      _dragFrom = null;
      _dragTo = null;
    });
    if (from == null || to == null) return;

    final target = widget.draft.nodeAt(to);
    if (target == null) return;

    final connected = widget.draft.connect(from, target);
    if (identical(connected, widget.draft)) return;
    HapticFeedback.lightImpact();
    widget.onChanged(connected);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: _handleTap,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ConstellationPainter(
            draft: widget.draft,
            dragFrom: _dragFrom == null ? null : widget.draft.nodes[_dragFrom!],
            dragTo: _dragTo,
          ),
          willChange: _dragFrom != null,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  const _ConstellationPainter({
    required this.draft,
    this.dragFrom,
    this.dragTo,
  });

  final ConstellationDraft draft;
  final Offset? dragFrom;
  final Offset? dragTo;

  static const _neon = AppNight.neon;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = _neon.withValues(alpha: 0.5)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (final (a, b) in draft.edges) {
      canvas.drawLine(draft.nodes[a], draft.nodes[b], glow);
      canvas.drawLine(draft.nodes[a], draft.nodes[b], line);
    }

    // Garis yang sedang ditarik jari, belum terkunci ke node mana pun.
    if (dragFrom != null && dragTo != null) {
      canvas.drawLine(
        dragFrom!,
        dragTo!,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    for (final node in draft.nodes) {
      canvas.drawCircle(
        node,
        12,
        Paint()
          ..color = _neon.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawCircle(node, 5, Paint()..color = Colors.white);
      canvas.drawCircle(
        node,
        9,
        Paint()
          ..color = _neon
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter oldDelegate) =>
      oldDelegate.draft != draft ||
      oldDelegate.dragFrom != dragFrom ||
      oldDelegate.dragTo != dragTo;
}

/// Kartu glassmorphism melayang: nama bentuk, hitungan node, dan aksinya.
class ConstellationDraftCard extends StatelessWidget {
  const ConstellationDraftCard({
    super.key,
    required this.draft,
    required this.controller,
    required this.onUndo,
    this.onSave,
  });

  final ConstellationDraft draft;
  final TextEditingController controller;
  final VoidCallback onUndo;

  /// null menonaktifkan tombol simpan, misalnya saat belum ada garis.
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GlassCard(
      grouped: true,
      tint: AppNight.scrim,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.nodesAndLines(draft.nodes.length, draft.edges.length),
            style: AppText.caption.copyWith(color: AppNight.onSurfaceMuted),
          ),
          const SizedBox(height: AppSpace.sm),
          TextField(
            controller: controller,
            style: AppText.body.copyWith(
              color: Colors.white,
              fontFamily: AppFont.rounded,
              fontSize: 18,
            ),
            cursorColor: AppNight.accent,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: l10n.constellationNameExample,
              hintStyle: AppText.body.copyWith(
                color: Colors.white38,
                fontFamily: AppFont.rounded,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              SpringTap(
                onTap: onUndo,
                pressedScale: 0.9,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.md,
                    vertical: 10,
                  ),
                  decoration: const ShapeDecoration(
                    color: Color(0x33FFFFFF),
                    shape: StadiumBorder(),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.undo_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.undo,
                        style: AppText.body.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: PillButton(
                  label: l10n.save,
                  // Kartu ini melayang di atas umpan kamera, jadi warnanya
                  // tetap gelap-malam dan tidak ikut tema.
                  color: AppNight.accent,
                  labelColor: AppNight.onAccent,
                  onPressed: onSave,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pratinjau kecil sebuah rasi bintang, dipakai di daftar koleksi.
/// Bentuknya diskalakan agar pas di kotak berapa pun ukurannya.
class ConstellationThumbnail extends StatelessWidget {
  const ConstellationThumbnail({
    super.key,
    required this.draft,
    this.size = 56,
  });

  final ConstellationDraft draft;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: _ThumbnailPainter(
          draft,
          line: p.accentStrong,
          dot: p.textPrimary,
        ),
        isComplex: false,
        willChange: false,
      ),
    );
  }
}

class _ThumbnailPainter extends CustomPainter {
  const _ThumbnailPainter(this.draft, {required this.line, required this.dot});

  final ConstellationDraft draft;

  /// Thumbnail ini tampil di daftar bertema terang maupun gelap, jadi warnanya
  /// datang dari palet, bukan dari konstanta malam.
  final Color line;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    if (draft.nodes.isEmpty) return;

    var minX = draft.nodes.first.dx, maxX = minX;
    var minY = draft.nodes.first.dy, maxY = minY;
    for (final n in draft.nodes) {
      minX = n.dx < minX ? n.dx : minX;
      maxX = n.dx > maxX ? n.dx : maxX;
      minY = n.dy < minY ? n.dy : minY;
      maxY = n.dy > maxY ? n.dy : maxY;
    }
    final spanX = (maxX - minX).abs();
    final spanY = (maxY - minY).abs();
    const pad = 6.0;
    final usable = size.width - pad * 2;
    // Bentuk satu titik atau satu garis lurus tidak punya rentang di salah
    // satu sumbu, jadi skalanya dijaga tetap terhingga.
    final scale = spanX == 0 && spanY == 0
        ? 1.0
        : usable / (spanX > spanY ? spanX : spanY).clamp(1.0, double.infinity);

    Offset map(Offset n) => Offset(
      pad + (n.dx - minX) * scale + (usable - spanX * scale) / 2,
      pad + (n.dy - minY) * scale + (usable - spanY * scale) / 2,
    );

    final linePaint = Paint()
      ..color = line
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in draft.edges) {
      canvas.drawLine(map(draft.nodes[a]), map(draft.nodes[b]), linePaint);
    }
    final dotPaint = Paint()..color = dot;
    for (final n in draft.nodes) {
      canvas.drawCircle(map(n), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_ThumbnailPainter oldDelegate) =>
      oldDelegate.draft != draft ||
      oldDelegate.line != line ||
      oldDelegate.dot != dot;
}
