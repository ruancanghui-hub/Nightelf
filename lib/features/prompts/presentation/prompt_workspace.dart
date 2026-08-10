import 'package:ai_workbench/features/editor/presentation/text_editor_workspace.dart';
import 'package:ai_workbench/features/prompts/application/prompt_controller.dart';
import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:macos_ui/macos_ui.dart';

/// Prompt workspace with copy/duplicate/trash actions over a live editor.
class PromptWorkspace extends StatelessWidget {
  const PromptWorkspace({
    super.key,
    this.controller,
    this.fallback,
    this.onRenamed,
  });

  final PromptController? controller;
  final Widget? fallback;
  final Future<void> Function(String relativePath)? onRenamed;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null) {
      return fallback ?? const _MockPromptSurface();
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final session = controller.session;
        if (session == null) {
          return fallback ?? const _MockPromptSurface();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PromptTitleBar(controller: controller, onRenamed: onRenamed),
            _PromptActionsBar(controller: controller),
            Expanded(
              child: TextEditorWorkspace(session: session, title: '提示词源码'),
            ),
          ],
        );
      },
    );
  }
}

class _PromptTitleBar extends StatefulWidget {
  const _PromptTitleBar({required this.controller, this.onRenamed});

  final PromptController controller;
  final Future<void> Function(String relativePath)? onRenamed;

  @override
  State<_PromptTitleBar> createState() => _PromptTitleBarState();
}

class _PromptTitleBarState extends State<_PromptTitleBar> {
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
  void didUpdateWidget(covariant _PromptTitleBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final document = widget.controller.document;
    if (document != null && document.id != _boundDocumentId) {
      _boundDocumentId = document.id;
      _titleController.text = document.title;
    } else if (document != null &&
        _titleController.text != document.title &&
        !_titleController.value.composing.isValid) {
      // Keep field in sync after external rename/save when not composing.
      if (!_titleController.selection.isValid ||
          _titleController.selection.baseOffset ==
              _titleController.text.length) {
        _titleController.text = document.title;
      }
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
              semanticLabel: '提示词标题',
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

class _PromptActionsBar extends StatelessWidget {
  const _PromptActionsBar({required this.controller});

  final PromptController controller;

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;
    final hasDocument = controller.document != null;
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
            tooltip: '复制纯文本',
            semanticLabel: '复制纯文本',
            onPressed: hasDocument ? () => controller.copyPlainText() : null,
            icon: const Icon(LucideIcons.copy),
          ),
          WorkbenchIconButton(
            width: 34,
            height: 34,
            iconSize: 16,
            variant: WorkbenchButtonVariant.outline,
            tooltip: '复制 Markdown',
            semanticLabel: '复制 Markdown',
            onPressed: hasDocument ? () => controller.copyMarkdown() : null,
            icon: const Icon(LucideIcons.fileCode),
          ),
          WorkbenchIconButton(
            width: 34,
            height: 34,
            iconSize: 16,
            variant: WorkbenchButtonVariant.outline,
            tooltip: '创建副本',
            semanticLabel: '创建副本',
            onPressed: hasDocument ? () => controller.duplicate() : null,
            icon: const Icon(LucideIcons.copyPlus),
          ),
          WorkbenchIconButton(
            width: 34,
            height: 34,
            iconSize: 16,
            variant: WorkbenchButtonVariant.destructive,
            tooltip: '移到回收站',
            semanticLabel: '移到回收站',
            onPressed: hasDocument ? () => controller.moveToTrash() : null,
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

class _MockPromptSurface extends StatelessWidget {
  const _MockPromptSurface();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 380),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MacosTheme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Text(
              '提示词源码',
              style: MacosTheme.of(context).typography.headline,
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(22),
            child: Text('选择 Vault 中的提示词以开始编辑。'),
          ),
        ],
      ),
    );
  }
}
