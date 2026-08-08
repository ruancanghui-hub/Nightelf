import 'package:ai_workbench/features/shell/application/workspace_tabs_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// An accessible tab strip for the resources opened in this mock session.
class WorkspaceTabStrip extends StatelessWidget {
  const WorkspaceTabStrip({
    required this.controller,
    required this.onTabActivated,
    required this.onTabClosed,
    super.key,
  });

  final WorkspaceTabsController controller;
  final ValueChanged<String> onTabActivated;
  final ValueChanged<String> onTabClosed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 6),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        border: Border(
          bottom: BorderSide(color: MacosTheme.of(context).dividerColor),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final tab = controller.tabs[index];
          final isActive = tab.resourceId == controller.activeResourceId;

          return Container(
            decoration: BoxDecoration(
              color: isActive
                  ? MacosTheme.of(context).primaryColor.withValues(alpha: 0.14)
                  : null,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: MacosTheme.of(context).dividerColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PushButton(
                  controlSize: ControlSize.regular,
                  semanticLabel: '激活标签页：${tab.title}',
                  onPressed: () => onTabActivated(tab.resourceId),
                  child: Text(tab.title),
                ),
                MacosIconButton(
                  icon: const Text('×'),
                  semanticLabel: '关闭标签页：${tab.title}',
                  onPressed: () => onTabClosed(tab.resourceId),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
