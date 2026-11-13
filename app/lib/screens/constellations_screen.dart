import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constellations/constellation_store.dart';
import '../constellations/saved_constellation.dart';
import '../l10n/l10n_ext.dart';
import '../theme/tokens.dart';
import '../widgets/constellation_layer.dart';
import '../widgets/soft_ui.dart';
import 'cosmic_night_screen.dart';

/// Fitur 4.2 — koleksi rasi bintang yang digambar pengguna.
/// Dimuat per halaman lewat [ConstellationStore].
class ConstellationsScreen extends StatefulWidget {
  const ConstellationsScreen({super.key});

  @override
  State<ConstellationsScreen> createState() => _ConstellationsScreenState();
}

class _ConstellationsScreenState extends State<ConstellationsScreen> {
  final _scroll = ScrollController();
  final _loaded = <SavedConstellation>[];

  ConstellationStore? _store;
  String? _nextCursor;
  bool _loading = false;
  bool _firstLoadDone = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = ConstellationScope.of(context);
    if (identical(store, _store)) return;
    _store?.removeListener(_reload);
    _store = store..addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    _store?.removeListener(_reload);
    _scroll.dispose();
    super.dispose();
  }

  /// Memuat ulang dari halaman pertama, misalnya setelah bentuk baru disimpan.
  void _reload() {
    _loaded.clear();
    _nextCursor = null;
    _firstLoadDone = false;
    _loadNextPage();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final nearBottom =
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 400;
    if (nearBottom) _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    final store = _store;
    if (store == null || _loading) return;
    if (_firstLoadDone && _nextCursor == null) return;

    setState(() => _loading = true);
    final page = await store.fetchPage(cursor: _nextCursor);
    if (!mounted) return;
    setState(() {
      _loaded.addAll(page.items);
      _nextCursor = page.nextCursor;
      _loading = false;
      _firstLoadDone = true;
    });
  }

  Future<bool> _delete(SavedConstellation item) async {
    final l10n = context.l10n;
    final store = _store;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteConstellationTitle(item.name)),
        content: Text(l10n.deleteConstellationBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteConstellation),
          ),
        ],
      ),
    );
    if (confirmed != true || store == null) return false;
    HapticFeedback.mediumImpact();
    await store.remove(item.id);
    return true;
  }

  Future<void> _rename(SavedConstellation item) async {
    final l10n = context.l10n;
    final store = _store;
    final controller = TextEditingController(text: item.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.renameConstellation),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || store == null) return;
    HapticFeedback.selectionClick();
    await store.rename(item.id, name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: context.palette.backgroundSecondary,
      body: SafeArea(
        bottom: false,
        child: _firstLoadDone && _loaded.isEmpty
            ? _EmptyState(scrollable: true)
            : ListView.separated(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.md,
                  AppSpace.md,
                  AppSpace.md,
                  kTabBarInset,
                ),
                itemCount: _loaded.length + 2,
                separatorBuilder: (_, index) =>
                    SizedBox(height: index == 0 ? AppSpace.md : AppSpace.sm),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Text(
                      l10n.constellationsTitle,
                      style: context.palette.largeTitle,
                    );
                  }
                  if (index <= _loaded.length) {
                    final item = _loaded[index - 1];
                    return _ConstellationTile(
                      key: ValueKey(item.id),
                      item: item,
                      onRename: () => _rename(item),
                      onDelete: () => _delete(item),
                    );
                  }
                  // Baris terakhir: indikator memuat halaman berikutnya.
                  return _loading
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpace.lg),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.palette.accentStrong,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(height: AppSpace.lg);
                },
              ),
      ),
    );
  }
}

class _ConstellationTile extends StatelessWidget {
  const _ConstellationTile({
    super.key,
    required this.item,
    required this.onRename,
    required this.onDelete,
  });

  final SavedConstellation item;
  final VoidCallback onRename;
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Geser baris untuk menghapus: pola daftar bawaan iOS
    // (designing-for-ios.md > "swipe actions in a list row").
    return Dismissible(
      key: ValueKey('dismiss-${item.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDelete(),
      background: Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.sm),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: context.palette.destructive,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(AppRadius.cardInner),
            ),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpace.lg),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.deleteConstellation,
                    style: context.palette.subhead.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      child: SpringTap(
        onTap: onRename,
        pressedScale: 0.98,
        child: _card(context),
      ),
    );
  }

  Widget _card(BuildContext context) {
    return SoftCard(
      radius: AppRadius.cardInner,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        children: [
          ConstellationThumbnail(draft: item.draft),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.palette.body.copyWith(
                    fontFamily: AppFont.rounded,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.nodesAndLines(
                    item.draft.nodes.length,
                    item.draft.edges.length,
                  ),
                  style: context.palette.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scrollable});

  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.hub_rounded, size: 56, color: context.palette.accentStrong),
        const SizedBox(height: AppSpace.md),
        Text(l10n.constellationsEmptyTitle, style: context.palette.title),
        const SizedBox(height: AppSpace.sm),
        Text(
          l10n.constellationsEmptyBody,
          textAlign: TextAlign.center,
          style: context.palette.caption,
        ),
        const SizedBox(height: AppSpace.lg),
        PillButton(
          label: l10n.enterCosmicNight,
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CosmicNightScreen())),
        ),
      ],
    );

    if (!scrollable) return Center(child: content);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.md,
          AppSpace.lg,
          kTabBarInset,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight - kTabBarInset - AppSpace.md,
          ),
          child: content,
        ),
      ),
    );
  }
}
