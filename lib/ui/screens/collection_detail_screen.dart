import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_controller.dart';
import '../../services/audio_playback_controller.dart';
import '../../services/download_manager.dart';
import '../../theme/bagan_colors.dart';
import '../../theme/bagan_theme.dart';
import '../media_actions.dart';
import '../ui_ext.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';
import '../widgets/media_row.dart';
import '../widgets/paged.dart';

class CollectionDetailScreen extends StatefulWidget {
  const CollectionDetailScreen({super.key, required this.collectionId});

  final int collectionId;

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  CollectionSummary? _collection;
  Paged<MediaItem>? _tracks;
  bool _loading = true;
  bool _preparingAll = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _tracks?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = context.read<AppController>().catalogue;
    final col = await repo.getCollection(widget.collectionId);
    if (!mounted) return;
    _collection = col;
    _loading = false;
    if (col != null) {
      final paged = Paged<MediaItem>(
        (offset, limit) => repo.getCollectionTracks(
          widget.collectionId,
          offset: offset,
          limit: limit,
        ),
        pageSize: 50,
      );
      _tracks = paged;
      unawaited(paged.loadMore());
    }
    setState(() {});
  }

  Future<List<MediaItem>> _fetchAllTracks() async {
    final col = _collection;
    if (col == null) return const [];
    final repo = context.read<AppController>().catalogue;
    final total = col.itemCount > 0 ? col.itemCount : 1000;
    return repo.getCollectionTracks(
      widget.collectionId,
      limit: total,
      offset: 0,
    );
  }

  Future<void> _playAll() async {
    if (_preparingAll) return;
    setState(() => _preparingAll = true);
    try {
      final all = await _fetchAllTracks();
      if (!mounted) return;
      final audioTracks = all
          .where((m) => m.kind == MediaKind.audio && m.isInAppPlayable)
          .toList();
      if (audioTracks.isNotEmpty) {
        await context.read<AudioPlaybackController>().playQueue(audioTracks, 0);
      } else if (all.isNotEmpty) {
        await MediaActions.open(context, all.first, queue: all);
      }
    } finally {
      if (mounted) setState(() => _preparingAll = false);
    }
  }

  Future<void> _downloadSeries() async {
    final s = context.s;
    final col = _collection;
    if (col == null) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BText(
                s.downloadSeriesTitle,
                size: 18,
                serif: true,
                weight: FontWeight.w700,
              ),
              const SizedBox(height: 8),
              BText(
                s.downloadSeriesBody(col.itemCount),
                size: 13,
                color: ctx.c.inkMuted,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: BaganButton(
                      label: s.cancel,
                      primary: false,
                      onTap: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BaganButton(
                      label: s.confirmDownload,
                      icon: 'download',
                      onTap: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final all = await _fetchAllTracks();
    if (!mounted) return;
    final downloadable = all.where((m) => m.isInAppPlayable).toList();
    final res = await context.read<DownloadManager>().enqueueAll(downloadable);
    if (!mounted) return;
    MediaActions.toast(context, switch (res) {
      EnqueueResult.started => s.downloadsQueued(downloadable.length),
      EnqueueResult.alreadyDownloaded => s.readyOffline,
      EnqueueResult.blockedByWifi => s.wifiRequired,
      EnqueueResult.unsupported => s.cannotOpenLink,
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    final col = _collection;
    final tracks = _tracks;
    return DetailChrome(
      currentTab: 1,
      body: _loading
          ? const LoadingFooter()
          : col == null
          ? Column(
              children: [
                BackBar(label: s.collection, fallback: '/browse'),
                Expanded(
                  child: EmptyState(
                    icon: 'folders',
                    title: s.nothingFound,
                    body: s.nothingFoundBody,
                  ),
                ),
              ],
            )
          : ListenableBuilder(
              listenable: tracks!,
              builder: (context, _) {
                final items = tracks.items;
                final total = col.itemCount > items.length
                    ? col.itemCount
                    : items.length;
                final seriesLabel = switch ((col.type ?? 'audio')
                    .toLowerCase()) {
                  'video' => s.videoSeries,
                  'ebook' => s.ebookSeries,
                  _ => s.audioSeries,
                };
                return NearEndListener(
                  onNearEnd: tracks.loadMore,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: BackBar(
                          label: s.collection,
                          fallback: '/browse',
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                          child: BaganCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SmallBadge(
                                  label: seriesLabel,
                                  background: c.lacquerSoft,
                                  foreground: c.lacquer,
                                ),
                                const SizedBox(height: 10),
                                BText(
                                  col.name,
                                  size: 19,
                                  serif: true,
                                  weight: FontWeight.w700,
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: col.teacherId == null
                                      ? null
                                      : () => context.push(
                                          '/teacher/${col.teacherId}',
                                        ),
                                  child: BText(
                                    [
                                      if ((col.teacherName ?? '').isNotEmpty)
                                        col.teacherName!,
                                      s.tracksCount(col.itemCount),
                                    ].join(' · '),
                                    size: 11.5,
                                    color: c.inkMuted,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: BaganButton(
                                        label: s.playAll,
                                        icon: 'play',
                                        onTap: _preparingAll ? null : _playAll,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: BaganButton(
                                        label: s.downloadSeries,
                                        icon: 'download',
                                        primary: false,
                                        onTap: _downloadSeries,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (items.isNotEmpty)
                        SliverToBoxAdapter(
                          child: SectionLabel(
                            s.trackOrder(1, items.length, total),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                          ),
                        ),
                      if (tracks.initialLoading)
                        const SliverToBoxAdapter(child: LoadingFooter())
                      else
                        SliverList.builder(
                          itemCount: items.length + (tracks.loading ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i >= items.length) return const LoadingFooter();
                            return MediaRow(
                              item: items[i],
                              number: i + 1,
                              onTap: () => MediaActions.open(
                                context,
                                items[i],
                                queue: items,
                              ),
                            );
                          },
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
