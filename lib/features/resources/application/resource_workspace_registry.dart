import 'package:ai_workbench/features/mcp/application/mcp_controller.dart';
import 'package:ai_workbench/features/mcp/presentation/mcp_workspace.dart';
import 'package:ai_workbench/features/prompts/application/prompt_controller.dart';
import 'package:ai_workbench/features/prompts/presentation/prompt_workspace.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/skills/application/skill_controller.dart';
import 'package:ai_workbench/features/skills/presentation/skill_workspace.dart';
import 'package:flutter/widgets.dart';

/// Builds the live workspace surface for a workbench resource type.
class ResourceWorkspaceRegistry {
  const ResourceWorkspaceRegistry();

  Widget? build({
    required WorkbenchResource resource,
    PromptController? promptController,
    SkillController? skillController,
    McpController? mcpController,
  }) {
    return switch (resource.type) {
      ResourceType.aiPrompt when promptController != null => PromptWorkspace(
        controller: promptController,
      ),
      ResourceType.skillFolder when skillController != null => SkillWorkspace(
        controller: skillController,
      ),
      ResourceType.mcpConfiguration when mcpController != null => McpWorkspace(
        controller: mcpController,
      ),
      _ => null,
    };
  }
}
