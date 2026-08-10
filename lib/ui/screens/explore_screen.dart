import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/ui/components/async_message.dart';
import 'package:dhamma_echo/ui/components/track_tile.dart';
import 'package:flutter/material.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({required this.controller, super.key});
  final AppController controller;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.controller.audioRequest.query);
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        Text('Explore the Dhamma library', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        SearchBar(
          controller: _queryController,
          hintText: 'Search talks or teachers',
          leading: const Icon(Icons.search),
          trailing: <Widget>[
            if (_queryController.text.isNotEmpty)
              IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _queryController.clear();
                  controller.setAudioQuery('');
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              ),
          ],
          onSubmitted: controller.setAudioQuery,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ChoiceChip(label: const Text('All languages'), selected: controller.audioRequest.language == null, onSelected: (_) => controller.setLanguage(null)),
            ChoiceChip(label: const Text('Myanmar'), selected: controller.audioRequest.language == 'myanmar', onSelected: (_) => controller.setLanguage('myanmar')),
            ChoiceChip(label: const Text('English'), selected: controller.audioRequest.language == 'english', onSelected: (_) => controller.setLanguage('english')),
            ChoiceChip(label: const Text('All formats'), selected: controller.audioRequest.format == null, onSelected: (_) => controller.setFormat(null)),
            ChoiceChip(label: const Text('MP3'), selected: controller.audioRequest.format == 'mp3', onSelected: (_) => controller.setFormat('mp3')),
            ChoiceChip(label: const Text('WMA'), selected: controller.audioRequest.format == 'wma', onSelected: (_) => controller.setFormat('wma')),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          initialValue: controller.audioRequest.categoryId,
          decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
          items: <DropdownMenuItem<int?>>[
            const DropdownMenuItem<int?>(value: null, child: Text('All audio categories')),
            ...controller.categories.map((category) => DropdownMenuItem<int?>(value: category.id, child: Text('${category.name} (${category.audioCount})'))),
          ],
          onChanged: controller.setCategory,
        ),
        if (controller.audioRequest.teacherId != null || controller.audioRequest.collectionId != null) ...<Widget>[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: <Widget>[
              if (controller.audioRequest.teacherId != null)
                InputChip(label: const Text('Teacher filter'), onDeleted: controller.clearTeacherFilter),
              if (controller.audioRequest.collectionId != null)
                InputChip(label: const Text('Collection filter'), onDeleted: controller.clearCollectionFilter),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text('Showing ${controller.audioPage.items.length} of ${controller.audioPage.total} talks', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        if (controller.audioLoading)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
        else if (controller.audioError.isNotEmpty)
          AsyncMessage(icon: Icons.error_outline, title: 'Could not load talks', message: controller.audioError, actionLabel: 'Retry', onAction: controller.searchAudio)
        else if (controller.audioPage.items.isEmpty)
          const AsyncMessage(icon: Icons.search_off, title: 'No talks found', message: 'Try a different search or remove a filter.')
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: controller.audioPage.items.map((track) => TrackTile(controller: controller, track: track)).toList(growable: false)),
          ),
        if (controller.audioLoadMoreError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(children: <Widget>[Expanded(child: Text(controller.audioLoadMoreError)), TextButton(onPressed: () => controller.searchAudio(append: true), child: const Text('Retry'))]),
          ),
        if (controller.hasMoreAudio) ...<Widget>[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: controller.audioLoadingMore ? null : () => controller.searchAudio(append: true),
            icon: controller.audioLoadingMore ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.expand_more),
            label: Text(controller.audioLoadingMore ? 'Loading…' : 'Load ${_remaining(controller.audioPage.total, controller.audioPage.items.length, 50)} more talks'),
          ),
        ],
      ],
    );
  }

  int _remaining(int total, int shown, int batch) {
    final remaining = total - shown;
    return remaining < batch ? remaining : batch;
  }
}
