import 'package:ai_workbench/features/editor/presentation/text_editor_workspace.dart';
import 'package:ai_workbench/features/mcp/application/mcp_controller.dart';
import 'package:ai_workbench/features/mcp/domain/json_diagnostic.dart';
import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:macos_ui/macos_ui.dart';

class McpWorkspace extends StatelessWidget {
  const McpWorkspace({
    super.key,
    this.controller,
    this.fallback,
    this.onRenamed,
  });

  final McpController? controller;
  final Widget? fallback;
  final Future<void> Function(String relativePath)? onRenamed;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null) {
      return fallback ?? const _MockMcpSurface();
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final session = controller.session;
        if (session == null) {
          return fallback ?? const _MockMcpSurface();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _McpTitleBar(controller: controller, onRenamed: onRenamed),
            _McpActionsBar(controller: controller),
            if (controller.diagnostic != null)
              _DiagnosticBanner(diagnostic: controller.diagnostic!),
            Expanded(
              child: TextEditorWorkspace(session: session, title: 'MCP JSON'),
            ),
          ],
        );
      },
    );
  }
}

class _McpTitleBar extends StatefulWidget {
  const _McpTitleBar({required this.controller, this.onRenamed});

  final McpController controller;
  final Future<void> Function(String relativePath)? onRenamed;

  @override
  State<_McpTitleBar> createState() => _McpTitleBarState();
}

class _McpTitleBarState extends State<_McpTitleBar> {
  late final TextEditingController _titleController;
  String? _boundDocumentId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.controller.document?.title ?? '',
    );
    _boundDocumentId = widget.controller.document?.id;
  }

  @override
  void didUpdateWidget(covariant _McpTitleBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final document = widget.controller.document;
    if (document != null && document.id != _boundDocumentId) {
      _boundDocumentId = document.id;
      _titleController.text = document.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveTitle() async {
    final renamed = await widget.controller.rename(_titleController.text);
    await widget.onRenamed?.call(renamed.relativePath);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Row(
        children: [
          Expanded(
            child: WorkbenchInput(
              controller: _titleController,
              placeholder: '输入标题',
              semanticLabel: 'MCP 标题',
              onSubmitted: (_) => _saveTitle(),
            ),
          ),
          const SizedBox(width: 8),
          WorkbenchIconButton(
            width: 34,
            height: 34,
            iconSize: 16,
            variant: WorkbenchButtonVariant.primary,
            tooltip: '保存标题',
            semanticLabel: '保存标题',
            onPressed: widget.controller.document == null ? null : _saveTitle,
            icon: const Icon(LucideIcons.check),
          ),
        ],
      ),
    );
  }
}

class _McpActionsBar extends StatelessWidget {
  const _McpActionsBar({required this.controller});

  final McpController controller;

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          WorkbenchIconButton(
            width: 34,
            height: 34,
            iconSize: 16,
            variant: WorkbenchButtonVariant.primary,
            tooltip: '格式化',
            semanticLabel: '格式化',
            onPressed: () => controller.format(),
            icon: const Icon(LucideIcons.alignLeft),
          ),
          WorkbenchIconButton(
            width: 34,
            height: 34,
            iconSize: 16,
            variant: WorkbenchButtonVariant.outline,
            tooltip: '复制安全模板',
            semanticLabel: '复制安全模板',
            onPressed: () => controller.copySafeTemplate(),
            icon: const Icon(LucideIcons.shield),
          ),
          MacosTooltip(
            message: '完整配置复制需 Phase 5 SecretStore',
            child: WorkbenchIconButton(
              width: 34,
              height: 34,
              iconSize: 16,
              variant: WorkbenchButtonVariant.outline,
              tooltip: '复制完整配置',
              semanticLabel: '复制完整配置',
              onPressed: null,
              icon: const Icon(LucideIcons.copy),
            ),
          ),
          WorkbenchIconButton(
            width: 34,
            height: 34,
            iconSize: 16,
            variant: WorkbenchButtonVariant.outline,
            tooltip: '在终端打开',
            semanticLabel: '在终端打开',
            onPressed: () => controller.openTerminal(),
            icon: const Icon(LucideIcons.terminal),
          ),
          WorkbenchIconButton(
            width: 34,
            height: 34,
            iconSize: 16,
            variant: WorkbenchButtonVariant.outline,
            tooltip: '创建副本',
            semanticLabel: '创建副本',
            onPressed: () => controller.duplicate(),
            icon: const Icon(LucideIcons.copyPlus),
          ),
          WorkbenchIconButton(
            width: 34,
            height: 34,
            iconSize: 16,
            variant: WorkbenchButtonVariant.destructive,
            tooltip: '移到回收站',
            semanticLabel: '移到回收站',
            onPressed: () => controller.moveToTrash(),
            icon: const Icon(LucideIcons.trash2),
          ),
          if (controller.lastTrashPath != null)
            WorkbenchIconButton(
              width: 34,
              height: 34,
              iconSize: 16,
              variant: WorkbenchButtonVariant.outline,
              tooltip: '撤销回收',
              semanticLabel: '撤销回收',
              onPressed: () => controller.undoTrash(),
              icon: const Icon(LucideIcons.undo2),
            ),
          if (controller.statusMessage != null)
            Text(controller.statusMessage!, style: typography.caption1),
        ],
      ),
    );
  }
}

class _DiagnosticBanner extends StatelessWidget {
  const _DiagnosticBanner({required this.diagnostic});

  final JsonDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'JSON 错误 · 第 ${diagnostic.line} 行第 ${diagnostic.column} 列：${diagnostic.message}',
        style: MacosTheme.of(
          context,
        ).typography.caption1.copyWith(color: MacosColors.systemRedColor),
      ),
    );
  }
}

class _MockMcpSurface extends StatelessWidget {
  const _MockMcpSurface();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 420),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MacosTheme.of(context).dividerColor),
      ),
      child: Text(
        '打开 Vault 中的 MCP 配置以编辑 JSON。',
        style: MacosTheme.of(context).typography.body,
      ),
    );
  }
}
