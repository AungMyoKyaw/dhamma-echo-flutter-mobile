import 'dart:async';

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
import '../widgets/lucide_icon.dart';
import '../widgets/media_row.dart';
import '../widgets/paged.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  String _query = '';
  MediaKind? _kind;
  Paged<MediaItem>? _paged;
  int _count = 0;
  bool _showLegacy = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final showLegacy = context.watch<AppController>().settings.showLegacy;
    if (showLegacy != _showLegacy) {
      _showLegacy = showLegacy;
      _run();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _paged?.dispose();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _query = value.trim();
      _run();
    });
    setState(() {});
  }

  void _run() {
    final repo = context.read<AppController>().catalogue;
    _paged?.dispose();
    if (_query.isEmpty) {
      setState(() {
        _paged = null;
        _count = 0;
      });
      return;
    }
    final query = _query;
    final kind = _kind;
    final showLegacy = _showLegacy;
    final paged = Paged<MediaItem>(
      (offset, limit) => repo.searchMedia(
        query,
        kind: kind,
        showLegacy: showLegacy,
        offset: offset,
        limit: limit,
      ),
    );
    _paged = paged;
    unawaited(paged.loadMore());
    unawaited(
      repo.countMedia(kind: kind, showLegacy: showLegacy, query: query).then((
        n,
      ) {
        if (mounted && _paged == paged) setState(() => _count = n);
      }),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabHeader(title: s.search),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _focus.hasFocus ? c.lacquer : c.rule,
                width: _focus.hasFocus ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                LucideIcon('search', size: 20, color: c.inkMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    onChanged: _onChanged,
                    onTap: () => setState(() {}),
                    textInputAction: TextInputAction.search,
                    cursorColor: c.lacquer,
                    style: BaganType.style(
                      _controller.text,
                      size: 14,
                      color: c.ink,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: s.searchHint,
                      hintStyle: BaganType.style(
                        s.searchHint,
                        size: 14,
                        color: c.inkSubtle,
                      ),
                    ),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  Tappable(
                    semanticLabel: s.clear,
                    minSize: 32,
                    onTap: () {
                      _controller.clear();
                      _query = '';
                      _run();
                    },
                    child: LucideIcon('x', size: 18, color: c.inkMuted),
                  ),
              ],
            ),
          ),
        ),
        PillRow(
          children: [
            for (final (k, label) in [
              (null, s.filterAll),
              (MediaKind.audio, s.kindAudio),
              (MediaKind.video, s.kindVideo),
              (MediaKind.ebook, s.kindEbooks),
            ])
              FilterPill(
                label: label,
                selected: _kind == k,
                onTap: () {
                  _kind = k;
                  _run();
                },
              ),
          ],
        ),
        if (_paged != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: BText(
              s.resultsInCatalogue(_count),
              size: 11.5,
              color: c.inkMuted,
            ),
          ),
        Expanded(child: _results(s)),
      ],
    );
  }

  Widget _results(AppStrings s) {
    final paged = _paged;
    if (paged == null) {
      return EmptyState(icon: 'search', title: s.search, body: s.searchPrompt);
    }
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
        return NearEndListener(
          onNearEnd: paged.loadMore,
          child: ListView.builder(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(bottom: 24),
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
}
