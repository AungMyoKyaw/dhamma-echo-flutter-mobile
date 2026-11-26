import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_controller.dart';
import '../../services/download_manager.dart';
import '../../theme/bagan_colors.dart';
import '../../theme/bagan_theme.dart';
import '../media_actions.dart';
import '../ui_ext.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';
import '../widgets/echo_emblem.dart';
import '../widgets/lucide_icon.dart';
import '../widgets/media_row.dart';

enum _LibraryTab { saved, history, downloads }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  _LibraryTab _tab = _LibraryTab.saved;
  final Map<int, MediaItem> _cache = {};

  Future<List<MediaItem>> _resolve(Iterable<int> ids) async {
    final list = ids.toList();
    final missing = list.where((id) => !_cache.containsKey(id)).toList();
    if (missing.isNotEmpty) {
      final fetched = await context
          .read<AppController>()
          .catalogue
          .getMediaByIds(missing);
      for (final m in fetched) {
        _cache[m.id] = m;
      }
    }
    return [
      for (final id in list)
        if (_cache[id] != null) _cache[id]!,
    ];
  }

  Future<void> _confirmClearDownloads() async {
    final s = context.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: BText(
          s.clearDownloadsTitle,
          size: 17,
          serif: true,
          weight: FontWeight.w700,
        ),
        content: BText(s.clearDownloadsBody, size: 13, color: ctx.c.inkMuted),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: BText(s.cancel, size: 13, color: ctx.c.inkMuted),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: BText(
              s.remove,
              size: 13,
              color: ctx.c.danger,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<DownloadManager>().clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    final app = context.watch<AppController>();
    final dl = context.watch<DownloadManager>();
    final dlCount = dl.active.length + dl.completed.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabHeader(
          title: s.myLibrary,
          trailing: Tappable(
            semanticLabel: s.settings,
            onTap: () => context.push('/settings'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.rule),
              ),
              child: Center(
                child: LucideIcon('settings-2', size: 20, color: c.ink),
              ),
            ),
          ),
        ),
        PillRow(
          children: [
            FilterPill(
              label: s.savedTab(app.savedIds.length),
              primary: true,
              selected: _tab == _LibraryTab.saved,
              onTap: () => setState(() => _tab = _LibraryTab.saved),
            ),
            FilterPill(
              label: s.historyTab,
              primary: true,
              selected: _tab == _LibraryTab.history,
              onTap: () => setState(() => _tab = _LibraryTab.history),
            ),
            FilterPill(
              label: s.downloadsTab(dlCount),
              primary: true,
              selected: _tab == _LibraryTab.downloads,
              onTap: () => setState(() => _tab = _LibraryTab.downloads),
            ),
          ],
        ),
        const Hairline(),
        if (!app.online)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: BaganCard(
              radius: 14,
              color: c.goldSoft,
              borderColor: c.gold.withValues(alpha: 0.35),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LucideIcon('wifi-off', size: 20, color: c.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BText(
                          s.youAreOffline,
                          size: 13,
                          weight: FontWeight.w600,
                        ),
                        const SizedBox(height: 2),
                        BText(s.offlineBody, size: 11, color: c.inkMuted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: switch (_tab) {
            _LibraryTab.saved => _savedView(app, s),
            _LibraryTab.history => _historyView(app, s),
            _LibraryTab.downloads => _downloadsView(app, dl, s, c),
          },
        ),
      ],
    );
  }

  Widget _savedView(AppController app, AppStrings s) {
    final ids = app.savedIds;
    if (ids.isEmpty) {
      return EmptyState(
        leading: const EchoEmblem(size: 56),
        title: s.nothingSaved,
        body: s.nothingSavedBody,
        actionLabel: s.browseCatalogue,
        onAction: () => context.go('/browse'),
      );
    }
    return FutureBuilder<List<MediaItem>>(
      future: _resolve(ids),
      builder: (context, snap) {
        final items = snap.data;
        if (items == null) return const SizedBox.shrink();
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: items.length,
          itemBuilder: (_, i) => MediaRow(
            item: items[i],
            onTap: () => MediaActions.open(context, items[i], queue: items),
          ),
        );
      },
    );
  }

  Widget _historyView(AppController app, AppStrings s) {
    final entries = app.history;
    if (entries.isEmpty) {
      return EmptyState(
        icon: 'history',
        title: s.noHistory,
        body: s.nothingToResumeBody,
        actionLabel: s.browseCatalogue,
        onAction: () => context.go('/browse'),
      );
    }
    return FutureBuilder<List<MediaItem>>(
      future: _resolve(entries.map((e) => e.mediaId)),
      builder: (context, snap) {
        final items = snap.data;
        if (items == null) return const SizedBox.shrink();
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: items.length,
          itemBuilder: (_, i) => MediaRow(
            item: items[i],
            onTap: () => MediaActions.open(context, items[i], queue: items),
          ),
        );
      },
    );
  }

  Widget _downloadsView(
    AppController app,
    DownloadManager dl,
    AppStrings s,
    BaganColors c,
  ) {
    final active = dl.active;
    final failed = dl.failed;
    final completed = dl.completed;
    final allIds = [
      ...active.map((r) => r.mediaId),
      ...failed.map((r) => r.mediaId),
      ...completed.map((r) => r.mediaId),
    ];
    if (allIds.isEmpty) {
      return EmptyState(
        icon: 'download',
        title: s.noDownloads,
        body: s.noDownloadsBody,
        actionLabel: s.browseCatalogue,
        onAction: () => context.go('/browse'),
      );
    }
    return FutureBuilder<List<MediaItem>>(
      future: _resolve(allIds),
      builder: (context, snap) {
        final map = {for (final m in snap.data ?? const <MediaItem>[]) m.id: m};
        final audioCount = completed
            .where((r) => map[r.mediaId]?.kind == MediaKind.audio)
            .length;
        final videoCount = completed
            .where((r) => map[r.mediaId]?.kind == MediaKind.video)
            .length;
        final pdfCount = completed
            .where((r) => map[r.mediaId]?.kind == MediaKind.ebook)
            .length;
        final bytes = dl.storageBytes();
        return ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BaganCard(
                radius: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: BText(
                            s.offlineStorage,
                            size: 10.5,
                            weight: FontWeight.w600,
                            color: c.inkMuted,
                          ),
                        ),
                        BText(
                          s.storageUsed(formatBytes(bytes)),
                          size: 12,
                          weight: FontWeight.w600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: completed.isEmpty ? 0 : 0.35,
                        minHeight: 6,
                        color: c.lacquer,
                        backgroundColor: c.surfaceSoft,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: BText(
                            s.storageBreakdown(
                              audioCount,
                              videoCount,
                              pdfCount,
                              app.settings.wifiOnly,
                            ),
                            size: 11,
                            color: c.inkMuted,
                          ),
                        ),
                        if (completed.isNotEmpty)
                          Tappable(
                            semanticLabel: s.clear,
                            minSize: 32,
                            onTap: _confirmClearDownloads,
                            child: BText(
                              s.clear,
                              size: 11,
                              weight: FontWeight.w600,
                              color: c.danger,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            for (final r in active)
              if (map[r.mediaId] case final item?)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: BaganCard(
                    radius: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: BText(
                                s.downloadingPct(
                                  ((r.progress ?? 0) * 100).round(),
                                ),
                                size: 11.5,
                                weight: FontWeight.w600,
                                color: c.lacquer,
                              ),
                            ),
                            Tappable(
                              semanticLabel: s.cancel,
                              minSize: 32,
                              onTap: () => dl.cancel(item.id),
                              child: BText(
                                s.cancel,
                                size: 11.5,
                                color: c.inkMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        BText(item.displayTitle, size: 12, maxLines: 2),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: r.progress,
                            minHeight: 4,
                            color: c.lacquer,
                            backgroundColor: c.surfaceSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            for (final r in failed)
              if (map[r.mediaId] case final item?)
                MediaRow(item: item, onTap: () => dl.retry(item)),
            if (completed.isNotEmpty) ...[
              SectionLabel(s.readyOffline),
              for (final r in completed)
                if (map[r.mediaId] case final item?)
                  Dismissible(
                    key: ValueKey('dl-${item.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: c.danger,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: BText(
                        s.remove,
                        color: c.onLacquer,
                        weight: FontWeight.w600,
                      ),
                    ),
                    onDismissed: (_) => dl.remove(item.id),
                    child: MediaRow(
                      item: item,
                      onTap: () => MediaActions.open(
                        context,
                        item,
                        queue: [
                          for (final cr in completed)
                            if (map[cr.mediaId] != null) map[cr.mediaId]!,
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        );
      },
    );
  }
}
