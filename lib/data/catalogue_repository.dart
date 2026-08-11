import 'package:dhamma_echo/domain/models.dart';

abstract interface class CatalogueRepository {
  Future<CatalogueSummary> getSummary();
  Future<List<AudioCategory>> listAudioCategories();
  Future<List<TeacherSummary>> listFeaturedTeachers({int limit = 100});
  Future<List<TeacherSummary>> searchTeachers(String query, {int limit = 100});
  Future<TeacherDetail> getTeacher(int id);
  Future<CollectionSearchPage> searchCollections(
    CollectionSearchRequest request,
  );
  Future<CollectionDetail> getCollection(int id);
  Future<AudioSearchPage> searchAudio(AudioSearchRequest request);
  Future<AudioTrack> getAudioTrack(int id);
}

class CatalogueNotFoundException implements Exception {
  const CatalogueNotFoundException(this.entity, this.id);

  final String entity;
  final int id;

  @override
  String toString() => '$entity $id was not found';
}
