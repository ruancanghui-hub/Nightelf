import 'package:ai_workbench/features/links/application/link_controller.dart';
import 'package:ai_workbench/features/links/presentation/link_workspace.dart';
import 'package:ai_workbench/features/mcp/application/mcp_controller.dart';
import 'package:ai_workbench/features/mcp/presentation/mcp_workspace.dart';
import 'package:ai_workbench/features/prompts/application/prompt_controller.dart';
import 'package:ai_workbench/features/prompts/presentation/prompt_workspace.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/skills/application/skill_controller.dart';
import 'package:ai_workbench/features/skills/presentation/skill_workspace.dart';
import 'package:ai_workbench/features/workflows/application/workflow_controller.dart';
import 'package:ai_workbench/features/workspaces/presentation/workflow_workspace.dart';
import 'package:flutter/widgets.dart';

/// Builds the live workspace surface for a workbench resource type.
class ResourceWorkspaceRegistry {
  const ResourceWorkspaceRegistry();

  Widget? build({
    required WorkbenchResource resource,
    PromptController? promptController,
    SkillController? skillController,
    McpController? mcpController,
    LinkController? linkController,
    WorkflowController? workflowController,
    Future<void> Function(String relativePath)? onRenamed,
  }) {
    return switch (resource.type) {
      ResourceType.aiPrompt when promptController != null => PromptWorkspace(
        controller: promptController,
        onRenamed: onRenamed,
      ),
      ResourceType.skillFolder when skillController != null => SkillWorkspace(
        controller: skillController,
      ),
      ResourceType.mcpConfiguration when mcpController != null => McpWorkspace(
        controller: mcpController,
        onRenamed: onRenamed,
      ),
      ResourceType.websiteLink when linkController != null => LinkWorkspace(
        controller: linkController,
        onRenamed: onRenamed,
      ),
      ResourceType.workflowFile when workflowController != null =>
        WorkflowWorkspace(
          controller: workflowController,
          onRenamed: onRenamed,
        ),
      _ => null,
    };
  }
}
