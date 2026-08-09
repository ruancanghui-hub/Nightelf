import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:ai_workbench/features/workflows/domain/workflow_graph.dart';
import 'package:ai_workbench/features/workflows/domain/workflow_layout.dart';
import 'package:flutter/widgets.dart';

class WorkflowEdgePainter extends CustomPainter {
  const WorkflowEdgePainter({
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
    for (final edge in graph.edges) {
      final from = layout.positions[edge.fromId];
      final to = layout.positions[edge.toId];
      if (from == null || to == null) {
        continue;
      }
      final start = Offset(from.x + nodeWidth / 2, from.y + nodeHeight / 2);
      final end = Offset(to.x + nodeWidth / 2, to.y + nodeHeight / 2);
      final paint = Paint()
        ..color = const Color(0xFF8A8A8A)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      if (edge.style == WorkflowEdgeStyle.dotted) {
        _drawDashed(canvas, start, end, paint);
      } else {
        canvas.drawLine(start, end, paint);
      }
      _drawArrow(canvas, start, end, paint);
      if (edge.label.isNotEmpty) {
        final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
        final builder = ui.ParagraphBuilder(
          ui.ParagraphStyle(fontSize: 11, textAlign: TextAlign.center),
        )..addText(edge.label);
        final paragraph = builder.build()
          ..layout(const ui.ParagraphConstraints(width: 120));
        canvas.drawParagraph(
          paragraph,
          Offset(mid.dx - 60, mid.dy - paragraph.height - 4),
        );
      }
    }
  }

  void _drawDashed(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dash = 6.0;
    const gap = 4.0;
    final distance = (end - start).distance;
    if (distance == 0) {
      return;
    }
    final direction = (end - start) / distance;
    var traveled = 0.0;
    while (traveled < distance) {
      final from = start + direction * traveled;
      final to = start + direction * math.min(traveled + dash, distance);
      canvas.drawLine(from, to, paint);
      traveled += dash + gap;
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const size = 8.0;
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - size * math.cos(angle - 0.4),
        end.dy - size * math.sin(angle - 0.4),
      )
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - size * math.cos(angle + 0.4),
        end.dy - size * math.sin(angle + 0.4),
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WorkflowEdgePainter oldDelegate) {
    return oldDelegate.graph != graph ||
        oldDelegate.layout != layout ||
        oldDelegate.nodeWidth != nodeWidth ||
        oldDelegate.nodeHeight != nodeHeight;
  }
}
