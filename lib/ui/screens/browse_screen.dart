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

enum BrowseKind { audio, video, ebook, teachers }

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({
    super.key,
    this.initialKind = BrowseKind.audio,
    this.abhidhamma = false,
  });

  final BrowseKind initialKind;
  final bool abhidhamma;

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  late BrowseKind _kind = widget.initialKind;
  late bool _abhidhamma = widget.abhidhamma;
  String? _language;
  String? _format;
  Paged<MediaItem>? _paged;
  Future<List<Teacher>>? _teachers;
  int _count = 0;
  bool _showLegacy = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final showLegacy = context.watch<AppController>().settings.showLegacy;
    if (_paged == null || showLegacy != _showLegacy) {
      _showLegacy = showLegacy;
      _rebuildData();
    }
  }

  @override
  void dispose() {
    _paged?.dispose();
    super.dispose();
  }

  MediaKind? get _mediaKind => switch (_kind) {
    BrowseKind.audio => MediaKind.audio,
    BrowseKind.video => MediaKind.video,
    BrowseKind.ebook => MediaKind.ebook,
    BrowseKind.teachers => null,
  };

  void _rebuildData() {
    final repo = context.read<AppController>().catalogue;
    _paged?.dispose();
    _paged = null;
    if (_kind == BrowseKind.teachers) {
      _teachers ??= repo.getTeachers();
      _count = context.read<AppController>().counts.teachers;
      setState(() {});
      return;
    }
    final kind = _mediaKind;
    final language = _language;
    final format = _format;
    final abhidhamma = _abhidhamma;
    final showLegacy = _showLegacy;
    final paged = Paged<MediaItem>(
      (offset, limit) => repo.browseMedia(
        kind: kind,
        language: language,
        format: format,
        abhidhammaOnly: abhidhamma,
        showLegacy: showLegacy,
        offset: offset,
        limit: limit,
      ),
    );
    _paged = paged;
    unawaited(paged.loadMore());
    unawaited(
      repo
          .countMedia(
            kind: kind,
            language: language,
            format: format,
            abhidhammaOnly: abhidhamma,
            showLegacy: showLegacy,
          )
          .then((n) {
            if (mounted && _paged == paged) setState(() => _count = n);
          }),
    );
    setState(() {});
  }

  void _setKind(BrowseKind kind) {
    if (kind == _kind) return;
    _kind = kind;
    _language = null;
    _format = null;
    _rebuildData();
  }

  void _setLanguage(String? v) {
    _language = v;
    _rebuildData();
  }

  void _setFormat(String? v) {
    _format = v;
    _rebuildData();
  }

  void _toggleAbhidhamma() {
    _abhidhamma = !_abhidhamma;
    _rebuildData();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    final title = _kind == BrowseKind.teachers
        ? s.teachersAndSources
        : s.browse;
    final countLabel = switch (_kind) {
      BrowseKind.teachers => s.teachersTotal(_count),
      BrowseKind.ebook => s.ebooksTotal(_count),
      _ => s.itemsTotal(_count),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabHeader(
          title: title,
          serifSize: _kind == BrowseKind.teachers && !s.my ? 21 : 24,
          trailing: BText(countLabel, size: 12, color: c.inkMuted),
        ),
        PillRow(
          children: [
            for (final (k, label) in [
              (BrowseKind.audio, s.kindAudio),
              (BrowseKind.video, s.kindVideo),
              (BrowseKind.ebook, s.kindEbooks),
              (BrowseKind.teachers, s.kindTeachers),
            ])
              FilterPill(
                label: label,
                primary: true,
                selected: _kind == k,
                onTap: () => _setKind(k),
              ),
          ],
        ),
        if (_kind != BrowseKind.teachers) _filters(s),
        const Hairline(),
        Expanded(
          child: _kind == BrowseKind.teachers ? _teacherList(s) : _mediaList(s),
        ),
      ],
    );
  }

  Widget _filters(AppStrings s) {
    final formatFilter = switch (_kind) {
      BrowseKind.audio => ('mp3', s.filterMp3),
      BrowseKind.video => ('mp4', s.filterMp4),
      _ => ('pdf', s.filterPdf),
    };
    final pills = <Widget>[
      FilterPill(
        label: s.filterAll,
        selected: _language == null && _format == null && !_abhidhamma,
        onTap: () {
          _language = null;
          _format = null;
          _abhidhamma = false;
          _rebuildData();
        },
      ),
      if (_kind == BrowseKind.ebook)
        FilterPill(
          label: formatFilter.$2,
          selected: _format == formatFilter.$1,
          onTap: () =>
              _setFormat(_format == formatFilter.$1 ? null : formatFilter.$1),
        ),
      FilterPill(
        label: s.filterMyanmar,
        selected: _language == 'myanmar',
        onTap: () => _setLanguage(_language == 'myanmar' ? null : 'myanmar'),
      ),
      FilterPill(
        label: s.filterEnglish,
        selected: _language == 'english',
        onTap: () => _setLanguage(_language == 'english' ? null : 'english'),
      ),
      if (_kind != BrowseKind.ebook)
        FilterPill(
          label: formatFilter.$2,
          selected: _format == formatFilter.$1,
          onTap: () =>
              _setFormat(_format == formatFilter.$1 ? null : formatFilter.$1),
        ),
      FilterPill(
        label: s.abhidhamma,
        selected: _abhidhamma,
        onTap: _toggleAbhidhamma,
      ),
    ];
    return PillRow(children: pills);
  }

  Widget _mediaList(AppStrings s) {
    final paged = _paged;
    if (paged == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: paged,
      builder: (context, _) {
        if (paged.initialLoading) return const LoadingFooter();
        if (paged.empty) {
          return EmptyState(
            icon: 'search',
            title: s.nothingFound,
            body: s.nothingFoundBody,
          );
        }
        final items = paged.items;
        if (_kind == BrowseKind.ebook) {
          return NearEndListener(
            onNearEnd: paged.loadMore,
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 10,
                childAspectRatio: 174 / 218,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => EbookSpineCard(
                item: items[i],
                index: i,
                onTap: () => MediaActions.open(context, items[i], queue: items),
              ),
            ),
          );
        }
        return NearEndListener(
          onNearEnd: paged.loadMore,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: items.length + (paged.loading ? 1 : 0),
            itemBuilder: (_, i) {
              if (i >= items.length) return const LoadingFooter();
              return MediaRow(
                item: items[i],
                onTap: () => MediaActions.open(context, items[i], queue: items),
              );
            },
          ),
        );
      },
    );
  }

  Widget _teacherList(AppStrings s) => FutureBuilder<List<Teacher>>(
    future: _teachers,
    builder: (context, snap) {
      final teachers = snap.data;
      if (teachers == null) return const LoadingFooter();
      final featuredCount = teachers.where((t) => t.featured).length;
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: teachers.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) return SectionLabel(s.featuredTop);
          final t = teachers[i - 1];
          return _TeacherRow(
            teacher: t,
            showDivider: i - 1 != featuredCount - 1 || true,
          );
        },
      );
    },
  );
}

class _TeacherRow extends StatelessWidget {
  const _TeacherRow({required this.teacher, required this.showDivider});

  final Teacher teacher;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    return Semantics(
      button: true,
      label: teacher.displayName,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/teacher/${teacher.id}'),
        child: Column(
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 82),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  TeacherSeal(teacher: teacher, size: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: BText(
                                teacher.displayName,
                                size: 12.5,
                                weight: FontWeight.w500,
                                maxLines: 2,
                              ),
                            ),
                            if (teacher.featured) ...[
                              const SizedBox(width: 8),
                              SmallBadge(
                                label: s.featuredBadge,
                                background: c.goldSoft,
                                foreground: c.gold,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        BText(
                          s.teachingsCollections(
                            teacher.mediaCount,
                            teacher.collectionCount,
                          ),
                          size: 11,
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
            if (showDivider) const Hairline(indent: 80),
          ],
        ),
      ),
    );
  }
}
