import 'package:ai_workbench/shared/domain/resource_type.dart';

/// Searchable metadata for one resource stored in a Vault.
class ResourceRecord {
  ResourceRecord({
    required this.id,
    required this.type,
    required this.relativePath,
    required this.title,
    required this.description,
    required List<String> tags,
    required this.modifiedAt,
    required this.searchableText,
  }) : tags = List.unmodifiable(tags);

  final String id;
  final ResourceType type;
  final String relativePath;
  final String title;
  final String description;
  final List<String> tags;
  final DateTime modifiedAt;
  final String searchableText;
}
