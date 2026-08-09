import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:macos_ui/macos_ui.dart';

/// The static top toolbar for the mock workbench shell.
class WorkbenchToolbar extends StatelessWidget {
  const WorkbenchToolbar({
    this.onGlobalSearch,
    this.onToggleInspector,
    this.inspectorVisible = true,
    this.showActions = true,
    super.key,
  });

  final VoidCallback? onGlobalSearch;
  final VoidCallback? onToggleInspector;
  final bool inspectorVisible;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF030B09),
        border: const Border(bottom: BorderSide(color: Color(0xFF123127))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: '搜索资源',
              textField: true,
              child: GestureDetector(
                onTap: onGlobalSearch,
                child: Container(
                  height: 48,
                  constraints: const BoxConstraints(maxWidth: 880),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF07120F),
                    border: Border.all(color: const Color(0xFF1B4D40)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        LucideIcons.search,
                        color: Color(0xFF9BB4AB),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '搜索你的所有资源（提示词 / 文件夹 / 配置 / 链接 / 工作流）',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF9BB4AB),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '⌘K',
                        style: TextStyle(
                          color: Color(0xFF9BB4AB),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (showActions) ...[
            const SizedBox(width: 16),
            MacosTooltip(
              message: '打开命令面板',
              child: PushButton(
                controlSize: ControlSize.large,
                onPressed: onGlobalSearch,
                semanticLabel: '打开命令面板',
                child: const Icon(LucideIcons.command, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            MacosTooltip(
              message: '同步尚未配置',
              child: Semantics(
                label: '同步',
                container: true,
                child: PushButton(
                  controlSize: ControlSize.large,
                  onPressed: null,
                  semanticLabel: '同步',
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.refreshCw, size: 16),
                      SizedBox(width: 8),
                      Text('同步'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (onToggleInspector != null) ...[
              MacosTooltip(
                message: inspectorVisible ? '隐藏检查器' : '显示检查器',
                child: Semantics(
                  label: '切换检查器',
                  container: true,
                  child: PushButton(
                    controlSize: ControlSize.large,
                    secondary: true,
                    onPressed: onToggleInspector,
                    semanticLabel: '切换检查器',
                    child: Text(inspectorVisible ? '隐藏检查器' : '显示检查器'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            MacosTooltip(
              message: '历史记录将在后续版本提供',
              child: Semantics(
                label: '查看历史记录',
                container: true,
                child: MacosIconButton(
                  icon: const Icon(LucideIcons.history),
                  onPressed: null,
                  semanticLabel: '查看历史记录',
                ),
              ),
            ),
            const SizedBox(width: 8),
            MacosTooltip(
              message: '视图切换将在后续版本提供',
              child: Semantics(
                label: '切换视图',
                container: true,
                child: MacosIconButton(
                  icon: const Icon(LucideIcons.panelRight),
                  onPressed: null,
                  semanticLabel: '切换视图',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
