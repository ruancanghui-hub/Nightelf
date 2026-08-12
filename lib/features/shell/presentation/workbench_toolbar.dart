import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The static top toolbar for the mock workbench shell.
class WorkbenchToolbar extends StatelessWidget {
  const WorkbenchToolbar({
    this.onGlobalSearch,
    this.onToggleInspector,
    this.onSyncVault,
    this.inspectorVisible = true,
    this.showActions = true,
    super.key,
  });

  final VoidCallback? onGlobalSearch;
  final VoidCallback? onToggleInspector;
  final VoidCallback? onSyncVault;
  final bool inspectorVisible;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
      decoration: const BoxDecoration(
        color: WorkbenchUiTokens.canvas,
        border: Border(bottom: BorderSide(color: Color(0xFF123127))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: WorkbenchSearchTrigger(onTap: onGlobalSearch),
            ),
          ),
          if (showActions) ...[
            const SizedBox(width: 16),
            WorkbenchIconButton(
              tooltip: '打开命令面板',
              semanticLabel: '打开命令面板',
              icon: const Icon(LucideIcons.command, size: 18),
              onPressed: onGlobalSearch,
            ),
            const SizedBox(width: 8),
            WorkbenchButton(
              size: WorkbenchButtonSize.sm,
              variant: WorkbenchButtonVariant.outline,
              semanticLabel: '同步',
              onPressed: onSyncVault,
              leading: const Icon(LucideIcons.refreshCw, size: 16),
              child: const Text('同步'),
            ),
            if (onToggleInspector != null) ...[
              const SizedBox(width: 8),
              WorkbenchButton(
                size: WorkbenchButtonSize.sm,
                variant: WorkbenchButtonVariant.ghost,
                semanticLabel: '切换检查器',
                onPressed: onToggleInspector,
                child: Text(inspectorVisible ? '隐藏检查器' : '显示检查器'),
              ),
            ],
            const SizedBox(width: 8),
            WorkbenchIconButton(
              tooltip: '历史记录将在后续版本提供',
              semanticLabel: '查看历史记录',
              icon: const Icon(LucideIcons.history, size: 18),
              onPressed: null,
            ),
            const SizedBox(width: 4),
            WorkbenchIconButton(
              tooltip: '视图切换将在后续版本提供',
              semanticLabel: '切换视图',
              icon: const Icon(LucideIcons.panelRight, size: 18),
              onPressed: null,
            ),
          ],
        ],
      ),
    );
  }
}
