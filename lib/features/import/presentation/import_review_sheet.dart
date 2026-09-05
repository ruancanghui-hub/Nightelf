import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:ai_workbench/features/import/application/import_controller.dart';
import 'package:ai_workbench/features/import/domain/import_plan.dart';
import 'package:ai_workbench/features/vault/data/vault_paths.dart';
import 'package:ai_workbench/features/vault/domain/vault_handle.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path/path.dart' as p;

class ImportReviewSheet extends StatefulWidget {
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

  static const importableTypes = [
    ResourceType.prompt,
    ResourceType.skill,
    ResourceType.mcp,
    ResourceType.link,
    ResourceType.workflow,
  ];

  @override
  State<ImportReviewSheet> createState() => _ImportReviewSheetState();
}

class _ImportReviewSheetState extends State<ImportReviewSheet> {
  static const _overlay = Color(0xF2030B09);
  static const _dialog = Color(0xFF07130F);
  static const _panel = Color(0xFF0A1916);
  static const _raised = Color(0xFF0C211A);
  static const _border = Color(0xFF1B4D40);
  static const _muted = Color(0xFF9BB4AB);
  static const _foreground = Color(0xFFF2FFF8);
  static const _emerald = Color(0xFF5DE7A7);

  late final TextEditingController _targetController;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController();
    widget.controller.addListener(_handleControllerChanged);
    _syncFromPlan();
  }

  @override
  void didUpdateWidget(covariant ImportReviewSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
      _activeIndex = 0;
      _syncFromPlan();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _targetController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(_syncFromPlan);
  }

  void _syncFromPlan() {
    final items = widget.controller.plan.items;
    if (items.isEmpty) {
      _activeIndex = 0;
      _targetController.clear();
      return;
    }
    _activeIndex = _activeIndex.clamp(0, items.length - 1);
    final target = items[_activeIndex].targetBasename;
    if (_targetController.text != target) {
      _targetController.value = TextEditingValue(
        text: target,
        selection: TextSelection.collapsed(offset: target.length),
      );
    }
  }

  void _cancel() {
    if (widget.controller.isImporting) {
      return;
    }
    widget.controller.cancel();
    widget.onClose?.call();
  }

  Future<void> _confirm() async {
    if (!widget.controller.canConfirm) {
      return;
    }
    await widget.controller.confirm(widget.vault);
    if (widget.controller.plan.items.isEmpty) {
      widget.onClose?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.controller.plan.items;
    if (items.isEmpty) {
      return const ColoredBox(color: _overlay);
    }
    final item = items[_activeIndex];

    return ColoredBox(
      color: _overlay,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dialogWidth = math.min(960.0, constraints.maxWidth - 48);
          final dialogHeight = math.min(720.0, constraints.maxHeight - 48);
          final compact = dialogWidth < 820;
          return Center(
            child: Container(
              key: const Key('import-review-dialog'),
              width: dialogWidth,
              height: dialogHeight,
              decoration: BoxDecoration(
                color: _dialog,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 34,
                    offset: Offset(0, 18),
                  ),
                  BoxShadow(color: Color(0x1F5DE7A7), blurRadius: 18),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(
                    itemCount: items.length,
                    isImporting: widget.controller.isImporting,
                    onClose: _cancel,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 18 : 28,
                        18,
                        compact ? 18 : 28,
                        18,
                      ),
                      child: compact
                          ? SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _SourcePane(item: item, compact: true),
                                  const SizedBox(height: 16),
                                  _ConfigPane(
                                    item: item,
                                    itemIndex: _activeIndex,
                                    controller: widget.controller,
                                    targetController: _targetController,
                                    vault: widget.vault,
                                    compact: true,
                                  ),
                                ],
                              ),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: _SourcePane(
                                    item: item,
                                    compact: false,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 6,
                                  child: _ConfigPane(
                                    item: item,
                                    itemIndex: _activeIndex,
                                    controller: widget.controller,
                                    targetController: _targetController,
                                    vault: widget.vault,
                                    compact: false,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  _Footer(
                    controller: widget.controller,
                    onCancel: _cancel,
                    onConfirm: _confirm,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.itemCount,
    required this.isImporting,
    required this.onClose,
  });

  final int itemCount;
  final bool isImporting;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 22, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _ImportReviewSheetState._emerald.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              LucideIcons.shieldCheck,
              size: 36,
              color: _ImportReviewSheetState._emerald,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '审核导入',
                      style: TextStyle(
                        color: _ImportReviewSheetState._foreground,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (itemCount > 1) ...[
                      const SizedBox(width: 12),
                      Text(
                        '$itemCount 个文件',
                        style: const TextStyle(
                          color: _ImportReviewSheetState._emerald,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  '确认类型与目标名称后，将复制到当前 Vault。源文件不会被修改。',
                  style: TextStyle(
                    color: _ImportReviewSheetState._muted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          WorkbenchIconButton(
            icon: const Icon(LucideIcons.x),
            semanticLabel: '关闭审核导入',
            tooltip: '关闭',
            onPressed: isImporting ? null : onClose,
          ),
        ],
      ),
    );
  }
}

class _SourcePane extends StatelessWidget {
  const _SourcePane({required this.item, required this.compact});

  final ImportPlanItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final sourceName = p.basename(item.candidate.sourcePath);
    return _ReviewPanel(
      key: const Key('import-source-pane'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '文件信息',
            style: TextStyle(
              color: _ImportReviewSheetState._foreground,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _ImportReviewSheetState._emerald.withValues(
                    alpha: 0.16,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.file,
                  size: 25,
                  color: _ImportReviewSheetState._emerald,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sourceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ImportReviewSheetState._foreground,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _SourceMetadata(item: item),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            '内容预览（前 20 行）',
            style: TextStyle(
              color: _ImportReviewSheetState._muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (compact)
            SizedBox(
              height: 220,
              child: _SourcePreview(
                path: item.candidate.sourcePath,
                isDirectory: item.candidate.isDirectory,
              ),
            )
          else
            Expanded(
              child: _SourcePreview(
                path: item.candidate.sourcePath,
                isDirectory: item.candidate.isDirectory,
              ),
            ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  LucideIcons.shieldCheck,
                  size: 17,
                  color: _ImportReviewSheetState._emerald,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '源文件位置',
                      style: TextStyle(
                        color: _ImportReviewSheetState._foreground,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.candidate.sourcePath,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ImportReviewSheetState._muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      '源文件不会被修改',
                      style: TextStyle(
                        color: _ImportReviewSheetState._muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceMetadata extends StatelessWidget {
  const _SourceMetadata({required this.item});

  final ImportPlanItem item;

  @override
  Widget build(BuildContext context) {
    String detail;
    if (item.candidate.isDirectory) {
      detail = '文件夹';
    } else {
      try {
        detail =
            '${p.extension(item.candidate.sourcePath).replaceFirst('.', '').toUpperCase()} 文件 · ${_formatBytes(File(item.candidate.sourcePath).lengthSync())}';
      } on FileSystemException {
        detail = '文件';
      }
    }
    return Text(
      detail,
      style: const TextStyle(
        color: _ImportReviewSheetState._muted,
        fontSize: 11,
      ),
    );
  }
}

class _SourcePreview extends StatefulWidget {
  const _SourcePreview({required this.path, required this.isDirectory});

  final String path;
  final bool isDirectory;

  @override
  State<_SourcePreview> createState() => _SourcePreviewState();
}

class _SourcePreviewState extends State<_SourcePreview> {
  late Future<List<String>> _lines;

  @override
  void initState() {
    super.initState();
    _lines = _loadLines();
  }

  @override
  void didUpdateWidget(covariant _SourcePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.isDirectory != widget.isDirectory) {
      _lines = _loadLines();
    }
  }

  Future<List<String>> _loadLines() async {
    try {
      if (widget.isDirectory) {
        final entities = await Directory(
          widget.path,
        ).list(followLinks: false).take(20).toList();
        return [for (final entity in entities) p.basename(entity.path)];
      }
      final lines = <String>[];
      await for (final line
          in File(widget.path)
              .openRead()
              .transform(const SystemEncoding().decoder)
              .transform(const LineSplitter())) {
        lines.add(line);
        if (lines.length == 20) {
          break;
        }
      }
      return lines;
    } on Object {
      return const ['无法预览此文件'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF06100D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ImportReviewSheetState._border),
      ),
      child: FutureBuilder<List<String>>(
        future: _lines,
        builder: (context, snapshot) {
          final lines = snapshot.data;
          if (lines == null) {
            return const Center(child: ProgressCircle(radius: 8));
          }
          if (lines.isEmpty) {
            return const Center(
              child: Text(
                '文件为空',
                style: TextStyle(color: _ImportReviewSheetState._muted),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Text(
              [
                for (var index = 0; index < lines.length; index++)
                  '${(index + 1).toString().padLeft(2)}  ${lines[index]}',
              ].join('\n'),
              style: const TextStyle(
                color: Color(0xFFC8DED5),
                fontFamily: 'Menlo',
                fontSize: 11,
                height: 1.55,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConfigPane extends StatelessWidget {
  const _ConfigPane({
    required this.item,
    required this.itemIndex,
    required this.controller,
    required this.targetController,
    required this.vault,
    required this.compact,
  });

  final ImportPlanItem item;
  final int itemIndex;
  final ImportController controller;
  final TextEditingController targetController;
  final VaultHandle vault;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final selected = item.selectedType;
    final targetFolder = selected == null
        ? vault.root.path
        : p.join(vault.root.path, VaultPaths.directoryFor(selected));
    return _ReviewPanel(
      key: const Key('import-config-pane'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: _ImportReviewSheetState._raised,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _ImportReviewSheetState._border),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.slidersHorizontal,
                  color: _ImportReviewSheetState._emerald,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selected == null
                        ? '需要确认资源类型'
                        : '识别为 ${ImportReviewSheet.typeLabels[selected]}',
                    style: const TextStyle(
                      color: _ImportReviewSheetState._foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (item.candidate.suggestedType != null) ...[
                  const Text(
                    '高置信度',
                    style: TextStyle(
                      color: _ImportReviewSheetState._emerald,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    LucideIcons.shieldCheck,
                    color: _ImportReviewSheetState._emerald,
                    size: 15,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const WorkbenchFieldLabel('资源类型'),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final type in ImportReviewSheet.importableTypes)
                WorkbenchButton(
                  semanticLabel: '资源类型：${ImportReviewSheet.typeLabels[type]}',
                  size: WorkbenchButtonSize.sm,
                  variant: selected == type
                      ? WorkbenchButtonVariant.primary
                      : WorkbenchButtonVariant.secondary,
                  onPressed: controller.isImporting
                      ? null
                      : () => controller.setType(itemIndex, type),
                  child: Text(ImportReviewSheet.typeLabels[type]!),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const WorkbenchFieldLabel('目标名称'),
          const SizedBox(height: 9),
          WorkbenchInput(
            key: const Key('import-target-name'),
            controller: targetController,
            enabled: !controller.isImporting,
            semanticLabel: '目标名称',
            onChanged: (value) =>
                controller.rename(itemIndex, targetBasename: value),
          ),
          const SizedBox(height: 6),
          const Text(
            '将作为资源在 Vault 中的名称',
            style: TextStyle(
              color: _ImportReviewSheetState._muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 22),
          const WorkbenchFieldLabel('目标位置'),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF06100D),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _ImportReviewSheetState._border),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.folder,
                  color: _ImportReviewSheetState._emerald,
                  size: 17,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    targetFolder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ImportReviewSheetState._foreground,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            '将复制到当前 Vault',
            style: TextStyle(
              color: _ImportReviewSheetState._muted,
              fontSize: 11,
            ),
          ),
          if (compact) const SizedBox(height: 20) else const Spacer(),
          Text(
            item.candidate.reason,
            style: const TextStyle(
              color: _ImportReviewSheetState._muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.controller,
    required this.onCancel,
    required this.onConfirm,
  });

  final ImportController controller;
  final VoidCallback onCancel;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF091612),
        border: Border(top: BorderSide(color: _ImportReviewSheetState._border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.statusMessage != null) ...[
            Text(
              controller.statusMessage!,
              style: const TextStyle(
                color: _ImportReviewSheetState._muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 9),
          ],
          if (controller.results.any((result) => !result.succeeded)) ...[
            for (final result in controller.results.where(
              (result) => !result.succeeded,
            ))
              Text(
                '失败：${p.basename(result.item.candidate.sourcePath)} — ${result.failureReason ?? '未知错误'}',
                style: const TextStyle(color: Color(0xFFE8848E), fontSize: 12),
              ),
            const SizedBox(height: 9),
          ],
          Row(
            children: [
              WorkbenchButton(
                semanticLabel: '取消导入',
                variant: WorkbenchButtonVariant.outline,
                size: WorkbenchButtonSize.lg,
                onPressed: controller.isImporting ? null : onCancel,
                child: const Text('取消'),
              ),
              const Spacer(),
              WorkbenchButton(
                key: const Key('import-copy-button'),
                semanticLabel: '复制到 Vault',
                size: WorkbenchButtonSize.lg,
                enabled: controller.canConfirm,
                onPressed: controller.canConfirm ? onConfirm : null,
                leading: controller.isImporting
                    ? const ProgressCircle(radius: 7)
                    : const Icon(LucideIcons.copy, size: 17),
                child: Text(controller.isImporting ? '正在复制…' : '复制到 Vault'),
              ),
            ],
          ),
          if (!controller.canConfirm && controller.plan.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                '请为所有选中项选择资源类型后再导入',
                style: TextStyle(
                  color: _ImportReviewSheetState._muted,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _ImportReviewSheetState._panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _ImportReviewSheetState._border),
      ),
      child: child,
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  final kilobytes = bytes / 1024;
  if (kilobytes < 1024) {
    return '${kilobytes.toStringAsFixed(1)} KB';
  }
  return '${(kilobytes / 1024).toStringAsFixed(1)} MB';
}
