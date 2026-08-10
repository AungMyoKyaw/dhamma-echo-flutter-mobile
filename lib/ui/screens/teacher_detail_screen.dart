import 'dart:async';

import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/domain/models.dart';
import 'package:dhamma_echo/ui/components/async_message.dart';
import 'package:dhamma_echo/ui/components/collection_card.dart';
import 'package:dhamma_echo/ui/components/track_tile.dart';
import 'package:dhamma_echo/ui/screens/collection_detail_screen.dart';
import 'package:flutter/material.dart';

class TeacherDetailScreen extends StatefulWidget {
  const TeacherDetailScreen({required this.controller, required this.teacher, super.key});

  final AppController controller;
  final TeacherSummary teacher;

  @override
  State<TeacherDetailScreen> createState() => _TeacherDetailScreenState();
}

class _TeacherDetailScreenState extends State<TeacherDetailScreen> {
  late final Future<TeacherDetail> _detail;
  final List<AudioTrack> _talks = <AudioTrack>[];
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _detail = widget.controller.getTeacher(widget.teacher.id);
    unawaited(_loadTalks());
  }

  Future<void> _loadTalks({bool append = false}) async {
    if (append) {
      setState(() => _loadingMore = true);
    } else {
      setState(() => _loading = true);
    }
    try {
      final page = await widget.controller.teacherTalks(
        widget.teacher.id,
        offset: append ? _talks.length : 0,
      );
      if (!mounted) return;
      setState(() {
        if (!append) _talks.clear();
        final ids = _talks.map((track) => track.id).toSet();
        _talks.addAll(page.items.where((track) => !ids.contains(track.id)));
        _total = page.total;
        _error = '';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Teacher')),
        body: FutureBuilder<TeacherDetail>(
          future: _detail,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return AsyncMessage(
                icon: Icons.error_outline,
                title: 'Could not load teacher',
                message: snapshot.error.toString(),
              );
            }
            final detail = snapshot.requireData;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: <Widget>[
                Text(
                  detail.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (detail.nameMyanmar case final myanmar?) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(myanmar, style: Theme.of(context).textTheme.titleMedium),
                ],
                if (detail.title case final title?) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(title),
                ],
                if (detail.description case final description?) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(description),
                ],
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Text('${detail.audioCount} talks'),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await widget.controller.filterByTeacher(detail.id);
                        if (context.mounted) {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      },
                      icon: const Icon(Icons.filter_alt_outlined),
                      label: const Text('Explore filter'),
                    ),
                  ],
                ),
                if (detail.collections.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 24),
                  Text(
                    'Collections',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  for (final collection in detail.collections)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CollectionCard(
                        collection: collection,
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => CollectionDetailScreen(
                              controller: widget.controller,
                              collection: collection,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Talks',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text('Showing ${_talks.length} of $_total talks'),
                const SizedBox(height: 8),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error.isNotEmpty && _talks.isEmpty)
                  AsyncMessage(
                    icon: Icons.error_outline,
                    title: 'Could not load talks',
                    message: _error,
                    actionLabel: 'Retry',
                    onAction: _loadTalks,
                  )
                else
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: _talks
                          .map((track) => TrackTile(controller: widget.controller, track: track))
                          .toList(growable: false),
                    ),
                  ),
                if (_error.isNotEmpty && _talks.isNotEmpty)
                  Row(
                    children: <Widget>[
                      Expanded(child: Text(_error)),
                      TextButton(
                        onPressed: () => _loadTalks(append: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                if (_talks.length < _total) ...<Widget>[
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: _loadingMore ? null : () => _loadTalks(append: true),
                    child: Text(_loadingMore ? 'Loading…' : 'Load more talks'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
