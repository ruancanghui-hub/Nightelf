import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// The static top toolbar for the mock workbench shell.
class WorkbenchToolbar extends StatelessWidget {
  const WorkbenchToolbar({super.key});

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
            message: '全局搜索将在后续版本提供',
            child: Semantics(
              label: '打开全局搜索',
              container: true,
              child: PushButton(
                controlSize: ControlSize.large,
                onPressed: null,
                semanticLabel: '打开全局搜索',
                child: Row(
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
              label: '同步不可用',
              container: true,
              child: PushButton(
                controlSize: ControlSize.large,
                onPressed: null,
                semanticLabel: '同步不可用',
                child: Text('未配置同步'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          MacosTooltip(
            message: '历史记录将在后续版本提供',
            child: Semantics(
              label: '查看历史记录',
              container: true,
              child: MacosIconButton(
                icon: Text('◷'),
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
                icon: Text('☷'),
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
