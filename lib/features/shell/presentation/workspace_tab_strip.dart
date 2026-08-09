import 'package:ai_workbench/features/shell/application/workspace_tabs_controller.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_focus_ring.dart';
import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:flutter/widgets.dart';

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
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return WorkbenchTabBar(
          items: [
            for (final tab in controller.tabs)
              WorkbenchTabItem(
                id: tab.resourceId,
                label: tab.title,
                selected: tab.resourceId == controller.activeResourceId,
                onActivate: () => onTabActivated(tab.resourceId),
                onClose: () => onTabClosed(tab.resourceId),
                focusKey: ValueKey('tab-focus-${tab.resourceId}'),
                indicatorKey: ValueKey(
                  'tab-focus-${tab.resourceId}-indicator',
                ),
              ),
          ],
          focusRingBuilder: (context, item, child) {
            final focusKey = item.focusKey;
            final indicatorKey = item.indicatorKey;
            if (focusKey == null || indicatorKey == null) {
              return child;
            }
            return WorkbenchFocusRing(
              focusKey: focusKey,
              indicatorKey: indicatorKey,
              onActivate: item.onActivate,
              borderRadius: BorderRadius.circular(999),
              child: child,
            );
          },
        );
      },
    );
  }
}
