import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_controller.dart';
import '../../theme/bagan_colors.dart';
import '../../theme/bagan_theme.dart';
import '../media_actions.dart';
import '../ui_ext.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';
import '../widgets/ebook_spine_card.dart';
import '../widgets/lucide_icon.dart';
import '../widgets/media_row.dart';
import '../widgets/paged.dart';
import '../widgets/teacher_seal.dart';

enum _TeacherTab { collections, audio, video, ebook }

class TeacherDetailScreen extends StatefulWidget {
  const TeacherDetailScreen({super.key, required this.teacherId});

  final int teacherId;

  @override
  State<TeacherDetailScreen> createState() => _TeacherDetailScreenState();
}

class _TeacherDetailScreenState extends State<TeacherDetailScreen> {
  Teacher? _teacher;
  List<CollectionSummary>? _collections;
  _TeacherTab _tab = _TeacherTab.collections;
  Paged<MediaItem>? _media;
  bool _loadingHeader = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _media?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = context.read<AppController>().catalogue;
    final results = await Future.wait([
      repo.getTeacher(widget.teacherId),
      repo.getTeacherCollections(widget.teacherId),
    ]);
    if (!mounted) return;
    _teacher = results[0] as Teacher?;
    _collections = results[1] as List<CollectionSummary>;
    _loadingHeader = false;
    if (_collections!.isEmpty) _tab = _TeacherTab.audio;
    _loadTab();
  }

  void _setTab(_TeacherTab next) {
    if (next == _tab) return;
    _tab = next;
    _loadTab();
  }

  void _loadTab() {
    _media?.dispose();
    _media = null;
    if (_tab != _TeacherTab.collections) {
      final repo = context.read<AppController>().catalogue;
      final kind = switch (_tab) {
        _TeacherTab.audio => MediaKind.audio,
        _TeacherTab.video => MediaKind.video,
        _TeacherTab.ebook => MediaKind.ebook,
        _TeacherTab.collections => MediaKind.audio,
      };
      final paged = Paged<MediaItem>(
        (offset, limit) => repo.getTeacherMedia(
          widget.teacherId,
          kind: kind,
          offset: offset,
          limit: limit,
        ),
      );
      _media = paged;
      unawaited(paged.loadMore());
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    final teacher = _teacher;
    return DetailChrome(
      currentTab: 1,
      body: _loadingHeader
          ? const LoadingFooter()
          : teacher == null
          ? Column(
              children: [
                BackBar(label: s.teachers, fallback: '/browse?kind=teachers'),
                Expanded(
                  child: EmptyState(
                    icon: 'users',
                    title: s.nothingFound,
                    body: s.nothingFoundBody,
                  ),
                ),
              ],
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: BackBar(
                    label: s.teachers,
                    fallback: '/browse?kind=teachers',
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 14),
                    child: Column(
                      children: [
                        TeacherSeal(teacher: teacher, size: 76),
                        const SizedBox(height: 12),
                        if (teacher.featured) ...[
                          SmallBadge(
                            label: s.featuredTeacher,
                            background: c.goldSoft,
                            foreground: c.gold,
                          ),
                          const SizedBox(height: 10),
                        ],
                        BText(
                          teacher.displayName,
                          size: 16,
                          serif: true,
                          weight: FontWeight.w700,
                          align: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        BText(
                          s.teachingsCollections(
                            teacher.mediaCount,
                            teacher.collectionCount,
                          ),
                          size: 11.5,
                          color: c.inkMuted,
                          align: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: PillRow(
                    children: [
                      for (final (tab, label) in [
                        (_TeacherTab.collections, s.tabCollections),
                        (_TeacherTab.audio, s.kindAudio),
                        (_TeacherTab.video, s.kindVideo),
                        (_TeacherTab.ebook, s.kindEbooks),
                      ])
                        FilterPill(
                          label: label,
                          primary: true,
                          selected: _tab == tab,
                          onTap: () => _setTab(tab),
                        ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: Hairline()),
                ..._tabSlivers(s, c),
              ],
            ),
    );
  }

  List<Widget> _tabSlivers(AppStrings s, BaganColors c) {
    if (_tab == _TeacherTab.collections) {
      final cols = _collections ?? const <CollectionSummary>[];
      if (cols.isEmpty) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: 'folders',
              title: s.nothingFound,
              body: s.nothingFoundBody,
            ),
          ),
        ];
      }
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          sliver: SliverList.separated(
            itemCount: cols.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _CollectionCard(collection: cols[i]),
          ),
        ),
      ];
    }
    final paged = _media;
    if (paged == null) return const [];
    return [
      SliverToBoxAdapter(
        child: ListenableBuilder(
          listenable: paged,
          builder: (context, _) {
            if (paged.initialLoading) return const LoadingFooter();
            if (paged.empty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: EmptyState(
                  icon: 'folder-open',
                  title: s.nothingFound,
                  body: s.nothingFoundBody,
                ),
              );
            }
            final items = paged.items;
            if (_tab == _TeacherTab.ebook) {
              return Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 10,
                          childAspectRatio: 174 / 218,
                        ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => EbookSpineCard(
                      item: items[i],
                      index: i,
                      onTap: () =>
                          MediaActions.open(context, items[i], queue: items),
                    ),
                  ),
                  if (!paged.done)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: BaganButton(
                        label: s.loadMore,
                        primary: false,
                        onTap: paged.loadMore,
                      ),
                    ),
                ],
              );
            }
            return Column(
              children: [
                const SizedBox(height: 8),
                for (final item in items)
                  MediaRow(
                    item: item,
                    onTap: () => MediaActions.open(context, item, queue: items),
                  ),
                if (paged.loading) const LoadingFooter(),
                if (!paged.done && !paged.loading)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: BaganButton(
                      label: s.loadMore,
                      primary: false,
                      onTap: paged.loadMore,
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    ];
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.collection});

  final CollectionSummary collection;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    final type = (collection.type ?? 'audio').toLowerCase();
    final (badge, bg, fg) = switch (type) {
      'video' => (s.videoBadge, c.goldSoft, c.gold),
      'ebook' => (s.ebookBadge, c.sageSoft, c.sage),
      _ => (s.audioBadge, c.lacquerSoft, c.lacquer),
    };
    return Semantics(
      button: true,
      label: collection.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/collection/${collection.id}'),
        child: BaganCard(
          radius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SmallBadge(
                          label: badge,
                          background: bg,
                          foreground: fg,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: BText(
                            collection.name,
                            size: 13.5,
                            weight: FontWeight.w600,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    BText(
                      s.tracksOrdered(collection.itemCount),
                      size: 11.5,
                      color: c.inkMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              LucideIcon('chevron-right', size: 18, color: c.inkSubtle),
            ],
          ),
        ),
      ),
    );
  }
}
