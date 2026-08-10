import 'package:dhamma_echo/core/catalogue_policy.dart';
import 'package:dhamma_echo/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validation accepts supported filters and rejects bad input', () {
    expect(validatePositiveId(1), 1);
    expect(() => validatePositiveId(0), throwsArgumentError);
    expect(validateLimit(100), 100);
    expect(() => validateLimit(101), throwsArgumentError);
    expect(() => validateLanguage('thai'), throwsArgumentError);
    expect(() => validateFormat('aac'), throwsArgumentError);
  });

  test('featured teachers preserve curated order and skip missing ids', () {
    const teachers = <TeacherSummary>[
      TeacherSummary(id: 42, name: 'B', audioCount: 1),
      TeacherSummary(id: 999, name: 'Other', audioCount: 1),
      TeacherSummary(id: 16, name: 'A', audioCount: 1),
    ];
    expect(featuredTeachers(teachers).map((t) => t.id), [16, 42]);
    expect(orderTeachersFeaturedFirst(teachers).map((t) => t.id), [16, 42, 999]);
  });

  test('collections sort naturally inside teacher groups with unknown last', () {
    final items = <CollectionSummary>[
      const CollectionSummary(id: 1, name: 'Course 10', teacherId: 16, teacherName: 'A', audioCount: 1),
      const CollectionSummary(id: 2, name: 'Course 2', teacherId: 16, teacherName: 'A', audioCount: 1),
      const CollectionSummary(id: 3, name: 'Unknown', teacherId: null, teacherName: 'Unknown teacher', audioCount: 1),
    ];
    sortCollectionSummaries(items);
    expect(items.map((e) => e.id), [2, 1, 3]);
    final groups = groupCollectionsByTeacher(items);
    expect(groups.map((e) => e.name), ['A', 'Unknown teacher']);
  });
}
