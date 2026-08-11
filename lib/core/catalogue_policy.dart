import 'package:dhamma_echo/core/text_utils.dart';
import 'package:dhamma_echo/domain/models.dart';

const List<int> curatedFeaturedTeacherIds = <int>[16, 42, 40, 53, 61, 8];

int validatePositiveId(int id) {
  if (id <= 0) {
    throw ArgumentError.value(id, 'id', 'must be a positive integer');
  }
  return id;
}

int validateLimit(int limit) {
  if (limit < 1 || limit > 100) {
    throw ArgumentError.value(limit, 'limit', 'must be between 1 and 100');
  }
  return limit;
}

String? validateLanguage(String? language) {
  if (language == null) return null;
  if (language != 'myanmar' && language != 'english') {
    throw ArgumentError.value(
      language,
      'language',
      'unsupported language filter',
    );
  }
  return language;
}

String? validateFormat(String? format) {
  if (format == null) return null;
  if (format != 'mp3' && format != 'wma') {
    throw ArgumentError.value(format, 'format', 'unsupported format filter');
  }
  return format;
}

List<TeacherSummary> featuredTeachers(List<TeacherSummary> teachers) {
  final byId = <int, TeacherSummary>{
    for (final teacher in teachers) teacher.id: teacher,
  };
  final featured = <TeacherSummary>[];
  for (final id in curatedFeaturedTeacherIds) {
    final teacher = byId[id];
    if (teacher != null) featured.add(teacher);
  }
  return featured;
}

List<TeacherSummary> orderTeachersFeaturedFirst(List<TeacherSummary> teachers) {
  final featured = featuredTeachers(teachers);
  final featuredIds = curatedFeaturedTeacherIds.toSet();
  return <TeacherSummary>[
    ...featured,
    ...teachers.where((teacher) => !featuredIds.contains(teacher.id)),
  ];
}

void sortCollectionSummaries(List<CollectionSummary> collections) {
  collections.sort((left, right) {
    if (left.teacherId == null && right.teacherId != null) return 1;
    if (left.teacherId != null && right.teacherId == null) return -1;
    if (left.teacherId != null && right.teacherId != null) {
      final teacherOrder = _naturalCompare(left.teacherName, right.teacherName);
      if (teacherOrder != 0) return teacherOrder;
    }
    final nameOrder = _naturalCompare(left.name, right.name);
    return nameOrder != 0 ? nameOrder : left.id.compareTo(right.id);
  });
}

void sortTeacherCollections(List<CollectionSummary> collections) {
  collections.sort((left, right) {
    final nameOrder = _naturalCompare(left.name, right.name);
    return nameOrder != 0 ? nameOrder : left.id.compareTo(right.id);
  });
}

List<CollectionGroup> groupCollectionsByTeacher(List<CollectionSummary> items) {
  final groups = <CollectionGroup>[];
  for (final item in items) {
    final key = item.teacherId?.toString() ?? 'unknown';
    if (groups.isNotEmpty && groups.last.key == key) {
      final latest = groups.removeLast();
      groups.add(
        CollectionGroup(
          key: latest.key,
          name: latest.name,
          items: <CollectionSummary>[...latest.items, item],
        ),
      );
    } else {
      groups.add(
        CollectionGroup(
          key: key,
          name: item.teacherName.isEmpty ? 'Unknown teacher' : item.teacherName,
          items: <CollectionSummary>[item],
        ),
      );
    }
  }
  return groups;
}

int _naturalCompare(String left, String right) {
  final leftParts = _parts(left);
  final rightParts = _parts(right);
  final length = leftParts.length < rightParts.length
      ? leftParts.length
      : rightParts.length;
  for (var index = 0; index < length; index += 1) {
    final a = leftParts[index];
    final b = rightParts[index];
    final aNumber = int.tryParse(a);
    final bNumber = int.tryParse(b);
    final int comparison;
    if (aNumber != null && bNumber != null) {
      comparison = aNumber.compareTo(bNumber);
    } else {
      comparison = a.compareTo(b);
    }
    if (comparison != 0) return comparison;
  }
  return leftParts.length.compareTo(rightParts.length);
}

List<String> _parts(String value) {
  final normalized = normalizeText(value).replaceAll(' ', '').toLowerCase();
  return RegExp(r'\d+|\D+')
      .allMatches(normalized)
      .map((match) => match.group(0)!)
      .toList(growable: false);
}
