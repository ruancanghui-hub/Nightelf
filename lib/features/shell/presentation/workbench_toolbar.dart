import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// The static top toolbar for the mock workbench shell.
class WorkbenchToolbar extends StatelessWidget {
  const WorkbenchToolbar({
    this.onGlobalSearch,
    this.onToggleInspector,
    this.inspectorVisible = true,
    super.key,
  });

  final VoidCallback? onGlobalSearch;
  final VoidCallback? onToggleInspector;
  final bool inspectorVisible;

  @override
  Widget build(BuildContext context) {
    final colors = MacosTheme.of(context).typography;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MacosTheme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('我的 AI 工作台', style: colors.headline),
              Text('AI Workbench', style: colors.caption1),
            ],
          ),
          const Spacer(),
          MacosTooltip(
            message: '打开命令面板',
            child: Semantics(
              label: '搜索资源',
              container: true,
              child: PushButton(
                controlSize: ControlSize.large,
                onPressed: onGlobalSearch,
                semanticLabel: '搜索资源',
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text('全局搜索'), SizedBox(width: 20), Text('⌘K')],
                ),
              ),
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
                child: const Text('未配置同步'),
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
                icon: const Text('◷'),
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
                icon: const Text('☷'),
                onPressed: null,
                semanticLabel: '切换视图',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
