import 'package:ai_workbench/features/vault/domain/resource_record.dart';

class SearchHit {
  const SearchHit({
    required this.record,
    required this.snippet,
    required this.rank,
  });

  final ResourceRecord record;
  final String snippet;
  final double rank;
}
