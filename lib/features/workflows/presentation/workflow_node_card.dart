import 'package:ai_workbench/features/workflows/domain/workflow_graph.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

class WorkflowNodeCard extends StatelessWidget {
  const WorkflowNodeCard({
    super.key,
    required this.node,
    required this.selected,
    required this.width,
    required this.height,
    required this.onSelect,
    this.onDrag,
    this.onDragEnd,
  });

  final WorkflowNode node;
  final bool selected;
  final double width;
  final double height;
  final VoidCallback onSelect;
  final ValueChanged<Offset>? onDrag;
  final VoidCallback? onDragEnd;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final radius = switch (node.shape) {
      WorkflowNodeShape.rounded => 20.0,
      WorkflowNodeShape.diamond => 4.0,
      WorkflowNodeShape.rectangle || WorkflowNodeShape.plain => 8.0,
    };
    return GestureDetector(
      onTap: onSelect,
      onPanUpdate: onDrag == null ? null : (details) => onDrag!(details.delta),
      onPanEnd: onDragEnd == null ? null : (_) => onDragEnd!(),
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.primaryColor.withValues(alpha: 0.22)
              : theme.primaryColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: selected
                ? theme.primaryColor
                : theme.primaryColor.withValues(alpha: 0.35),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          node.label,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.typography.body,
        ),
      ),
    );
  }
}
