import 'package:ai_workbench/features/links/domain/link_document.dart';

abstract interface class LinkRepository {
  Future<LinkDocument> create({
    required String title,
    required Uri uri,
    String description = '',
    List<String> tags = const [],
    String notes = '',
  });

  Future<LinkDocument> read(String relativePath);

  Future<LinkDocument> save(LinkDocument document);

  Future<LinkDocument> duplicate(String relativePath);

  Future<String> moveToTrash(String relativePath);
}
