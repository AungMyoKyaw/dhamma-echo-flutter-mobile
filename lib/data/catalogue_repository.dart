import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// Read-only access to the bundled Dhamma catalogue.
class CatalogueRepository {
  CatalogueRepository(this._db);

  final Database _db;

  /// Canonical featured-teacher order shared with the desktop app.
  static const featuredTeacherIds = [16, 42, 40, 53, 61, 8, 55, 1307];

  static const _mediaSelect = '''
    SELECT m.id, m.title, m.title_myanmar, m.type, m.format, m.language,
           m.url, m.file_size, m.duration, m.description, m.date_recorded,
           m.location, m.teacher_id, m.category_id, m.source_page,
           t.name AS teacher_name
    FROM media m
    LEFT JOIN teachers t ON t.id = m.teacher_id
  ''';

  static const _teacherSelect = '''
    SELECT t.id, t.name, t.name_myanmar, t.title, t.description,
           (SELECT COUNT(*) FROM media m WHERE m.teacher_id = t.id) AS media_count,
           (SELECT COUNT(*) FROM collections c WHERE c.teacher_id = t.id) AS collection_count
    FROM teachers t
  ''';

  Future<ArchiveCounts> getArchiveCounts() async {
    final rows = await _db.rawQuery(
      'SELECT type, COUNT(*) AS n FROM media GROUP BY type',
    );
    int of(String type) => rows
        .where((r) => r['type'] == type)
        .fold<int>(0, (sum, r) => sum + (r['n']! as int));
    final abhidhamma = Sqflite.firstIntValue(
      await _db.rawQuery(
        'SELECT COUNT(*) FROM media WHERE category_id IN (4, 5)',
      ),
    );
    final teachers = Sqflite.firstIntValue(
      await _db.rawQuery('SELECT COUNT(*) FROM teachers'),
    );
    final collections = Sqflite.firstIntValue(
      await _db.rawQuery('SELECT COUNT(*) FROM collections'),
    );
    final audio = of('audio');
    final video = of('video');
    final ebook = of('ebook');
    return ArchiveCounts(
      audio: audio,
      video: video,
      ebook: ebook,
      abhidhamma: abhidhamma ?? 0,
      teachers: teachers ?? 0,
      collections: collections ?? 0,
      total: audio + video + ebook,
    );
  }

  Teacher _teacher(Map<String, Object?> r) => Teacher(
    id: r['id']! as int,
    name: (r['name'] as String?) ?? '',
    nameMyanmar: r['name_myanmar'] as String?,
    title: r['title'] as String?,
    description: r['description'] as String?,
    mediaCount: (r['media_count'] as int?) ?? 0,
    collectionCount: (r['collection_count'] as int?) ?? 0,
    featured: featuredTeacherIds.contains(r['id']),
  );

  Future<List<Teacher>> getFeaturedTeachers() async {
    final ids = featuredTeacherIds.join(',');
    final rows = await _db.rawQuery('$_teacherSelect WHERE t.id IN ($ids)');
    final byId = {for (final r in rows) r['id']! as int: _teacher(r)};
    return [
      for (final id in featuredTeacherIds)
        if (byId[id] != null) byId[id]!,
    ];
  }

  /// Featured teachers first (canonical order), then the rest by teaching count.
  Future<List<Teacher>> getTeachers({int limit = 300, int offset = 0}) async {
    final rows = await _db.rawQuery(_teacherSelect);
    final all = rows.map(_teacher).toList();
    final featured = <Teacher>[
      for (final id in featuredTeacherIds) ...all.where((t) => t.id == id),
    ];
    final rest = all.where((t) => !t.featured).toList()
      ..sort((a, b) {
        final byCount = b.mediaCount.compareTo(a.mediaCount);
        return byCount != 0 ? byCount : a.id.compareTo(b.id);
      });
    final ordered = [...featured, ...rest];
    if (offset >= ordered.length) return const [];
    final end = (offset + limit).clamp(0, ordered.length);
    return ordered.sublist(offset, end);
  }

  Future<Teacher?> getTeacher(int id) async {
    final rows = await _db.rawQuery('$_teacherSelect WHERE t.id = ?', [id]);
    return rows.isEmpty ? null : _teacher(rows.first);
  }

  CollectionSummary _collection(Map<String, Object?> r) => CollectionSummary(
    id: r['id']! as int,
    name: (r['name'] as String?) ?? '',
    description: r['description'] as String?,
    teacherId: r['teacher_id'] as int?,
    teacherName: r['teacher_name'] as String?,
    type: r['type'] as String?,
    itemCount: (r['item_count'] as int?) ?? 0,
  );

  static const _collectionSelect = '''
    SELECT c.id, c.name, c.description, c.teacher_id, c.type,
           t.name AS teacher_name,
           (SELECT COUNT(*) FROM media_collections mc WHERE mc.collection_id = c.id) AS item_count
    FROM collections c
    LEFT JOIN teachers t ON t.id = c.teacher_id
  ''';

  Future<List<CollectionSummary>> getRandomCollections({int limit = 4}) async {
    final rows = await _db.rawQuery(
      '$_collectionSelect WHERE (SELECT COUNT(*) FROM media_collections mc WHERE mc.collection_id = c.id) > 0 ORDER BY RANDOM() LIMIT ?',
      [limit],
    );
    return rows.map(_collection).toList();
  }

  Future<CollectionSummary?> getCollection(int id) async {
    final rows = await _db.rawQuery('$_collectionSelect WHERE c.id = ?', [id]);
    return rows.isEmpty ? null : _collection(rows.first);
  }

  Future<List<CollectionSummary>> getTeacherCollections(int teacherId) async {
    final rows = await _db.rawQuery(
      '$_collectionSelect WHERE c.teacher_id = ? ORDER BY item_count DESC, c.name',
      [teacherId],
    );
    return rows.map(_collection).toList();
  }

  Future<int> countCollectionTracks(int collectionId) async =>
      Sqflite.firstIntValue(
        await _db.rawQuery(
          'SELECT COUNT(*) FROM media_collections WHERE collection_id = ?',
          [collectionId],
        ),
      ) ??
      0;

  Future<List<MediaItem>> getCollectionTracks(
    int collectionId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await _db.rawQuery(
      '''
      SELECT m.id, m.title, m.title_myanmar, m.type, m.format, m.language,
             m.url, m.file_size, m.duration, m.description, m.date_recorded,
             m.location, m.teacher_id, m.category_id, m.source_page,
             t.name AS teacher_name, mc.track_number AS track_number
      FROM media_collections mc
      JOIN media m ON m.id = mc.media_id
      LEFT JOIN teachers t ON t.id = m.teacher_id
      WHERE mc.collection_id = ?
      ORDER BY COALESCE(mc.track_number, 1000000), m.id
      LIMIT ? OFFSET ?
      ''',
      [collectionId, limit, offset],
    );
    return rows.map(MediaItem.fromRow).toList();
  }

  Future<MediaItem?> getMedia(int id) async {
    final rows = await _db.rawQuery('$_mediaSelect WHERE m.id = ?', [id]);
    return rows.isEmpty ? null : MediaItem.fromRow(rows.first);
  }

  Future<List<MediaItem>> getMediaByIds(Iterable<int> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return const [];
    final rows = await _db.rawQuery(
      '$_mediaSelect WHERE m.id IN (${list.map((_) => '?').join(',')})',
      list,
    );
    final byId = {for (final r in rows) r['id']! as int: MediaItem.fromRow(r)};
    return [
      for (final id in list)
        if (byId[id] != null) byId[id]!,
    ];
  }

  /// Builds `WHERE` fragments for the shared browse/search filters.
  ({String where, List<Object?> args}) _filters({
    MediaKind? kind,
    String? language,
    String? format,
    int? teacherId,
    bool showLegacy = true,
    bool abhidhammaOnly = false,
    String? query,
  }) {
    final clauses = <String>[];
    final args = <Object?>[];
    if (kind != null) {
      clauses.add('m.type = ?');
      args.add(kind.dbValue);
    }
    if (language != null) {
      clauses.add('m.language = ?');
      args.add(language);
    }
    if (format != null) {
      clauses.add('m.format = ?');
      args.add(format);
    }
    if (teacherId != null) {
      clauses.add('m.teacher_id = ?');
      args.add(teacherId);
    }
    if (abhidhammaOnly) {
      clauses.add('m.category_id IN (4, 5)');
    }
    if (!showLegacy) {
      clauses.add("m.format IN ('mp3','mp4','pdf')");
    }
    final tokens = (query ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty);
    for (final token in tokens) {
      final like = '%${_escapeLike(token)}%';
      clauses.add(
        "(m.title LIKE ? ESCAPE '\\' OR m.title_myanmar LIKE ? ESCAPE '\\' "
        "OR t.name LIKE ? ESCAPE '\\' OR t.name_myanmar LIKE ? ESCAPE '\\')",
      );
      args.addAll([like, like, like, like]);
    }
    return (
      where: clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}',
      args: args,
    );
  }

  static String _escapeLike(String raw) =>
      raw.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

  Future<List<MediaItem>> browseMedia({
    MediaKind? kind,
    String? language,
    String? format,
    int? teacherId,
    bool showLegacy = true,
    bool abhidhammaOnly = false,
    int limit = 40,
    int offset = 0,
  }) async {
    final f = _filters(
      kind: kind,
      language: language,
      format: format,
      teacherId: teacherId,
      showLegacy: showLegacy,
      abhidhammaOnly: abhidhammaOnly,
    );
    final rows = await _db.rawQuery(
      '$_mediaSelect ${f.where} ORDER BY m.id LIMIT ? OFFSET ?',
      [...f.args, limit, offset],
    );
    return rows.map(MediaItem.fromRow).toList();
  }

  Future<int> countMedia({
    MediaKind? kind,
    String? language,
    String? format,
    int? teacherId,
    bool showLegacy = true,
    bool abhidhammaOnly = false,
    String? query,
  }) async {
    final f = _filters(
      kind: kind,
      language: language,
      format: format,
      teacherId: teacherId,
      showLegacy: showLegacy,
      abhidhammaOnly: abhidhammaOnly,
      query: query,
    );
    return Sqflite.firstIntValue(
          await _db.rawQuery(
            'SELECT COUNT(*) FROM media m LEFT JOIN teachers t ON t.id = m.teacher_id ${f.where}',
            f.args,
          ),
        ) ??
        0;
  }

  Future<List<MediaItem>> searchMedia(
    String query, {
    MediaKind? kind,
    bool showLegacy = true,
    int limit = 40,
    int offset = 0,
  }) async {
    if (query.trim().isEmpty) return const [];
    final f = _filters(kind: kind, showLegacy: showLegacy, query: query);
    final rows = await _db.rawQuery(
      '$_mediaSelect ${f.where} ORDER BY m.id LIMIT ? OFFSET ?',
      [...f.args, limit, offset],
    );
    return rows.map(MediaItem.fromRow).toList();
  }

  Future<List<MediaItem>> getTeacherMedia(
    int teacherId, {
    MediaKind? kind,
    int limit = 40,
    int offset = 0,
  }) => browseMedia(
    teacherId: teacherId,
    kind: kind,
    limit: limit,
    offset: offset,
  );

  Future<List<MediaItem>> getRelatedVideos(
    int? teacherId,
    int excludeId, {
    int limit = 6,
  }) async {
    if (teacherId == null) return const [];
    final rows = await _db.rawQuery(
      "$_mediaSelect WHERE m.teacher_id = ? AND m.type = 'video' AND m.id != ? ORDER BY m.id LIMIT ?",
      [teacherId, excludeId, limit],
    );
    return rows.map(MediaItem.fromRow).toList();
  }

  Future<void> close() => _db.close();
}
