import 'package:material_ui/material_ui.dart';

import '../../theme/bagan_colors.dart';

/// Offset-based pager for lazy lists.
class Paged<T> extends ChangeNotifier {
  Paged(this.fetch, {this.pageSize = 40});

  final Future<List<T>> Function(int offset, int limit) fetch;
  final int pageSize;
  final List<T> items = [];
  bool loading = false;
  bool done = false;
  bool failed = false;
  bool _disposed = false;
  int _generation = 0;

  bool get initialLoading => loading && items.isEmpty;
  bool get empty => !loading && done && items.isEmpty && !failed;

  Future<void> loadMore() async {
    if (loading || done) return;
    loading = true;
    failed = false;
    final gen = _generation;
    _notify();
    try {
      final page = await fetch(items.length, pageSize);
      if (gen != _generation) return;
      items.addAll(page);
      if (page.length < pageSize) done = true;
    } on Object catch (e, s) {
      debugPrint('Paged load failed: $e\n$s');
      if (gen != _generation) return;
      failed = true;
      done = true;
    } finally {
      if (gen == _generation) {
        loading = false;
        _notify();
      }
    }
  }

  Future<void> reset() async {
    _generation++;
    items.clear();
    loading = false;
    done = false;
    failed = false;
    await loadMore();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Calls [onNearEnd] when the scroll position is close to the bottom.
class NearEndListener extends StatelessWidget {
  const NearEndListener({
    super.key,
    required this.onNearEnd,
    required this.child,
  });

  final VoidCallback onNearEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 800) {
            onNearEnd();
          }
          return false;
        },
        child: child,
      );
}

class LoadingFooter extends StatelessWidget {
  const LoadingFooter({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: context.c.lacquer,
        ),
      ),
    ),
  );
}
