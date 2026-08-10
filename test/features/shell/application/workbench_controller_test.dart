import 'package:ai_workbench/features/shell/application/workbench_controller.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'selecting a destination deterministically selects its first resource',
    () {
      final controller = WorkbenchController();

      expect(controller.destinationLabels, const [
        'AI 提示词',
        'SKILL 文件夹',
        'MCP 配置',
        '网站链接',
        'Workflow 文件',
      ]);

      controller.selectDestination(ResourceType.mcpConfiguration);

      expect(controller.selectedDestination, ResourceType.mcpConfiguration);
      expect(controller.selectedResource.id, 'mcp-local-docs');
      expect(controller.selectedResource.title, '本地文档 MCP');
    },
  );

  test('replaceResources keeps an empty destination selection', () {
    final controller = WorkbenchController(
      resources: const [
        WorkbenchResource(
          id: 'prompt-1',
          type: ResourceType.aiPrompt,
          title: '提示词',
          subtitle: '',
          isFavorite: false,
        ),
      ],
    );

    controller.selectDestination(ResourceType.mcpConfiguration);
    expect(controller.selectedDestination, ResourceType.mcpConfiguration);
    expect(controller.selectedResources, isEmpty);

    controller.replaceResources(const [
      WorkbenchResource(
        id: 'prompt-1',
        type: ResourceType.aiPrompt,
        title: '提示词',
        subtitle: '',
        isFavorite: true,
      ),
    ]);

    expect(controller.selectedDestination, ResourceType.mcpConfiguration);
    expect(controller.selectedResources, isEmpty);
  });

  test('replaceResources keeps destination when selected resource is removed', () {
    final controller = WorkbenchController(
      resources: const [
        WorkbenchResource(
          id: 'prompt-1',
          type: ResourceType.aiPrompt,
          title: '提示词 A',
          subtitle: '',
          isFavorite: false,
        ),
        WorkbenchResource(
          id: 'prompt-2',
          type: ResourceType.aiPrompt,
          title: '提示词 B',
          subtitle: '',
          isFavorite: false,
        ),
        WorkbenchResource(
          id: 'mcp-1',
          type: ResourceType.mcpConfiguration,
          title: 'MCP',
          subtitle: '',
          isFavorite: false,
        ),
      ],
    );

    controller.selectResource(
      const WorkbenchResource(
        id: 'prompt-1',
        type: ResourceType.aiPrompt,
        title: '提示词 A',
        subtitle: '',
        isFavorite: false,
      ),
    );
    expect(controller.selectedDestination, ResourceType.aiPrompt);

    controller.replaceResources(const [
      WorkbenchResource(
        id: 'prompt-2',
        type: ResourceType.aiPrompt,
        title: '提示词 B',
        subtitle: '',
        isFavorite: false,
      ),
      WorkbenchResource(
        id: 'mcp-1',
        type: ResourceType.mcpConfiguration,
        title: 'MCP',
        subtitle: '',
        isFavorite: false,
      ),
    ]);

    expect(controller.selectedDestination, ResourceType.aiPrompt);
    expect(controller.selectedResource.id, 'prompt-2');
  });
}
