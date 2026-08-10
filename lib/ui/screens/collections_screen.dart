import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/core/catalogue_policy.dart';
import 'package:dhamma_echo/domain/models.dart';
import 'package:dhamma_echo/ui/components/async_message.dart';
import 'package:dhamma_echo/ui/components/collection_card.dart';
import 'package:dhamma_echo/ui/screens/collection_detail_screen.dart';
import 'package:flutter/material.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({required this.controller, super.key});
  final AppController controller;

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.controller.collectionRequest.query);
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final groups = controller.collectionRequest.teacherId == null ? groupCollectionsByTeacher(controller.collectionPage.items) : const [];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        Text('Browse listening collections', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        SearchBar(
          controller: _queryController,
          hintText: 'Search collections',
          leading: const Icon(Icons.search),
          onSubmitted: controller.setCollectionQuery,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          initialValue: controller.collectionRequest.teacherId,
          decoration: const InputDecoration(labelText: 'Teacher', prefixIcon: Icon(Icons.person_outline)),
          items: <DropdownMenuItem<int?>>[
            const DropdownMenuItem<int?>(value: null, child: Text('All teachers')),
            ...controller.teachers.map((teacher) => DropdownMenuItem<int?>(value: teacher.id, child: Text(teacher.name))),
          ],
          onChanged: controller.setCollectionTeacher,
        ),
        const SizedBox(height: 14),
        Text('Showing ${controller.collectionPage.items.length} of ${controller.collectionPage.total} collections', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        if (controller.collectionsLoading)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
        else if (controller.collectionsError.isNotEmpty)
          AsyncMessage(icon: Icons.error_outline, title: 'Could not load collections', message: controller.collectionsError, actionLabel: 'Retry', onAction: controller.searchCollections)
        else if (controller.collectionPage.items.isEmpty)
          const AsyncMessage(icon: Icons.library_music_outlined, title: 'No collections found', message: 'Try another search or teacher.')
        else if (controller.collectionRequest.teacherId == null)
          for (final group in groups) ...<Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
              child: Text(group.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
            for (final collection in group.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CollectionCard(collection: collection, onTap: () => _open(context, collection)),
              ),
          ]
        else
          for (final collection in controller.collectionPage.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CollectionCard(collection: collection, onTap: () => _open(context, collection)),
            ),
        if (controller.collectionsLoadMoreError.isNotEmpty)
          Row(children: <Widget>[Expanded(child: Text(controller.collectionsLoadMoreError)), TextButton(onPressed: () => controller.searchCollections(append: true), child: const Text('Retry'))]),
        if (controller.hasMoreCollections) ...<Widget>[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: controller.collectionsLoadingMore ? null : () => controller.searchCollections(append: true),
            icon: controller.collectionsLoadingMore ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.expand_more),
            label: const Text('Load more collections'),
          ),
        ],
      ],
    );
  }

  void _open(BuildContext context, CollectionSummary collection) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => CollectionDetailScreen(controller: widget.controller, collection: collection)),
    );
  }
}
