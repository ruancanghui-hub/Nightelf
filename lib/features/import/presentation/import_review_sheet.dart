import 'package:ai_workbench/features/import/application/import_controller.dart';
import 'package:ai_workbench/features/vault/domain/vault_handle.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path/path.dart' as p;

class ImportReviewSheet extends StatelessWidget {
  const ImportReviewSheet({
    super.key,
    required this.controller,
    required this.vault,
    this.onClose,
  });

  final ImportController controller;
  final VaultHandle vault;
  final VoidCallback? onClose;

  static const typeLabels = <ResourceType, String>{
    ResourceType.prompt: 'AI 提示词',
    ResourceType.skill: 'SKILL 文件夹',
    ResourceType.mcp: 'MCP 配置',
    ResourceType.link: '网站链接',
    ResourceType.workflow: 'Workflow 文件',
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final typography = MacosTheme.of(context).typography;
        return ColoredBox(
          color: MacosTheme.of(context).canvasColor.withValues(alpha: 0.96),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720, maxHeight: 560),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text('审核导入', style: typography.title2),
                        const Spacer(),
                        PushButton(
                          controlSize: ControlSize.small,
                          secondary: true,
                          onPressed: controller.isImporting
                              ? null
                              : () {
                                  controller.cancel();
                                  onClose?.call();
                                },
                          child: const Text('关闭'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '确认类型与目标名称后，将复制到当前 Vault。源文件不会被修改。',
                      style: typography.body,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: controller.plan.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = controller.plan.items[index];
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: MacosTheme.of(context).dividerColor,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.basename(item.candidate.sourcePath),
                                    style: typography.headline,
                                  ),
                                  Text(
                                    item.candidate.reason,
                                    style: typography.caption1,
                                  ),
                                  Text(
                                    '目标：${item.targetBasename}',
                                    style: typography.caption2,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final type in ResourceType.values)
                                        PushButton(
                                          controlSize: ControlSize.small,
                                          secondary: item.selectedType != type,
                                          onPressed: () =>
                                              controller.setType(index, type),
                                          child: Text(typeLabels[type]!),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  PushButton(
                                    controlSize: ControlSize.small,
                                    secondary: true,
                                    onPressed: () => controller.remove(index),
                                    child: const Text('移除'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (controller.statusMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(controller.statusMessage!),
                    ],
                    if (controller.results.any((result) => !result.succeeded))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final result in controller.results.where(
                              (result) => !result.succeeded,
                            ))
                              Text(
                                '失败：${p.basename(result.item.candidate.sourcePath)} — ${result.failureReason ?? '未知错误'}',
                                style: typography.caption1,
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        PushButton(
                          controlSize: ControlSize.large,
                          secondary: true,
                          onPressed: controller.isImporting
                              ? null
                              : () {
                                  controller.cancel();
                                  onClose?.call();
                                },
                          child: const Text('取消'),
                        ),
                        const Spacer(),
                        Semantics(
                          label: '复制到 Vault',
                          button: true,
                          child: PushButton(
                            controlSize: ControlSize.large,
                            onPressed: controller.canConfirm
                                ? () async {
                                    await controller.confirm(vault);
                                    if (controller.plan.items.isEmpty) {
                                      onClose?.call();
                                    }
                                  }
                                : null,
                            child: const Text('复制到 Vault'),
                          ),
                        ),
                      ],
                    ),
                    if (!controller.canConfirm &&
                        controller.plan.items.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '请为所有选中项选择资源类型后再导入',
                          style: typography.caption1,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
