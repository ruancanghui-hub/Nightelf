import 'package:ai_workbench/shared/ui/workbench_shad_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Capsule search trigger that opens the command palette (⌘K).
class WorkbenchSearchTrigger extends StatelessWidget {
  const WorkbenchSearchTrigger({
    this.onTap,
    this.placeholder = '搜索你的所有资源（提示词 / 文件夹 / 配置 / 链接 / 工作流）',
    this.height = 42,
    this.maxWidth = 880,
    super.key,
  });

  final VoidCallback? onTap;
  final String placeholder;
  final double height;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '搜索资源',
      textField: true,
      button: true,
      container: true,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: height,
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: WorkbenchUiTokens.searchFill,
              border: Border.all(color: WorkbenchUiTokens.border),
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.search,
                  color: WorkbenchUiTokens.muted,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    placeholder,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: WorkbenchUiTokens.muted,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: WorkbenchUiTokens.chipFill,
                    border: Border.all(color: WorkbenchUiTokens.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '⌘K',
                    style: TextStyle(
                      color: WorkbenchUiTokens.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
