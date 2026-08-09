/// Per-resource metadata stored beside Vault files (not in front matter alone).
class ResourceMetadata {
  const ResourceMetadata({
    required this.resourceId,
    this.description = '',
    this.tags = const [],
    this.relatedResourceIds = const [],
    this.isFavorite = false,
  });

  final String resourceId;
  final String description;
  final List<String> tags;
  final List<String> relatedResourceIds;
  final bool isFavorite;

  ResourceMetadata copyWith({
    String? resourceId,
    String? description,
    List<String>? tags,
    List<String>? relatedResourceIds,
    bool? isFavorite,
  }) {
    return ResourceMetadata(
      resourceId: resourceId ?? this.resourceId,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      relatedResourceIds: relatedResourceIds ?? this.relatedResourceIds,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// A named grouping of stable resource IDs synchronized with the Vault.
class CollectionRecord {
  const CollectionRecord({
    required this.id,
    required this.name,
    this.resourceIds = const [],
  });

  final String id;
  final String name;
  final List<String> resourceIds;

  CollectionRecord copyWith({
    String? id,
    String? name,
    List<String>? resourceIds,
  }) {
    return CollectionRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      resourceIds: resourceIds ?? this.resourceIds,
    );
  }
}

/// A recently opened resource with optional open timestamp.
class RecentResourceEntry {
  const RecentResourceEntry({required this.resourceId, this.openedAt});

  final String resourceId;
  final DateTime? openedAt;
}

/// Loaded metadata state for one Vault.
class MetadataSnapshot {
  const MetadataSnapshot({
    this.resources = const {},
    this.collections = const [],
    this.recentEntries = const [],
  });

  final Map<String, ResourceMetadata> resources;
  final List<CollectionRecord> collections;
  final List<RecentResourceEntry> recentEntries;

  List<String> get recentResourceIds => [
    for (final entry in recentEntries) entry.resourceId,
  ];

  Set<String> get favoriteIds => {
    for (final entry in resources.entries)
      if (entry.value.isFavorite) entry.key,
  };
}
