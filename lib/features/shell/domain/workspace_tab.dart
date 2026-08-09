import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';

/// A resource opened in the mock workspace.
class WorkspaceTab {
  const WorkspaceTab({
    required this.resourceId,
    required this.title,
    required this.type,
  });

  final String resourceId;
  final String title;
  final ResourceType type;
}
