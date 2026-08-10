import 'package:flutter/foundation.dart';

@immutable
class CatalogueSummary {
  const CatalogueSummary({
    required this.totalAudio,
    required this.totalTeachers,
    required this.myanmarAudio,
    required this.englishAudio,
  });

  final int totalAudio;
  final int totalTeachers;
  final int myanmarAudio;
  final int englishAudio;
}

@immutable
class TeacherSummary {
  const TeacherSummary({required this.id, required this.name, required this.audioCount});

  final int id;
  final String name;
  final int audioCount;
}

@immutable
class TeacherDetail {
  const TeacherDetail({
    required this.id,
    required this.name,
    required this.audioCount,
    required this.collections,
    this.nameMyanmar,
    this.title,
    this.description,
  });

  final int id;
  final String name;
  final String? nameMyanmar;
  final String? title;
  final String? description;
  final int audioCount;
  final List<CollectionSummary> collections;
}

@immutable
class AudioCategory {
  const AudioCategory({
    required this.id,
    required this.name,
    required this.language,
    required this.audioCount,
  });

  final int id;
  final String name;
  final String language;
  final int audioCount;
}

@immutable
class CollectionSearchRequest {
  const CollectionSearchRequest({
    this.query = '',
    this.teacherId,
    this.limit = 24,
    this.offset = 0,
  });

  final String query;
  final int? teacherId;
  final int limit;
  final int offset;

  CollectionSearchRequest copyWith({
    String? query,
    int? teacherId,
    bool clearTeacher = false,
    int? limit,
    int? offset,
  }) {
    return CollectionSearchRequest(
      query: query ?? this.query,
      teacherId: clearTeacher ? null : teacherId ?? this.teacherId,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}

@immutable
class CollectionSummary {
  const CollectionSummary({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.teacherName,
    required this.audioCount,
  });

  final int id;
  final String name;
  final int? teacherId;
  final String teacherName;
  final int audioCount;
}

@immutable
class CollectionSearchPage {
  const CollectionSearchPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<CollectionSummary> items;
  final int total;
  final int limit;
  final int offset;
}

@immutable
class CollectionDetail {
  const CollectionDetail({
    required this.id,
    required this.name,
    required this.teacherName,
    required this.audioCount,
    required this.tracks,
    this.description,
    this.teacherId,
  });

  final int id;
  final String name;
  final String? description;
  final int? teacherId;
  final String teacherName;
  final int audioCount;
  final List<AudioTrack> tracks;
}

@immutable
class AudioTrack {
  const AudioTrack({
    required this.id,
    required this.title,
    required this.format,
    required this.language,
    required this.url,
    required this.teacherName,
    required this.playable,
    this.dateRecorded,
    this.location,
    this.teacherId,
  });

  final int id;
  final String title;
  final String format;
  final String language;
  final String url;
  final String? dateRecorded;
  final String? location;
  final int? teacherId;
  final String teacherName;
  final bool playable;
}

@immutable
class AudioSearchRequest {
  const AudioSearchRequest({
    this.query = '',
    this.language,
    this.format,
    this.teacherId,
    this.categoryId,
    this.collectionId,
    this.limit = 50,
    this.offset = 0,
  });

  final String query;
  final String? language;
  final String? format;
  final int? teacherId;
  final int? categoryId;
  final int? collectionId;
  final int limit;
  final int offset;

  AudioSearchRequest copyWith({
    String? query,
    String? language,
    bool clearLanguage = false,
    String? format,
    bool clearFormat = false,
    int? teacherId,
    bool clearTeacher = false,
    int? categoryId,
    bool clearCategory = false,
    int? collectionId,
    bool clearCollection = false,
    int? limit,
    int? offset,
  }) {
    return AudioSearchRequest(
      query: query ?? this.query,
      language: clearLanguage ? null : language ?? this.language,
      format: clearFormat ? null : format ?? this.format,
      teacherId: clearTeacher ? null : teacherId ?? this.teacherId,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      collectionId: clearCollection ? null : collectionId ?? this.collectionId,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}

@immutable
class AudioSearchPage {
  const AudioSearchPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<AudioTrack> items;
  final int total;
  final int limit;
  final int offset;
}

@immutable
class HistoryEntry {
  const HistoryEntry({required this.id, required this.playedAt});

  final int id;
  final double playedAt;

  @override
  bool operator ==(Object other) {
    return other is HistoryEntry && other.id == id && other.playedAt == playedAt;
  }

  @override
  int get hashCode => Object.hash(id, playedAt);
}

@immutable
class LibraryState {
  const LibraryState({required this.favorites, required this.history, required this.resume});
  const LibraryState.defaults() : favorites = const [], history = const [], resume = const {};

  final List<int> favorites;
  final List<HistoryEntry> history;
  final Map<int, double> resume;

  @override
  bool operator ==(Object other) {
    return other is LibraryState &&
        listEquals(other.favorites, favorites) &&
        listEquals(other.history, history) &&
        mapEquals(other.resume, resume);
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(favorites), Object.hashAll(history), Object.hashAll(resume.entries));
}

@immutable
class SettingsState {
  const SettingsState({required this.playbackRate, required this.volume});
  const SettingsState.defaults() : playbackRate = 1, volume = 0.8;

  final double playbackRate;
  final double volume;

  @override
  bool operator ==(Object other) {
    return other is SettingsState && other.playbackRate == playbackRate && other.volume == volume;
  }

  @override
  int get hashCode => Object.hash(playbackRate, volume);
}

@immutable
class PersistedState {
  const PersistedState({required this.library, required this.settings});
  const PersistedState.defaults()
      : library = const LibraryState.defaults(),
        settings = const SettingsState.defaults();

  final LibraryState library;
  final SettingsState settings;

  @override
  bool operator ==(Object other) {
    return other is PersistedState && other.library == library && other.settings == settings;
  }

  @override
  int get hashCode => Object.hash(library, settings);
}

@immutable
class CollectionGroup {
  const CollectionGroup({required this.key, required this.name, required this.items});

  final String key;
  final String name;
  final List<CollectionSummary> items;
}
