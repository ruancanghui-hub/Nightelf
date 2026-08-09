import 'package:ai_workbench/features/search/domain/search_hit.dart';
import 'package:ai_workbench/features/search/domain/search_query.dart';
import 'package:ai_workbench/features/vault/domain/resource_record.dart';

abstract interface class SearchIndex {
  Future<void> rebuild(Iterable<ResourceRecord> records);

  Future<void> upsert(ResourceRecord record);

  Future<void> remove(String id);

  Future<List<SearchHit>> query(SearchQuery query);

  Future<void> close();
}
