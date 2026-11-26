import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/catalogue_repository.dart';
import '../../models/models.dart';
import '../../services/app_controller.dart';
import '../../services/audio_playback_controller.dart';
import '../../theme/bagan_colors.dart';
import '../../theme/bagan_theme.dart';
import '../ui_ext.dart';
import '../widgets/common.dart';
import '../widgets/echo_emblem.dart';
import '../widgets/lucide_icon.dart';
import '../widgets/teacher_seal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<List<Teacher>> _teachers;
  late final Future<List<CollectionSummary>> _collections;

  @override
  void initState() {
    super.initState();
    final repo = context.read<AppController>().catalogue;
    _teachers = repo.getFeaturedTeachers();
    _collections = repo.getRandomCollections(limit: 4);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    final app = context.watch<AppController>();
    final counts = app.counts;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
          child: Row(
            children: [
              const EchoEmblem(size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: BText(
                  s.appName,
                  size: s.my ? 17 : 20,
                  serif: true,
                  weight: FontWeight.w700,
                ),
              ),
              Tappable(
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
            ],
          ),
        ),
        SectionLabel(s.continueListening),
        const _ContinueCard(),
        SectionLabel(s.exploreArchive),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ArchiveTile(
                      icon: 'headphones',
                      tint: c.lacquerSoft,
                      title: s.audioTalks,
                      subtitle: s.audioCountLine(counts.audio),
                      onTap: () => context.go('/browse?kind=audio'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ArchiveTile(
                      icon: 'video',
                      tint: c.goldSoft,
                      title: s.videoTalks,
                      subtitle: s.videoCountLine(counts.video),
                      onTap: () => context.go('/browse?kind=video'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ArchiveTile(
                      icon: 'book-open',
                      tint: c.sageSoft,
                      title: s.ebooks,
                      subtitle: s.ebookCountLine(counts.ebook),
                      onTap: () => context.go('/browse?kind=ebook'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ArchiveTile(
                      icon: 'book',
                      tint: c.surfaceSoft,
                      title: s.abhidhamma,
                      subtitle: s.abhidhammaCountLine(counts.abhidhamma),
                      onTap: () =>
                          context.go('/browse?kind=audio&abhidhamma=1'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: BText(
                  s.featuredTeachers,
                  size: 10.5,
                  weight: FontWeight.w600,
                  color: c.inkMuted,
                  letterSpacing: s.my ? 0 : 0.9,
                ),
              ),
              Tappable(
                onTap: () => context.go('/browse?kind=teachers'),
                semanticLabel: s.viewAll,
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: BText(
                    s.viewAll,
                    size: 11,
                    weight: FontWeight.w600,
                    color: c.lacquer,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 112,
          child: FutureBuilder<List<Teacher>>(
            future: _teachers,
            builder: (context, snap) {
              final teachers = snap.data ?? const <Teacher>[];
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: teachers.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _TeacherChip(teacher: teachers[i]),
              );
            },
          ),
        ),
        SectionLabel(s.randomCollections),
        FutureBuilder<List<CollectionSummary>>(
          future: _collections,
          builder: (context, snap) {
            final list = snap.data ?? const <CollectionSummary>[];
            return Column(
              children: [
                for (final col in list)
                  Tappable(
                    onTap: () => context.push('/collection/${col.id}'),
                    semanticLabel: col.name,
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: BText(
                              [
                                col.name,
                                if ((col.teacherName ?? '').isNotEmpty)
                                  col.teacherName!,
                              ].join(' · '),
                              size: 11.5,
                              weight: FontWeight.w500,
                              maxLines: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          BText(
                            s.itemsCount(col.itemCount),
                            size: 10.5,
                            color: c.inkMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    final resume = context
        .select<AppController, ({MediaItem media, HistoryEntry entry})?>(
          (a) => a.resume,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: BaganCard(
        padding: const EdgeInsets.all(14),
        child: resume == null
            ? Row(
                children: [
                  const EchoEmblem(size: 40),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BText(
                          s.nothingToResume,
                          size: 13,
                          weight: FontWeight.w600,
                        ),
                        const SizedBox(height: 2),
                        BText(
                          s.nothingToResumeBody,
                          size: 11,
                          color: c.inkMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : _ResumeBody(media: resume.media, entry: resume.entry),
      ),
    );
  }
}

class _ResumeBody extends StatelessWidget {
  const _ResumeBody({required this.media, required this.entry});

  final MediaItem media;
  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _resume(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SmallBadge(
                      label: '${media.formatLabel} · ${s.resumeBadge}',
                      background: c.lacquerSoft,
                      foreground: c.lacquer,
                    ),
                    const SizedBox(height: 8),
                    BText(
                      media.displayTitle,
                      size: 13,
                      weight: FontWeight.w500,
                      maxLines: 2,
                    ),
                    BText(
                      media.teacherName ?? '',
                      size: 11,
                      color: c.inkMuted,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: c.lacquer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: LucideIcon('play', size: 22, color: c.onLacquer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: entry.fraction,
              minHeight: 5,
              color: c.lacquer,
              backgroundColor: c.surfaceSoft,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resume(BuildContext context) async {
    switch (media.kind) {
      case MediaKind.audio:
        await context.read<AudioPlaybackController>().playItem(media);
      case MediaKind.video:
        context.push('/video/${media.id}');
      case MediaKind.ebook:
        context.push('/reader/${media.id}');
    }
  }
}

class _ArchiveTile extends StatelessWidget {
  const _ArchiveTile({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.rule),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: LucideIcon(icon, size: 22, color: c.ink)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BText(
                      title,
                      size: 12.5,
                      weight: FontWeight.w600,
                      maxLines: 1,
                    ),
                    BText(subtitle, size: 10.5, color: c.inkMuted, maxLines: 1),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherChip extends StatelessWidget {
  const _TeacherChip({required this.teacher});

  final Teacher teacher;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: teacher.displayName,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/teacher/${teacher.id}'),
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            const SizedBox(height: 4),
            TeacherSeal(teacher: teacher),
            const SizedBox(height: 6),
            BText(
              teacher.displayName,
              size: 10,
              maxLines: 2,
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Used by tests and the router to check the canonical featured order.
List<int> get featuredTeacherOrder => CatalogueRepository.featuredTeacherIds;
