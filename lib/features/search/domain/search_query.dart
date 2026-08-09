import 'package:ai_workbench/shared/domain/resource_type.dart';

class SearchQuery {
  const SearchQuery({
    required this.text,
    this.types = const {},
    this.tags = const {},
    this.limit = 50,
  });

  final String text;
  final Set<ResourceType> types;
  final Set<String> tags;
  final int limit;
}
