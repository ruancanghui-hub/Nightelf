import 'package:ai_workbench/features/workflows/domain/workflow_graph.dart';
import 'package:ai_workbench/features/workflows/domain/workflow_layout.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

class WorkflowMinimap extends StatelessWidget {
  const WorkflowMinimap({
    super.key,
    required this.graph,
    required this.layout,
    required this.nodeWidth,
    required this.nodeHeight,
  });

  final WorkflowGraph graph;
  final WorkflowLayout layout;
  final double nodeWidth;
  final double nodeHeight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '画布缩略图',
      child: Container(
        width: 140,
        height: 96,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: MacosTheme.of(context).canvasColor.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: MacosTheme.of(context).dividerColor),
        ),
        child: CustomPaint(
          painter: _MinimapPainter(
            graph: graph,
            layout: layout,
            nodeWidth: nodeWidth,
            nodeHeight: nodeHeight,
          ),
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  const _MinimapPainter({
    required this.graph,
    required this.layout,
    required this.nodeWidth,
    required this.nodeHeight,
  });

  final WorkflowGraph graph;
  final WorkflowLayout layout;
  final double nodeWidth;
  final double nodeHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (graph.nodes.isEmpty) {
      return;
    }
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    for (final node in graph.nodes) {
      final point = layout.positions[node.id]!;
      minX = minX < point.x ? minX : point.x;
      minY = minY < point.y ? minY : point.y;
      maxX = maxX > point.x + nodeWidth ? maxX : point.x + nodeWidth;
      maxY = maxY > point.y + nodeHeight ? maxY : point.y + nodeHeight;
    }
    final worldW = (maxX - minX).clamp(1, double.infinity);
    final worldH = (maxY - minY).clamp(1, double.infinity);
    final scale = (size.width / worldW < size.height / worldH)
        ? size.width / worldW
        : size.height / worldH;
    final paint = Paint()..color = const Color(0xFF2F6FED);
    for (final node in graph.nodes) {
      final point = layout.positions[node.id]!;
      canvas.drawRect(
        Rect.fromLTWH(
          (point.x - minX) * scale,
          (point.y - minY) * scale,
          nodeWidth * scale * 0.35,
          nodeHeight * scale * 0.35,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter oldDelegate) {
    return oldDelegate.layout != layout || oldDelegate.graph != graph;
  }
}
