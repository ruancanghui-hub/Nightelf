import 'package:ai_workbench/features/shell/application/workbench_controller.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toggleFavorite updates state and returns ids', () {
    final controller = WorkbenchController(
      resources: const [
        WorkbenchResource(
          id: 'a',
          type: ResourceType.aiPrompt,
          title: 'A',
          subtitle: '',
          isFavorite: false,
        ),
        WorkbenchResource(
          id: 'b',
          type: ResourceType.mcpConfiguration,
          title: 'B',
          subtitle: '',
          isFavorite: true,
        ),
      ],
    );

    expect(controller.toggleFavorite('a'), {'a', 'b'});
    expect(controller.resourceById('a')!.isFavorite, isTrue);
    expect(controller.toggleFavorite('b'), {'a'});
    controller.applyFavoriteIds({'b'});
    expect(controller.favoriteResources.map((e) => e.id), ['b']);
  });
}
