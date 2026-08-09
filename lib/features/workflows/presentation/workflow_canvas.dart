import 'package:ai_workbench/features/workflows/application/workflow_canvas_controller.dart';
import 'package:ai_workbench/features/workflows/domain/workflow_layout.dart';
import 'package:ai_workbench/features/workflows/presentation/workflow_edge_painter.dart';
import 'package:ai_workbench/features/workflows/presentation/workflow_minimap.dart';
import 'package:ai_workbench/features/workflows/presentation/workflow_node_card.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

class WorkflowCanvas extends StatefulWidget {
  const WorkflowCanvas({super.key, required this.controller});

  final WorkflowCanvasController controller;

  @override
  State<WorkflowCanvas> createState() => _WorkflowCanvasState();
}

class _WorkflowCanvasState extends State<WorkflowCanvas> {
  late final TransformationController _transform;
  Offset? _marqueeStart;
  Offset? _marqueeEnd;

  @override
  void initState() {
    super.initState();
    _transform = TransformationController();
    widget.controller.addListener(_syncTransform);
    _syncTransform();
  }

  @override
  void didUpdateWidget(covariant WorkflowCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncTransform);
      widget.controller.addListener(_syncTransform);
      _syncTransform();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncTransform);
    _transform.dispose();
    super.dispose();
  }

  void _syncTransform() {
    final viewport = widget.controller.layout?.viewport;
    if (viewport == null) {
      return;
    }
    final matrix = Matrix4.identity()
      ..setEntry(0, 0, viewport.scale)
      ..setEntry(1, 1, viewport.scale)
      ..setEntry(2, 2, 1)
      ..setTranslationRaw(viewport.offsetX, viewport.offsetY, 0);
    if (_transform.value != matrix) {
      _transform.value = matrix;
    }
  }

  void _persistViewport() {
    final matrix = _transform.value;
    final scale = matrix.getMaxScaleOnAxis();
    final translation = matrix.getTranslation();
    widget.controller.setViewport(
      WorkflowViewport(
        offsetX: translation.x,
        offsetY: translation.y,
        scale: scale,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final graph = widget.controller.graph;
        final layout = widget.controller.layout;
        if (graph == null || layout == null) {
          return const Center(child: Text('暂无可用图'));
        }
        return Column(
          children: [
            _CanvasToolbar(controller: widget.controller),
            Expanded(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: widget.controller.clearSelection,
                    onPanStart: (details) {
                      _marqueeStart = details.localPosition;
                      _marqueeEnd = details.localPosition;
                      setState(() {});
                    },
                    onPanUpdate: (details) {
                      _marqueeEnd = details.localPosition;
                      setState(() {});
                    },
                    onPanEnd: (_) {
                      _applyMarquee(layout);
                      _marqueeStart = null;
                      _marqueeEnd = null;
                      setState(() {});
                    },
                    child: InteractiveViewer(
                      constrained: false,
                      minScale: 0.15,
                      maxScale: 4,
                      boundaryMargin: const EdgeInsets.all(100000),
                      transformationController: _transform,
                      onInteractionEnd: (_) {
                        _persistViewport();
                        widget.controller.persist();
                      },
                      child: SizedBox(
                        width: 4000,
                        height: 3000,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CustomPaint(
                              size: const Size(4000, 3000),
                              painter: WorkflowEdgePainter(
                                graph: graph,
                                layout: layout,
                                nodeWidth: widget.controller.nodeWidth,
                                nodeHeight: widget.controller.nodeHeight,
                              ),
                            ),
                            for (final node in graph.nodes)
                              Positioned(
                                left: layout.positions[node.id]!.x,
                                top: layout.positions[node.id]!.y,
                                child: WorkflowNodeCard(
                                  node: node,
                                  selected: widget.controller.selectedNodeIds
                                      .contains(node.id),
                                  width: widget.controller.nodeWidth,
                                  height: widget.controller.nodeHeight,
                                  onSelect: () =>
                                      widget.controller.selectNodes({node.id}),
                                  onDrag: widget.controller.locked
                                      ? null
                                      : (delta) {
                                          final scale = widget.controller.scale
                                              .clamp(0.15, 4.0);
                                          widget.controller.moveNode(
                                            node.id,
                                            delta.dx / scale,
                                            delta.dy / scale,
                                          );
                                        },
                                  onDragEnd: () => widget.controller.persist(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_marqueeStart != null && _marqueeEnd != null)
                    Positioned.fromRect(
                      rect: Rect.fromPoints(_marqueeStart!, _marqueeEnd!),
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0x332F6FED),
                            border: Border.all(color: const Color(0xFF2F6FED)),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: WorkflowMinimap(
                      graph: graph,
                      layout: layout,
                      nodeWidth: widget.controller.nodeWidth,
                      nodeHeight: widget.controller.nodeHeight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _applyMarquee(WorkflowLayout layout) {
    final start = _marqueeStart;
    final end = _marqueeEnd;
    if (start == null || end == null) {
      return;
    }
    final sceneStart = _transform.toScene(start);
    final sceneEnd = _transform.toScene(end);
    final rect = Rect.fromPoints(sceneStart, sceneEnd);
    final selected = <String>{};
    for (final entry in layout.positions.entries) {
      final nodeRect = Rect.fromLTWH(
        entry.value.x,
        entry.value.y,
        widget.controller.nodeWidth,
        widget.controller.nodeHeight,
      );
      if (rect.overlaps(nodeRect)) {
        selected.add(entry.key);
      }
    }
    widget.controller.selectNodes(selected);
  }
}

class _CanvasToolbar extends StatelessWidget {
  const _CanvasToolbar({required this.controller});

  final WorkflowCanvasController controller;

  @override
  Widget build(BuildContext context) {
    final scalePercent = ((controller.scale) * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          PushButton(
            controlSize: ControlSize.small,
            semanticLabel: '适应视图',
            onPressed: () {
              controller.fitToView();
              controller.persist();
            },
            child: const Text('适应'),
          ),
          PushButton(
            controlSize: ControlSize.small,
            semanticLabel: '缩小',
            onPressed: () {
              final next = (controller.scale / 1.1).clamp(0.15, 4.0);
              controller.setViewport(
                controller.layout!.viewport.copyWith(scale: next),
              );
              controller.persist();
            },
            child: const Text('−'),
          ),
          Text('$scalePercent%', semanticsLabel: '缩放比例'),
          PushButton(
            controlSize: ControlSize.small,
            semanticLabel: '放大',
            onPressed: () {
              final next = (controller.scale * 1.1).clamp(0.15, 4.0);
              controller.setViewport(
                controller.layout!.viewport.copyWith(scale: next),
              );
              controller.persist();
            },
            child: const Text('+'),
          ),
          PushButton(
            controlSize: ControlSize.small,
            semanticLabel: controller.locked ? '解锁画布' : '锁定画布',
            onPressed: () => controller.setLocked(!controller.locked),
            child: Text(controller.locked ? '解锁' : '锁定'),
          ),
        ],
      ),
    );
  }
}
