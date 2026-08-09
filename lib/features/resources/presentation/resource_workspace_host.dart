import 'package:ai_workbench/features/mcp/application/mcp_controller.dart';
import 'package:ai_workbench/features/prompts/application/prompt_controller.dart';
import 'package:ai_workbench/features/resources/application/resource_workspace_registry.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/skills/application/skill_controller.dart';
import 'package:flutter/widgets.dart';

/// Dispatches the correct typed workspace for a selected resource.
class ResourceWorkspaceHost extends StatelessWidget {
  const ResourceWorkspaceHost({
    required this.resource,
    this.promptController,
    this.skillController,
    this.mcpController,
    this.fallback,
    this.registry = const ResourceWorkspaceRegistry(),
    super.key,
  });

  final WorkbenchResource resource;
  final PromptController? promptController;
  final SkillController? skillController;
  final McpController? mcpController;
  final Widget? fallback;
  final ResourceWorkspaceRegistry registry;

  @override
  Widget build(BuildContext context) {
    return registry.build(
          resource: resource,
          promptController: promptController,
          skillController: skillController,
          mcpController: mcpController,
        ) ??
        fallback ??
        const SizedBox.shrink();
  }
}
