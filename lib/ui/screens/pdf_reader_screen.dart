import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';
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
import '../widgets/lucide_icon.dart';
import '../widgets/paged.dart';

class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({super.key, required this.mediaId});

  final int mediaId;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  late final AppController _app = context.read<AppController>();
  final _pdfController = PdfViewerController();
  MediaItem? _item;
  String? _localPath;
  bool _loading = true;
  int _initialPage = 1;
  int _page = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    unawaited(_savePage());
    super.dispose();
  }

  Future<void> _load() async {
    final app = context.read<AppController>();
    final downloads = context.read<DownloadManager>();
    final item = await app.catalogue.getMedia(widget.mediaId);
    final progress = await app.userState.progressFor(widget.mediaId);
    if (!mounted) return;
    setState(() {
      _item = item;
      _localPath = item == null ? null : downloads.localPathFor(item.id);
      if (progress != null && progress.positionMs >= 1) {
        _initialPage = progress.positionMs;
        _page = progress.positionMs;
        if (progress.durationMs > 0) _totalPages = progress.durationMs;
      }
      _loading = false;
    });
  }

  Future<void> _savePage() async {
    if (_item == null || _page <= 0) return;
    await _app.userState.recordProgress(
      _item!.id,
      positionMs: _page,
      durationMs: _totalPages,
    );
    await _app.refreshHistory();
  }

  /// Warm sepia or dark inversion applied to rendered PDF pages.
  ColorFilter? _tintFilter(PdfTint tint) => switch (tint) {
    PdfTint.light => null,
    PdfTint.sepia => const ColorFilter.matrix([
      0.96,
      0.00,
      0.00,
      0,
      4,
      0.00,
      0.92,
      0.00,
      0,
      2,
      0.00,
      0.00,
      0.80,
      0,
      0,
      0.00,
      0.00,
      0.00,
      1,
      0,
    ]),
    PdfTint.dark => const ColorFilter.matrix([
      -0.88,
      0.00,
      0.00,
      0,
      240,
      0.00,
      -0.88,
      0.00,
      0,
      232,
      0.00,
      0.00,
      -0.86,
      0,
      218,
      0.00,
      0.00,
      0.00,
      1,
      0,
    ]),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    final app = context.watch<AppController>();
    final tint = app.settings.pdfTint;

    if (_loading) {
      return Scaffold(backgroundColor: c.paper, body: const LoadingFooter());
    }
    final item = _item;
    if (item == null || (_localPath == null && item.remoteUri == null)) {
      return Scaffold(
        backgroundColor: c.paper,
        body: SafeArea(
          child: Column(
            children: [
              BackBar(label: s.ebooks, fallback: '/browse?kind=ebook'),
              Expanded(
                child: EmptyState(
                  icon: 'book-open',
                  title: s.readerError,
                  body: s.nothingFoundBody,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final (canvasBg, chromeBg, borderCol, inkCol) = switch (tint) {
      PdfTint.light => (c.paper, c.surface, c.rule, c.ink),
      PdfTint.sepia => (
        PdfSepia.canvas,
        PdfSepia.chrome,
        PdfSepia.border,
        PdfSepia.ink,
      ),
      PdfTint.dark => (
        BaganColors.dark.paper,
        BaganColors.dark.surface,
        BaganColors.dark.rule,
        BaganColors.dark.ink,
      ),
    };

    final saved = app.isSaved(item.id);
    final dlRecord = context.select<DownloadManager, DownloadRecord?>(
      (m) => m.recordFor(item.id),
    );
    final dlStatus = dlRecord?.status;
    final offline = dlStatus == DownloadStatus.completed;
    final downloading =
        dlStatus == DownloadStatus.queued ||
        dlStatus == DownloadStatus.downloading;

    final params = PdfViewerParams(
      backgroundColor: canvasBg,
      pageDropShadow: null,
      onViewerReady: (doc, ctrl) {
        if (!mounted) return;
        setState(() {
          _totalPages = doc.pages.length;
          _page = (ctrl.pageNumber ?? _initialPage).clamp(1, doc.pages.length);
        });
      },
      onPageChanged: (page) {
        if (!mounted || page == null) return;
        setState(() => _page = page);
        unawaited(_savePage());
      },
      loadingBannerBuilder: (ctx, bytesDownloaded, totalBytes) {
        final hasTotal = totalBytes != null && totalBytes > 0;
        final frac = hasTotal
            ? (bytesDownloaded / totalBytes).clamp(0.0, 1.0)
            : null;
        final pct = frac != null ? ' ${(frac * 100).round()}%' : '';
        final sizeText = hasTotal
            ? '${formatBytes(bytesDownloaded)} / ${formatBytes(totalBytes)}'
            : (bytesDownloaded > 0 ? formatBytes(bytesDownloaded) : s.loading);
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: chromeBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BText(
                    '${s.loading}$pct',
                    size: 14,
                    weight: FontWeight.w600,
                    color: inkCol,
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: frac,
                      minHeight: 6,
                      color: c.lacquer,
                      backgroundColor: borderCol,
                    ),
                  ),
                  const SizedBox(height: 8),
                  BText(
                    sizeText,
                    size: 11.5,
                    color: inkCol.withValues(alpha: 0.75),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      errorBannerBuilder: (ctx, err, stack, documentRef) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: EmptyState(
            icon: 'circle-alert',
            title: s.readerError,
            body: err.toString(),
          ),
        ),
      ),
    );

    final viewer = _localPath != null
        ? PdfViewer.file(
            _localPath!,
            controller: _pdfController,
            initialPageNumber: _initialPage,
            params: params,
          )
        : PdfViewer.uri(
            item.remoteUri!,
            controller: _pdfController,
            initialPageNumber: _initialPage,
            params: params,
          );

    final filter = _tintFilter(tint);

    return Scaffold(
      backgroundColor: canvasBg,
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: chromeBg,
              border: Border(bottom: BorderSide(color: borderCol)),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 52,
                child: Row(
                  children: [
                    Tappable(
                      semanticLabel: s.back,
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go('/browse?kind=ebook'),
                      child: LucideIcon('arrow-left', size: 22, color: inkCol),
                    ),
                    Expanded(
                      child: BText(
                        item.displayTitle,
                        size: 13,
                        weight: FontWeight.w600,
                        color: inkCol,
                        maxLines: 1,
                      ),
                    ),
                    Tappable(
                      semanticLabel: downloading ? s.cancel : s.download,
                      onTap: offline
                          ? null
                          : downloading
                          ? () =>
                                context.read<DownloadManager>().cancel(item.id)
                          : () => MediaActions.download(context, item),
                      child: downloading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                value: dlRecord?.progress,
                                strokeWidth: 2.2,
                                color: c.lacquer,
                                backgroundColor: borderCol,
                              ),
                            )
                          : LucideIcon(
                              offline ? 'check-circle-2' : 'download',
                              size: 20,
                              color: offline ? c.sage : inkCol,
                            ),
                    ),
                    Tappable(
                      semanticLabel: s.save,
                      onTap: () => app.toggleSaved(item.id),
                      child: LucideIcon(
                        'heart',
                        size: 20,
                        color: saved ? c.lacquer : inkCol,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: filter == null
                ? viewer
                : ColorFiltered(colorFilter: filter, child: viewer),
          ),
          Container(
            decoration: BoxDecoration(
              color: chromeBg,
              border: Border(top: BorderSide(color: borderCol)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_totalPages > 1)
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          activeTrackColor: c.lacquer,
                          inactiveTrackColor: borderCol,
                          thumbColor: c.lacquer,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7,
                          ),
                        ),
                        child: Slider(
                          min: 1,
                          max: _totalPages.toDouble(),
                          value: _page.clamp(1, _totalPages).toDouble(),
                          onChanged: (v) {
                            final p = v.round();
                            setState(() => _page = p);
                            if (_pdfController.isReady) {
                              unawaited(_pdfController.goToPage(pageNumber: p));
                            }
                          },
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: BText(
                            _totalPages > 0
                                ? s.pageOf(_page, _totalPages)
                                : s.loading,
                            size: 12,
                            color: inkCol,
                            weight: FontWeight.w500,
                          ),
                        ),
                        _TintDot(
                          color: BaganColors.light.surface,
                          selected: tint == PdfTint.light,
                          label: s.tintLight,
                          border: borderCol,
                          onTap: () => app.setPdfTint(PdfTint.light),
                        ),
                        const SizedBox(width: 8),
                        _TintDot(
                          color: PdfSepia.sheet,
                          selected: tint == PdfTint.sepia,
                          label: s.tintSepia,
                          border: borderCol,
                          onTap: () => app.setPdfTint(PdfTint.sepia),
                        ),
                        const SizedBox(width: 8),
                        _TintDot(
                          color: BaganColors.dark.surface,
                          selected: tint == PdfTint.dark,
                          label: s.tintDark,
                          border: borderCol,
                          onTap: () => app.setPdfTint(PdfTint.dark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TintDot extends StatelessWidget {
  const _TintDot({
    required this.color,
    required this.selected,
    required this.label,
    required this.border,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final String label;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? c.lacquer : border,
                  width: selected ? 2.5 : 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
