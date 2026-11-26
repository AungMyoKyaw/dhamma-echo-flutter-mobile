import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/media_url_policy.dart';
import '../../models/models.dart';
import '../../services/app_controller.dart';
import '../../theme/bagan_colors.dart';
import '../../theme/bagan_theme.dart';
import '../media_actions.dart';
import '../ui_ext.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';
import '../widgets/lucide_icon.dart';
import '../widgets/paged.dart';

class LegacyMediaDetailScreen extends StatefulWidget {
  const LegacyMediaDetailScreen({super.key, required this.mediaId});

  final int mediaId;

  @override
  State<LegacyMediaDetailScreen> createState() =>
      _LegacyMediaDetailScreenState();
}

class _LegacyMediaDetailScreenState extends State<LegacyMediaDetailScreen> {
  MediaItem? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final item = await context.read<AppController>().catalogue.getMedia(
      widget.mediaId,
    );
    if (!mounted) return;
    setState(() {
      _item = item;
      _loading = false;
    });
  }

  Future<void> _openBrowser(MediaItem item) async {
    final uri = MediaUrlPolicy.externalUri(item.url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) MediaActions.toast(context, context.s.cannotOpenLink);
    }
  }

  Future<void> _copyUrl(MediaItem item) async {
    final url = MediaUrlPolicy.externalUri(item.url)?.toString() ?? item.url;
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) MediaActions.toast(context, context.s.urlCopied);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    final item = _item;
    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: _loading
            ? const LoadingFooter()
            : item == null
            ? Column(
                children: [
                  BackBar(label: s.mediaDetail, fallback: '/browse'),
                  Expanded(
                    child: EmptyState(
                      icon: 'circle-alert',
                      title: s.nothingFound,
                      body: s.nothingFoundBody,
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  BackBar(label: s.mediaDetail, fallback: '/browse'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SmallBadge(
                          label: s.legacyBadge(item.formatLabel),
                          background: c.dangerSoft,
                          foreground: c.danger,
                        ),
                        const SizedBox(height: 14),
                        BText(
                          item.displayTitle,
                          size: 17,
                          serif: true,
                          weight: FontWeight.w700,
                        ),
                        if ((item.teacherName ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          BText(
                            item.teacherName!,
                            size: 12.5,
                            color: c.inkMuted,
                          ),
                        ],
                        const SizedBox(height: 20),
                        BaganCard(
                          color: c.dangerSoft,
                          borderColor: c.danger.withValues(alpha: 0.35),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LucideIcon(
                                'circle-alert',
                                size: 20,
                                color: c.danger,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    BText(
                                      s.playbackUnsupported,
                                      size: 13.5,
                                      weight: FontWeight.w600,
                                    ),
                                    const SizedBox(height: 6),
                                    BText(
                                      s.playbackUnsupportedBody,
                                      size: 12.5,
                                      color: c.inkMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        BaganButton(
                          label: s.openOriginal,
                          icon: 'external-link',
                          onTap: () => _openBrowser(item),
                        ),
                        const SizedBox(height: 10),
                        BaganButton(
                          label: s.copySourceUrl,
                          primary: false,
                          onTap: () => _copyUrl(item),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
