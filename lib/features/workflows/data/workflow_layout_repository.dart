import 'package:ai_workbench/features/workflows/domain/workflow_layout.dart';

abstract class WorkflowLayoutRepository {
  Future<WorkflowLayout?> load(String workflowId);

  Future<void> save(WorkflowLayout layout);

  Future<void> delete(String workflowId);
}
