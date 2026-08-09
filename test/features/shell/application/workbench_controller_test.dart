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
}
