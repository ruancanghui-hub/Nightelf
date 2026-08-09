import 'package:ai_workbench/shared/ui/workbench_icon_button.dart';
import 'package:ai_workbench/shared/ui/workbench_shad_scope.dart';
import 'package:flutter/widgets.dart';

/// Data for one closable workspace tab chip.
class WorkbenchTabItem {
  const WorkbenchTabItem({
    required this.id,
    required this.label,
    required this.selected,
    required this.onActivate,
    required this.onClose,
    this.focusKey,
    this.indicatorKey,
  });

  final String id;
  final String label;
  final bool selected;
  final VoidCallback onActivate;
  final VoidCallback onClose;
  final Key? focusKey;
  final Key? indicatorKey;
}

/// Horizontal capsule tab strip styled like shadcn tabs (closable chips).
class WorkbenchTabBar extends StatelessWidget {
  const WorkbenchTabBar({
    required this.items,
    this.height = 64,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 12),
    this.focusRingBuilder,
    super.key,
  });

  final List<WorkbenchTabItem> items;
  final double height;
  final EdgeInsetsGeometry padding;

  /// Optional wrapper around each whole tab chip (e.g. WorkbenchFocusRing).
  final Widget Function(
    BuildContext context,
    WorkbenchTabItem item,
    Widget child,
  )?
  focusRingBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: const BoxDecoration(
        color: WorkbenchUiTokens.canvas,
        border: Border(
          bottom: BorderSide(color: Color(0xFF123127)),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final chip = _WorkbenchTabChip(item: item);
          final wrapped = focusRingBuilder == null
              ? chip
              : focusRingBuilder!(context, item, chip);
          return Align(alignment: Alignment.center, child: wrapped);
        },
      ),
    );
  }
}

class _WorkbenchTabChip extends StatelessWidget {
  const _WorkbenchTabChip({required this.item});

  final WorkbenchTabItem item;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    return Container(
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: item.selected ? WorkbenchUiTokens.emerald : null,
        borderRadius: radius,
        border: Border.all(
          color: item.selected
              ? WorkbenchUiTokens.emerald
              : WorkbenchUiTokens.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            selected: item.selected,
            label: '激活标签页：${item.label}',
            container: true,
            excludeSemantics: true,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: item.onActivate,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: item.selected
                          ? WorkbenchUiTokens.canvas
                          : WorkbenchUiTokens.foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          WorkbenchIconButton(
            semanticLabel: '关闭标签页：${item.label}',
            tooltip: '关闭标签页',
            width: 22,
            height: 22,
            iconSize: 13,
            icon: Text(
              '×',
              style: TextStyle(
                color: item.selected
                    ? WorkbenchUiTokens.canvas
                    : WorkbenchUiTokens.muted,
                fontSize: 13,
                height: 1,
              ),
            ),
            onPressed: item.onClose,
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}
