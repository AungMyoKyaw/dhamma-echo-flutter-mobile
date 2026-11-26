import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/bagan_colors.dart';
import '../../theme/bagan_theme.dart';
import '../ui_ext.dart';
import 'common.dart';
import 'lucide_icon.dart';
import 'mini_player.dart';

const tabPaths = ['/home', '/browse', '/search', '/library'];

class BaganBottomNav extends StatelessWidget {
  const BaganBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    final items = [
      ('house', s.tabHome),
      ('compass', s.tabBrowse),
      ('search', s.tabSearch),
      ('library', s.tabLibrary),
    ];
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.rule)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 6),
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == current,
                    label: items[i].$2,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 54,
                            height: 30,
                            decoration: BoxDecoration(
                              color: i == current
                                  ? c.lacquerSoft
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: LucideIcon(
                                items[i].$1,
                                size: 22,
                                color: i == current ? c.lacquer : c.inkMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          BText(
                            items[i].$2,
                            size: 10.5,
                            weight: i == current
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: i == current ? c.lacquer : c.inkMuted,
                            height: 1.2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page frame with mini-player + bottom navigation.
class ChromeScaffold extends StatelessWidget {
  const ChromeScaffold({
    super.key,
    required this.currentTab,
    required this.onTab,
    required this.body,
  });

  final int currentTab;
  final ValueChanged<int> onTab;
  final Widget body;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.c.paper,
    body: SafeArea(bottom: false, child: body),
    bottomNavigationBar: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MiniPlayer(),
        BaganBottomNav(current: currentTab, onSelect: onTab),
      ],
    ),
  );
}

/// Chrome for pushed detail pages: tapping a tab returns to that tab root.
class DetailChrome extends StatelessWidget {
  const DetailChrome({super.key, required this.currentTab, required this.body});

  final int currentTab;
  final Widget body;

  @override
  Widget build(BuildContext context) => ChromeScaffold(
    currentTab: currentTab,
    onTab: (i) => context.go(tabPaths[i]),
    body: body,
  );
}

class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.title,
    this.trailing,
    this.serifSize = 24,
  });

  final String title;
  final Widget? trailing;
  final double serifSize;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: BText(
            title,
            size: serifSize,
            serif: true,
            weight: FontWeight.w700,
            color: context.c.ink,
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class BackBar extends StatelessWidget {
  const BackBar({
    super.key,
    required this.label,
    this.fallback = '/home',
    this.trailing,
  });

  final String label;
  final String fallback;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 12, 0),
      child: Row(
        children: [
          Tappable(
            semanticLabel: label,
            onTap: () =>
                context.canPop() ? context.pop() : context.go(fallback),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LucideIcon('arrow-left', size: 20, color: c.lacquer),
                  const SizedBox(width: 8),
                  BText(
                    label,
                    size: 14,
                    weight: FontWeight.w600,
                    color: c.lacquer,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    this.icon,
    this.leading,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? icon;
  final Widget? leading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?leading,
            if (icon != null) LucideIcon(icon!, size: 36, color: c.inkSubtle),
            const SizedBox(height: 16),
            BText(
              title,
              size: 18,
              serif: true,
              weight: FontWeight.w700,
              align: TextAlign.center,
            ),
            const SizedBox(height: 8),
            BText(body, size: 13, color: c.inkMuted, align: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              BaganButton(label: actionLabel!, onTap: onAction, expand: false),
            ],
          ],
        ),
      ),
    );
  }
}
