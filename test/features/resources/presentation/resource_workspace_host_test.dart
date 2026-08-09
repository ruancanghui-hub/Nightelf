import 'package:ai_workbench/features/mcp/presentation/mcp_workspace.dart';
import 'package:ai_workbench/features/prompts/presentation/prompt_workspace.dart';
import 'package:ai_workbench/features/resources/presentation/resource_workspace_host.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/skills/presentation/skill_workspace.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

WorkbenchResource _record({
  required String id,
  required ResourceType type,
  required String title,
}) {
  return WorkbenchResource(
    id: id,
    type: type,
    title: title,
    subtitle: title,
    isFavorite: false,
    relativePath: switch (type) {
      ResourceType.aiPrompt => 'prompts/$id.md',
      ResourceType.skillFolder => 'skills/$id',
      ResourceType.mcpConfiguration => 'mcp/$id.json',
      _ => null,
    },
  );
}

Widget resourceHostHarness(WorkbenchResource resource) {
  return MacosApp(
    theme: MacosThemeData.light(),
    home: ResourceWorkspaceHost(
      resource: resource,
      promptController: null,
      skillController: null,
      mcpController: null,
      fallback: switch (resource.type) {
        ResourceType.aiPrompt => const PromptWorkspace(),
        ResourceType.skillFolder => const SkillWorkspace(),
        ResourceType.mcpConfiguration => const McpWorkspace(),
        _ => const SizedBox.shrink(),
      },
    ),
  );
}

void main() {
  testWidgets('workspace host dispatches by resource type', (tester) async {
    final promptRecord = _record(
      id: 'p1',
      type: ResourceType.aiPrompt,
      title: '提示词',
    );
    final skillRecord = _record(
      id: 's1',
      type: ResourceType.skillFolder,
      title: '技能',
    );
    final mcpRecord = _record(
      id: 'm1',
      type: ResourceType.mcpConfiguration,
      title: 'MCP',
    );

    await tester.pumpWidget(resourceHostHarness(promptRecord));
    expect(find.byType(PromptWorkspace), findsOneWidget);

    await tester.pumpWidget(resourceHostHarness(skillRecord));
    expect(find.byType(SkillWorkspace), findsOneWidget);

    await tester.pumpWidget(resourceHostHarness(mcpRecord));
    expect(find.byType(McpWorkspace), findsOneWidget);
  });
}
