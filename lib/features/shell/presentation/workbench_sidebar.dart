import 'package:ai_workbench/features/shell/application/workbench_controller.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// Navigation and deterministic quick-access sections for the shell.
class WorkbenchSidebar extends StatefulWidget {
  const WorkbenchSidebar({
    required this.controller,
    required this.onDestinationSelected,
    super.key,
  });

  final WorkbenchController controller;
  final ValueChanged<ResourceType> onDestinationSelected;

  @override
  State<WorkbenchSidebar> createState() => _WorkbenchSidebarState();
}

class _WorkbenchSidebarState extends State<WorkbenchSidebar> {
  late final Map<ResourceType, FocusNode> _focusNodes = {
    for (final type in ResourceType.values)
      type: FocusNode(debugLabel: 'sidebar-${type.name}'),
  };

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _handleKey(ResourceType type, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      widget.onDestinationSelected(type);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;

    return Container(
      width: 248,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        border: Border(
          right: BorderSide(color: MacosTheme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('资源库', style: typography.headline),
          const SizedBox(height: 12),
          for (final type in ResourceType.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Focus(
                key: ValueKey('sidebar-focus-${type.name}'),
                focusNode: _focusNodes[type],
                onKeyEvent: (_, event) => _handleKey(type, event),
                child: PushButton(
                  controlSize: ControlSize.large,
                  color: type == widget.controller.selectedDestination
                      ? MacosTheme.of(context).primaryColor
                      : null,
                  semanticLabel: '导航：${widget.controller.labelFor(type)}',
                  onPressed: () => widget.onDestinationSelected(type),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(widget.controller.labelFor(type)),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 18),
          Text('收藏', style: typography.subheadline),
          const SizedBox(height: 6),
          for (final resource in widget.controller.favoriteResources.take(2))
            Text(resource.title, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 18),
          Text('最近使用', style: typography.subheadline),
          const SizedBox(height: 6),
          for (final resource in widget.controller.recentResources.take(2))
            Text(resource.title, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
