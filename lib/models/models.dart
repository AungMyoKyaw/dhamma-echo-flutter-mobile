import 'package:material_ui/material_ui.dart' show ThemeMode;

import '../data/media_url_policy.dart';

enum MediaKind {
  audio,
  video,
  ebook;

  static MediaKind parse(String raw) => switch (raw) {
    'video' => MediaKind.video,
    'ebook' => MediaKind.ebook,
    _ => MediaKind.audio,
  };

  String get dbValue => name;
}

enum PdfTint { light, sepia, dark }

class MediaItem {
  const MediaItem({
    required this.id,
    required this.title,
    required this.kind,
    required this.format,
    required this.language,
    required this.url,
    this.titleMyanmar,
    this.fileSize,
    this.duration,
    this.description,
    this.dateRecorded,
    this.location,
    this.teacherId,
    this.teacherName,
    this.categoryId,
    this.sourcePage,
    this.trackNumber,
  });

  factory MediaItem.fromRow(Map<String, Object?> row) => MediaItem(
    id: row['id']! as int,
    title: (row['title'] as String?) ?? '',
    titleMyanmar: row['title_myanmar'] as String?,
    kind: MediaKind.parse((row['type'] as String?) ?? 'audio'),
    format: ((row['format'] as String?) ?? '').toLowerCase(),
    language: (row['language'] as String?) ?? 'myanmar',
    url: (row['url'] as String?) ?? '',
    fileSize: row['file_size'] as int?,
    duration: row['duration'] as String?,
    description: row['description'] as String?,
    dateRecorded: row['date_recorded'] as String?,
    location: row['location'] as String?,
    teacherId: row['teacher_id'] as int?,
    teacherName: row['teacher_name'] as String?,
    categoryId: row['category_id'] as int?,
    sourcePage: row['source_page'] as String?,
    trackNumber: row['track_number'] as int?,
  );

  final int id;
  final String title;
  final String? titleMyanmar;
  final MediaKind kind;
  final String format;
  final String language;
  final String url;
  final int? fileSize;
  final String? duration;
  final String? description;
  final String? dateRecorded;
  final String? location;
  final int? teacherId;
  final String? teacherName;
  final int? categoryId;
  final String? sourcePage;
  final int? trackNumber;

  String get displayTitle {
    final mm = titleMyanmar;
    return (mm != null && mm.trim().isNotEmpty) ? mm : title;
  }

  /// Whether this entry can be played or read inside the app.
  bool get isInAppPlayable => MediaUrlPolicy.isInAppPlayable(format, url);

  bool get isLegacy => !isInAppPlayable;

  Uri? get remoteUri => MediaUrlPolicy.normalize(url);

  String get formatLabel => format.toUpperCase();
}

class Teacher {
  const Teacher({
    required this.id,
    required this.name,
    required this.mediaCount,
    required this.collectionCount,
    required this.featured,
    this.nameMyanmar,
    this.title,
    this.description,
  });

  final int id;
  final String name;
  final String? nameMyanmar;
  final String? title;
  final String? description;
  final int mediaCount;
  final int collectionCount;
  final bool featured;

  String get displayName {
    final mm = nameMyanmar;
    return (mm != null && mm.trim().isNotEmpty) ? mm : name;
  }

  /// First user-perceived character, used for the geometric monogram seal.
  String get monogram {
    final text = displayName.trim();
    if (text.isEmpty) return '·';
    final first = String.fromCharCode(text.runes.first);
    return first.toUpperCase();
  }
}

class CollectionSummary {
  const CollectionSummary({
    required this.id,
    required this.name,
    required this.itemCount,
    this.description,
    this.teacherId,
    this.teacherName,
    this.type,
  });

  final int id;
  final String name;
  final String? description;
  final int? teacherId;
  final String? teacherName;
  final String? type;
  final int itemCount;
}

class ArchiveCounts {
  const ArchiveCounts({
    required this.audio,
    required this.video,
    required this.ebook,
    required this.abhidhamma,
    required this.teachers,
    required this.collections,
    required this.total,
  });

  static const empty = ArchiveCounts(
    audio: 0,
    video: 0,
    ebook: 0,
    abhidhamma: 0,
    teachers: 0,
    collections: 0,
    total: 0,
  );

  final int audio;
  final int video;
  final int ebook;
  final int abhidhamma;
  final int teachers;
  final int collections;
  final int total;
}

enum DownloadStatus { queued, downloading, completed, failed, canceled }

class DownloadRecord {
  const DownloadRecord({
    required this.mediaId,
    required this.status,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.localPath,
    this.error,
  });

  factory DownloadRecord.fromRow(Map<String, Object?> row) => DownloadRecord(
    mediaId: row['media_id']! as int,
    status: DownloadStatus.values.firstWhere(
      (s) => s.name == row['status'],
      orElse: () => DownloadStatus.failed,
    ),
    receivedBytes: (row['received_bytes'] as int?) ?? 0,
    totalBytes: (row['total_bytes'] as int?) ?? 0,
    localPath: row['local_path'] as String?,
    error: row['error'] as String?,
  );

  final int mediaId;
  final DownloadStatus status;
  final int receivedBytes;
  final int totalBytes;
  final String? localPath;
  final String? error;

  double? get progress =>
      totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : null;

  bool get isActive =>
      status == DownloadStatus.queued || status == DownloadStatus.downloading;

  DownloadRecord copyWith({
    DownloadStatus? status,
    int? receivedBytes,
    int? totalBytes,
    String? localPath,
    String? error,
  }) => DownloadRecord(
    mediaId: mediaId,
    status: status ?? this.status,
    receivedBytes: receivedBytes ?? this.receivedBytes,
    totalBytes: totalBytes ?? this.totalBytes,
    localPath: localPath ?? this.localPath,
    error: error,
  );
}

class HistoryEntry {
  const HistoryEntry({
    required this.mediaId,
    required this.positionMs,
    required this.durationMs,
    required this.updatedAt,
  });

  final int mediaId;
  final int positionMs;
  final int durationMs;
  final DateTime updatedAt;

  double get fraction =>
      durationMs > 0 ? (positionMs / durationMs).clamp(0.0, 1.0) : 0;
}

class AppSettings {
  const AppSettings({
    this.language = 'en',
    this.themeMode = ThemeMode.system,
    this.playbackSpeed = 1.0,
    this.wifiOnly = true,
    this.showLegacy = true,
    this.pdfTint = PdfTint.sepia,
  });

  final String language;
  final ThemeMode themeMode;
  final double playbackSpeed;
  final bool wifiOnly;
  final bool showLegacy;
  final PdfTint pdfTint;

  bool get isMyanmar => language == 'my';

  AppSettings copyWith({
    String? language,
    ThemeMode? themeMode,
    double? playbackSpeed,
    bool? wifiOnly,
    bool? showLegacy,
    PdfTint? pdfTint,
  }) => AppSettings(
    language: language ?? this.language,
    themeMode: themeMode ?? this.themeMode,
    playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    wifiOnly: wifiOnly ?? this.wifiOnly,
    showLegacy: showLegacy ?? this.showLegacy,
    pdfTint: pdfTint ?? this.pdfTint,
  );
}
