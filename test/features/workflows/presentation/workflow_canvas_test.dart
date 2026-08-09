import 'package:ai_workbench/features/workflows/application/workflow_canvas_controller.dart';
import 'package:ai_workbench/features/workflows/data/workflow_layout_repository.dart';
import 'package:ai_workbench/features/workflows/domain/workflow_graph.dart';
import 'package:ai_workbench/features/workflows/domain/workflow_layout.dart';
import 'package:ai_workbench/features/workflows/presentation/workflow_canvas.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

class _MemoryLayoutRepository implements WorkflowLayoutRepository {
  WorkflowLayout? stored;

  @override
  Future<void> delete(String workflowId) async => stored = null;

  @override
  Future<WorkflowLayout?> load(String workflowId) async => stored;

  @override
  Future<void> save(WorkflowLayout layout) async => stored = layout;
}

void main() {
  testWidgets('canvas renders nodes and selects via controller', (
    tester,
  ) async {
    final repository = _MemoryLayoutRepository();
    final controller = WorkflowCanvasController(layoutRepository: repository);
    const graph = WorkflowGraph(
      direction: WorkflowDirection.leftRight,
      nodes: [
        WorkflowNode(
          id: 'a',
          label: '读取变更',
          shape: WorkflowNodeShape.rectangle,
        ),
        WorkflowNode(
          id: 'b',
          label: '生成说明',
          shape: WorkflowNodeShape.rectangle,
        ),
      ],
      edges: [WorkflowEdge(id: 'e1', fromId: 'a', toId: 'b')],
    );
    await controller.loadGraph(workflowId: 'w1', graph: graph);
    controller.fitToView();

    await tester.pumpWidget(
      MacosApp(
        home: MacosWindow(
          child: SizedBox(
            width: 900,
            height: 600,
            child: WorkflowCanvas(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('读取变更'), findsOneWidget);
    expect(find.text('生成说明'), findsOneWidget);
    controller.selectNodes({'a'});
    await tester.pump();
    expect(controller.selectedNodeIds, {'a'});
    expect(find.text('适应'), findsOneWidget);
  });
}
