import 'package:ai_workbench/features/prompts/domain/prompt_document.dart';

abstract interface class PromptRepository {
  Future<PromptDocument> create({
    required String title,
    String description = '',
    List<String> tags = const [],
    String body = '',
  });

  Future<PromptDocument> read(String relativePath);

  Future<PromptDocument> save(PromptDocument document);

  Future<PromptDocument> duplicate(String relativePath);

  Future<String> moveToTrash(String relativePath);
}
