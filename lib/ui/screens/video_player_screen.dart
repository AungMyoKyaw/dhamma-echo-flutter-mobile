import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../data/media_url_policy.dart';
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
import '../widgets/echo_emblem.dart';
import '../widgets/lucide_icon.dart';
import '../widgets/media_row.dart';
import '../widgets/paged.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.mediaId});

  final int mediaId;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final AppController _app = context.read<AppController>();
  MediaItem? _item;
  List<MediaItem> _related = const [];
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _error = false;
  bool _fullscreen = false;
  bool _disposed = false;
  double _speed = 1.0;
  DateTime _lastSave = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  @override
  void didUpdateWidget(VideoPlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaId != widget.mediaId) {
      unawaited(_disposeController().then((_) => _init()));
    }
  }

  Future<void> _disposeController() async {
    final ctrl = _controller;
    _controller = null;
    if (ctrl == null) return;
    ctrl.removeListener(_onTick);
    if (ctrl.value.isInitialized) {
      unawaited(ctrl.pause());
      await _saveProgressFor(_item, ctrl);
    }
    await ctrl.dispose();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_fullscreen) {
      unawaited(_exitFullscreenSystem());
    }
    unawaited(_disposeController());
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final audio = context.read<AudioPlaybackController>();
    final downloads = context.read<DownloadManager>();
    if (audio.playing) unawaited(audio.togglePlay());
    final item = await _app.catalogue.getMedia(widget.mediaId);
    if (!mounted || _disposed) return;
    if (item == null) {
      setState(() {
        _item = null;
        _loading = false;
      });
      return;
    }
    _item = item;
    _speed = _app.settings.playbackSpeed;
    unawaited(
      _app.catalogue.getRelatedVideos(item.teacherId, item.id).then((list) {
        if (mounted && !_disposed) setState(() => _related = list);
      }),
    );

    final localPath = downloads.localPathFor(item.id);
    final remote = item.remoteUri;
    if (localPath == null && remote == null) {
      setState(() {
        _error = true;
        _loading = false;
      });
      return;
    }
    final ctrl = localPath != null
        ? VideoPlayerController.file(File(localPath))
        : VideoPlayerController.networkUrl(remote!);
    _controller = ctrl;
    try {
      await ctrl.initialize();
      if (_disposed || _controller != ctrl) {
        await ctrl.dispose();
        return;
      }
      final saved = await _app.userState.progressFor(item.id);
      if (_disposed || _controller != ctrl) {
        await ctrl.dispose();
        return;
      }
      if (saved != null && saved.positionMs > 5000) {
        final dur = ctrl.value.duration.inMilliseconds;
        if (dur == 0 || saved.positionMs < dur - 10000) {
          await ctrl.seekTo(Duration(milliseconds: saved.positionMs));
        }
      }
      await ctrl.setPlaybackSpeed(_speed);
      ctrl.addListener(_onTick);
      await ctrl.play();
      if (mounted && !_disposed) setState(() => _loading = false);
    } on Object catch (e, s) {
      debugPrint('Video init failed: $e\n$s');
      if (mounted && !_disposed) {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    }
  }

  void _onTick() {
    if (!mounted || _disposed) return;
    setState(() {});
    final ctrl = _controller;
    if (ctrl != null &&
        ctrl.value.isPlaying &&
        DateTime.now().difference(_lastSave) > const Duration(seconds: 5)) {
      unawaited(_saveProgress());
    }
  }

  Future<void> _saveProgress() => _saveProgressFor(_item, _controller);

  Future<void> _saveProgressFor(
    MediaItem? item,
    VideoPlayerController? ctrl,
  ) async {
    if (item == null || ctrl == null || !ctrl.value.isInitialized) return;
    _lastSave = DateTime.now();
    await _app.userState.recordProgress(
      item.id,
      positionMs: ctrl.value.position.inMilliseconds,
      durationMs: ctrl.value.duration.inMilliseconds,
    );
    await _app.refreshHistory();
  }

  Future<void> _toggleFullscreen() async {
    final next = !_fullscreen;
    setState(() => _fullscreen = next);
    if (next) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await _exitFullscreenSystem();
    }
  }

  Future<void> _exitFullscreenSystem() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> _seekBy(Duration delta) async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final max = ctrl.value.duration;
    var target = ctrl.value.position + delta;
    if (target < Duration.zero) target = Duration.zero;
    if (max > Duration.zero && target > max) target = max;
    await ctrl.seekTo(target);
  }

  Future<void> _cycleSpeed() async {
    const speeds = AudioPlaybackController.speeds;
    final nextIndex =
        (speeds.indexWhere((v) => (v - _speed).abs() < 0.01) + 1) %
        speeds.length;
    final next = speeds[nextIndex];
    setState(() => _speed = next);
    await _controller?.setPlaybackSpeed(next);
  }

  Future<void> _openSource(MediaItem item) async {
    final uri = MediaUrlPolicy.externalUri(item.url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) MediaActions.toast(context, context.s.cannotOpenLink);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    final item = _item;
    if (_loading && item == null) {
      return Scaffold(backgroundColor: c.paper, body: const LoadingFooter());
    }
    if (item == null) {
      return Scaffold(
        backgroundColor: c.paper,
        body: SafeArea(
          child: Column(
            children: [
              BackBar(label: s.video, fallback: '/browse?kind=video'),
              Expanded(
                child: EmptyState(
                  icon: 'video',
                  title: s.nothingFound,
                  body: s.nothingFoundBody,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_fullscreen) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_toggleFullscreen());
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: _videoSurface(c, s, fullscreen: true),
        ),
      );
    }

    final saved = context.select<AppController, bool>(
      (a) => a.isSaved(item.id),
    );
    final dlRecord = context.select<DownloadManager, DownloadRecord?>(
      (m) => m.recordFor(item.id),
    );
    final dlStatus = dlRecord?.status;
    final offline = dlStatus == DownloadStatus.completed;
    final downloading =
        dlStatus == DownloadStatus.queued ||
        dlStatus == DownloadStatus.downloading;
    final dlPct = dlRecord?.progress != null
        ? '${(dlRecord!.progress! * 100).round()}% · '
        : '';
    final isMyanmar = item.language.toLowerCase() == 'myanmar';

    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            BackBar(label: s.video, fallback: '/browse?kind=video'),
            const SizedBox(height: 8),
            _videoSurface(c, s),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SmallBadge(
                        label: s.videoMp4,
                        background: c.goldSoft,
                        foreground: c.gold,
                      ),
                      const SizedBox(width: 8),
                      SmallBadge(
                        label: isMyanmar
                            ? s.languageMyanmarBadge
                            : s.languageEnglishBadge,
                        background: c.surfaceSoft,
                        foreground: c.inkMuted,
                      ),
                      if (offline) ...[
                        const SizedBox(width: 8),
                        SmallBadge(
                          label: s.offlineBadge,
                          background: c.sageSoft,
                          foreground: c.sage,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  BText(
                    item.displayTitle,
                    size: 16.5,
                    serif: true,
                    weight: FontWeight.w700,
                  ),
                  if ((item.teacherName ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: item.teacherId == null
                          ? null
                          : () => context.push('/teacher/${item.teacherId}'),
                      child: BText(
                        item.teacherName!,
                        size: 12,
                        color: c.inkMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: BaganButton(
                          label: offline
                              ? s.readyOffline
                              : downloading
                              ? '$dlPct${s.cancel}'
                              : s.downloadMp4,
                          icon: offline ? 'check-circle-2' : 'download',
                          onTap: offline
                              ? null
                              : downloading
                              ? () => context.read<DownloadManager>().cancel(
                                  item.id,
                                )
                              : () => MediaActions.download(context, item),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: BaganButton(
                          label: saved ? s.unsave : s.save,
                          icon: 'heart',
                          primary: false,
                          onTap: () => context
                              .read<AppController>()
                              .toggleSaved(item.id),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: BaganButton(
                          label: s.source,
                          icon: 'external-link',
                          primary: false,
                          onTap: () => _openSource(item),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_related.isNotEmpty) ...[
              SectionLabel(
                s.moreVideos,
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 6),
              ),
              for (final rel in _related)
                MediaRow(
                  item: rel,
                  onTap: () => context.pushReplacement('/video/${rel.id}'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _videoSurface(BaganColors c, AppStrings s, {bool fullscreen = false}) {
    final ctrl = _controller;
    final initialized = ctrl != null && ctrl.value.isInitialized;
    final pos = initialized ? ctrl.value.position : Duration.zero;
    final dur = initialized ? ctrl.value.duration : Duration.zero;
    final playing = initialized && ctrl.value.isPlaying;
    final frac = dur.inMilliseconds > 0
        ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final videoLayer = initialized
        ? FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: ctrl.value.size.width,
              height: ctrl.value.size.height,
              child: VideoPlayer(ctrl),
            ),
          )
        : const EchoEmblem(size: 72);

    final centerControls = _loading
        ? CircularProgressIndicator(strokeWidth: 2.5, color: c.lacquer)
        : _error
        ? Padding(
            padding: const EdgeInsets.all(16),
            child: SmallBadge(
              label: s.playbackError,
              background: c.dangerSoft,
              foreground: c.danger,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tappable(
                semanticLabel: 'Back 15s',
                onTap: () => _seekBy(const Duration(seconds: -15)),
                child: const LucideIcon(
                  'rotate-ccw',
                  size: 24,
                  color: Color(0xFFFAF8F3),
                ),
              ),
              const SizedBox(width: 24),
              Semantics(
                button: true,
                label: playing ? 'Pause' : 'Play',
                child: GestureDetector(
                  onTap: () => initialized
                      ? (playing ? ctrl.pause() : ctrl.play())
                      : null,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: c.lacquer.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: LucideIcon(
                        playing ? 'pause' : 'play',
                        size: 24,
                        color: c.onLacquer,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Tappable(
                semanticLabel: 'Forward 15s',
                onTap: () => _seekBy(const Duration(seconds: 15)),
                child: const LucideIcon(
                  'refresh-ccw',
                  size: 24,
                  color: Color(0xFFFAF8F3),
                ),
              ),
            ],
          );

    final controlsBar = Container(
      color: fullscreen ? const Color(0xCC141210) : const Color(0xFF1D1A17),
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: c.lacquer,
              inactiveTrackColor: const Color(0xFF332E28),
              thumbColor: c.lacquer,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: frac,
              onChanged: initialized
                  ? (v) => ctrl.seekTo(
                      Duration(milliseconds: (v * dur.inMilliseconds).round()),
                    )
                  : null,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BText(
                '${formatDuration(pos)} / ${formatDuration(dur)}',
                size: 11,
                color: const Color(0xFFA69E92),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tappable(
                    semanticLabel: s.speed,
                    minSize: 36,
                    onTap: _cycleSpeed,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: BText(
                        '$_speed×',
                        size: 11,
                        color: const Color(0xFFF3EFE8),
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tappable(
                    semanticLabel: s.fullscreen,
                    minSize: 36,
                    onTap: _toggleFullscreen,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LucideIcon(
                          fullscreen ? 'minimize' : 'maximize',
                          size: 16,
                          color: const Color(0xFFF3EFE8),
                        ),
                        const SizedBox(width: 4),
                        BText(
                          fullscreen ? s.back : s.fullscreen,
                          size: 11,
                          color: const Color(0xFFF3EFE8),
                          weight: FontWeight.w500,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    if (fullscreen) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Center(child: videoLayer),
          Center(child: centerControls),
          Positioned(
            top: 8,
            left: 12,
            child: SafeArea(
              child: Tappable(
                semanticLabel: s.back,
                onTap: _toggleFullscreen,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xB3141210),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LucideIcon(
                        'arrow-left',
                        size: 18,
                        color: Color(0xFFF3EFE8),
                      ),
                      const SizedBox(width: 6),
                      BText(
                        s.back,
                        size: 12,
                        color: const Color(0xFFF3EFE8),
                        weight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(top: false, child: controlsBar),
          ),
        ],
      );
    }

    return Container(
      color: const Color(0xFF141210),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              children: [videoLayer, centerControls],
            ),
          ),
          controlsBar,
        ],
      ),
    );
  }
}
