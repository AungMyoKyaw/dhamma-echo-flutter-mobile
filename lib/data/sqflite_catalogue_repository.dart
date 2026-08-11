import 'package:dhamma_echo/core/catalogue_policy.dart';
import 'package:dhamma_echo/core/media_url_policy.dart';
import 'package:dhamma_echo/core/text_utils.dart';
import 'package:dhamma_echo/data/catalogue_repository.dart';
import 'package:dhamma_echo/domain/models.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteCatalogueRepository implements CatalogueRepository {
  SqfliteCatalogueRepository(this._database);

  final Database _database;

  @override
  Future<CatalogueSummary> getSummary() async {
    final rows = await _database.rawQuery('''
      SELECT
        SUM(CASE WHEN type = 'audio' THEN 1 ELSE 0 END) AS total_audio,
        (SELECT COUNT(*) FROM teachers) AS total_teachers,
        SUM(CASE WHEN type = 'audio' AND language = 'myanmar' THEN 1 ELSE 0 END) AS myanmar_audio,
        SUM(CASE WHEN type = 'audio' AND language = 'english' THEN 1 ELSE 0 END) AS english_audio
      FROM media
    ''');
    final row = rows.single;
    return CatalogueSummary(
      totalAudio: _integer(row['total_audio']),
      totalTeachers: _integer(row['total_teachers']),
      myanmarAudio: _integer(row['myanmar_audio']),
      englishAudio: _integer(row['english_audio']),
    );
  }

  @override
  Future<List<AudioCategory>> listAudioCategories() async {
    final rows = await _database.rawQuery('''
      SELECT c.id, c.name, c.language, COUNT(m.id) AS audio_count
      FROM categories c
      JOIN media m ON m.category_id = c.id AND m.type = 'audio'
      WHERE c.type IN ('audio', 'abhidhamma')
      GROUP BY c.id, c.name, c.language
      HAVING COUNT(m.id) > 0
      ORDER BY c.id
    ''');
    return rows
        .map((row) {
          return AudioCategory(
            id: _integer(row['id']),
            name: _normalizedOr(row['name'], 'Uncategorized audio'),
            language: normalizeText(_string(row['language'])).toLowerCase(),
            audioCount: _integer(row['audio_count']),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<TeacherSummary>> listTeachers() async {
    final rows = await _database.rawQuery('''
      SELECT t.id, t.name, COUNT(m.id) AS audio_count
      FROM teachers t
      LEFT JOIN media m ON m.teacher_id = t.id AND m.type = 'audio'
      GROUP BY t.id, t.name
      ORDER BY LOWER(t.name), t.id
    ''');
    return rows.map(_teacherSummary).toList(growable: false);
  }

  @override
  Future<List<TeacherSummary>> searchTeachers(
    String query, {
    int limit = 100,
  }) async {
    validateLimit(limit);
    final pattern = '%${normalizeText(query).toLowerCase()}%';
    final rows = await _database.rawQuery(
      '''
      SELECT t.id, t.name, COUNT(m.id) AS audio_count
      FROM teachers t
      LEFT JOIN media m ON m.teacher_id = t.id AND m.type = 'audio'
      WHERE LOWER(t.name) LIKE ? OR LOWER(COALESCE(t.name_myanmar, '')) LIKE ?
      GROUP BY t.id, t.name
      ORDER BY audio_count DESC, LOWER(t.name), t.id
      LIMIT ?
    ''',
      <Object?>[pattern, pattern, limit],
    );
    return rows.map(_teacherSummary).toList(growable: false);
  }

  @override
  Future<TeacherDetail> getTeacher(int id) async {
    validatePositiveId(id);
    final rows = await _database.rawQuery(
      '''
      SELECT t.id, t.name, t.name_myanmar, t.title, t.description, COUNT(m.id) AS audio_count
      FROM teachers t
      LEFT JOIN media m ON m.teacher_id = t.id AND m.type = 'audio'
      WHERE t.id = ?
      GROUP BY t.id
    ''',
      <Object?>[id],
    );
    if (rows.isEmpty) throw CatalogueNotFoundException('Teacher', id);
    final row = rows.single;
    final collectionRows = await _database.rawQuery(
      '''
      SELECT c.id, c.name, c.teacher_id, t.name AS teacher_name, COUNT(DISTINCT m.id) AS audio_count
      FROM collections c
      JOIN media_collections mc ON mc.collection_id = c.id
      JOIN media m ON m.id = mc.media_id AND m.type = 'audio'
      LEFT JOIN teachers t ON t.id = c.teacher_id
      WHERE c.teacher_id = ?
      GROUP BY c.id, c.name, c.teacher_id, t.name
    ''',
      <Object?>[id],
    );
    final collections = collectionRows.map(_collectionSummary).toList();
    sortTeacherCollections(collections);
    return TeacherDetail(
      id: _integer(row['id']),
      name: normalizeText(_string(row['name'])),
      nameMyanmar: _optionalNormalized(row['name_myanmar']),
      title: _optionalNormalized(row['title']),
      description: _optionalNormalized(row['description']),
      audioCount: _integer(row['audio_count']),
      collections: collections,
    );
  }

  @override
  Future<CollectionSearchPage> searchCollections(
    CollectionSearchRequest request,
  ) async {
    final limit = validateLimit(request.limit);
    final offset = request.offset < 0 ? 0 : request.offset;
    final teacherId = request.teacherId;
    if (teacherId != null) validatePositiveId(teacherId);
    final pattern = '%${normalizeText(request.query).toLowerCase()}%';
    final rows = await _database.rawQuery(
      '''
      SELECT c.id, c.name, c.teacher_id, t.name AS teacher_name, COUNT(DISTINCT m.id) AS audio_count
      FROM collections c
      JOIN media_collections mc ON mc.collection_id = c.id
      JOIN media m ON m.id = mc.media_id AND m.type = 'audio'
      LEFT JOIN teachers t ON t.id = c.teacher_id
      WHERE LOWER(c.name) LIKE ? AND (? IS NULL OR c.teacher_id = ?)
      GROUP BY c.id, c.name, c.teacher_id, t.name
    ''',
      <Object?>[pattern, request.teacherId, request.teacherId],
    );
    final summaries = rows.map(_collectionSummary).toList();
    sortCollectionSummaries(summaries);
    final items = summaries.skip(offset).take(limit).toList(growable: false);
    return CollectionSearchPage(
      items: items,
      total: summaries.length,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<CollectionDetail> getCollection(int id) async {
    validatePositiveId(id);
    final rows = await _database.rawQuery(
      '''
      SELECT c.name, c.description, c.teacher_id, t.name AS teacher_name
      FROM collections c
      LEFT JOIN teachers t ON t.id = c.teacher_id
      WHERE c.id = ?
    ''',
      <Object?>[id],
    );
    if (rows.isEmpty) throw CatalogueNotFoundException('Collection', id);
    final row = rows.single;
    final trackRows = await _database.rawQuery(
      '''
      SELECT m.id, m.title, COALESCE(m.format, '') AS format, m.language, m.url,
             m.date_recorded, m.location, m.teacher_id, t.name AS teacher_name
      FROM media_collections mc
      JOIN media m ON m.id = mc.media_id AND m.type = 'audio'
      LEFT JOIN teachers t ON t.id = m.teacher_id
      WHERE mc.collection_id = ?
      ORDER BY mc.track_number IS NULL, mc.track_number, m.id
    ''',
      <Object?>[id],
    );
    final tracks = trackRows.map(_audioTrack).toList(growable: false);
    return CollectionDetail(
      id: id,
      name: _normalizedOr(row['name'], 'Untitled collection'),
      description: _optionalNormalized(row['description']),
      teacherId: _nullableInteger(row['teacher_id']),
      teacherName: _normalizedOr(row['teacher_name'], 'Unknown teacher'),
      audioCount: tracks.length,
      tracks: tracks,
    );
  }

  @override
  Future<AudioTrack> getAudioTrack(int id) async {
    validatePositiveId(id);
    final rows = await _database.rawQuery(
      '''
      SELECT m.id, m.title, COALESCE(m.format, '') AS format, m.language, m.url,
             m.date_recorded, m.location, m.teacher_id, t.name AS teacher_name
      FROM media m
      LEFT JOIN teachers t ON t.id = m.teacher_id
      WHERE m.id = ? AND m.type = 'audio'
    ''',
      <Object?>[id],
    );
    if (rows.isEmpty) throw CatalogueNotFoundException('Audio track', id);
    return _audioTrack(rows.single);
  }

  @override
  Future<AudioSearchPage> searchAudio(AudioSearchRequest request) async {
    final limit = validateLimit(request.limit);
    final offset = request.offset < 0 ? 0 : request.offset;
    validateLanguage(request.language);
    validateFormat(request.format);
    final teacherId = request.teacherId;
    final categoryId = request.categoryId;
    final collectionId = request.collectionId;
    if (teacherId != null) validatePositiveId(teacherId);
    if (categoryId != null) validatePositiveId(categoryId);
    if (collectionId != null) validatePositiveId(collectionId);

    final clauses = <String>["m.type = 'audio'"];
    final values = <Object?>[];
    final query = normalizeText(request.query).toLowerCase();
    if (query.isNotEmpty) {
      final pattern = '%$query%';
      clauses.add(
        "(LOWER(COALESCE(m.title, '')) LIKE ? OR LOWER(COALESCE(t.name, '')) LIKE ?)",
      );
      values.addAll(<Object?>[pattern, pattern]);
    }
    final language = request.language;
    final format = request.format;
    if (language != null) {
      clauses.add('m.language = ?');
      values.add(language);
    }
    if (format != null) {
      clauses.add('m.format = ?');
      values.add(format);
    }
    if (teacherId != null) {
      clauses.add('m.teacher_id = ?');
      values.add(teacherId);
    }
    if (categoryId != null) {
      clauses.add('m.category_id = ?');
      values.add(categoryId);
    }
    if (collectionId != null) {
      clauses.add(
        'EXISTS (SELECT 1 FROM media_collections filter_mc WHERE filter_mc.media_id = m.id AND filter_mc.collection_id = ?)',
      );
      values.add(collectionId);
    }
    final whereClause = clauses.join(' AND ');
    final countRows = await _database.rawQuery(
      'SELECT COUNT(*) AS count FROM media m LEFT JOIN teachers t ON t.id = m.teacher_id WHERE $whereClause',
      values,
    );
    final total = _integer(countRows.single['count']);
    final pageValues = <Object?>[...values, limit, offset];
    final rows = await _database.rawQuery('''
      SELECT m.id, m.title, COALESCE(m.format, '') AS format, m.language, m.url,
             m.date_recorded, m.location, m.teacher_id, t.name AS teacher_name
      FROM media m
      LEFT JOIN teachers t ON t.id = m.teacher_id
      WHERE $whereClause
      ORDER BY LOWER(COALESCE(t.name, '')), m.id
      LIMIT ? OFFSET ?
    ''', pageValues);
    return AudioSearchPage(
      items: rows.map(_audioTrack).toList(growable: false),
      total: total,
      limit: limit,
      offset: offset,
    );
  }
}

TeacherSummary _teacherSummary(Map<String, Object?> row) {
  return TeacherSummary(
    id: _integer(row['id']),
    name: normalizeText(_string(row['name'])),
    audioCount: _integer(row['audio_count']),
  );
}

CollectionSummary _collectionSummary(Map<String, Object?> row) {
  return CollectionSummary(
    id: _integer(row['id']),
    name: _normalizedOr(row['name'], 'Untitled collection'),
    teacherId: _nullableInteger(row['teacher_id']),
    teacherName: _normalizedOr(row['teacher_name'], 'Unknown teacher'),
    audioCount: _integer(row['audio_count']),
  );
}

AudioTrack _audioTrack(Map<String, Object?> row) {
  final format = normalizeText(_string(row['format'])).toLowerCase();
  final url = _string(row['url']);
  return AudioTrack(
    id: _integer(row['id']),
    title: _normalizedOr(row['title'], 'Untitled talk'),
    format: format,
    language: normalizeText(_string(row['language'])).toLowerCase(),
    url: url,
    dateRecorded: _optionalNormalized(row['date_recorded']),
    location: _optionalNormalized(row['location']),
    teacherId: _nullableInteger(row['teacher_id']),
    teacherName: _normalizedOr(row['teacher_name'], 'Unknown teacher'),
    playable: format == 'mp3' && mediaUrlCandidates(url, format).isNotEmpty,
  );
}

int _integer(Object? value) => value is int ? value : (value as num).toInt();
int? _nullableInteger(Object? value) => value == null ? null : _integer(value);
String _string(Object? value) => value?.toString() ?? '';
String? _optionalNormalized(Object? value) {
  if (value == null) return null;
  final normalized = normalizeText(value.toString());
  return normalized.isEmpty ? null : normalized;
}

String _normalizedOr(Object? value, String fallback) =>
    _optionalNormalized(value) ?? fallback;
