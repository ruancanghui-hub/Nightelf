import 'package:ai_workbench/features/metadata/domain/resource_metadata.dart';

abstract interface class MetadataRepository {
  Future<MetadataSnapshot> load();

  Future<void> saveResource(ResourceMetadata metadata);

  Future<void> saveCollection(CollectionRecord collection);

  Future<void> deleteCollection(String collectionId);

  Future<void> recordRecent(String resourceId);
}
