import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/ui/components/teacher_card.dart';
import 'package:dhamma_echo/ui/screens/teacher_detail_screen.dart';
import 'package:flutter/material.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({required this.controller, super.key});
  final AppController controller;

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        Text('Learn from trusted voices', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        SearchBar(controller: _query, hintText: 'Search teachers', leading: const Icon(Icons.search), onSubmitted: widget.controller.searchTeachers),
        const SizedBox(height: 14),
        for (final teacher in widget.controller.teacherResults)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TeacherCard(
              teacher: teacher,
              onTap: () => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => TeacherDetailScreen(controller: widget.controller, teacher: teacher))),
            ),
          ),
      ],
    );
  }
}
