import 'package:ai_workbench/features/workflows/domain/workflow_document.dart';

abstract class WorkflowRepository {
  Future<WorkflowDocument> create({
    required String title,
    String source = '',
    String extension = '.mmd',
    String description = '',
    List<String> tags = const [],
  });

  Future<WorkflowDocument> read(String relativePath);

  Future<WorkflowDocument> save(WorkflowDocument document);

  Future<WorkflowDocument> duplicate(String relativePath);

  Future<WorkflowDocument> rename(
    String relativePath, {
    required String title,
    String? source,
  });

  Future<String> moveToTrash(String relativePath);

  Future<WorkflowDocument> importFile({
    required String absolutePath,
    String? title,
  });
}
