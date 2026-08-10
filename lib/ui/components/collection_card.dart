import 'package:dhamma_echo/domain/models.dart';
import 'package:flutter/material.dart';

class CollectionCard extends StatelessWidget {
  const CollectionCard({required this.collection, required this.onTap, super.key});

  final CollectionSummary collection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(collection.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(collection.teacherName, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Icon(Icons.headphones, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('${collection.audioCount} talks'),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
