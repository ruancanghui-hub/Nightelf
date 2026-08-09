import 'package:ai_workbench/features/editor/application/document_session.dart';
import 'package:ai_workbench/features/editor/presentation/text_editor_workspace.dart';
import 'package:ai_workbench/features/prompts/application/prompt_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// Prompt workspace with copy/duplicate/trash actions over a live editor.
class PromptWorkspace extends StatelessWidget {
  const PromptWorkspace({super.key, this.controller, this.fallback});

  final PromptController? controller;
  final Widget? fallback;

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

class _PromptActionsBar extends StatelessWidget {
  const _PromptActionsBar({required this.controller});

  final PromptController controller;

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          PushButton(
            controlSize: ControlSize.small,
            semanticLabel: '复制纯文本',
            onPressed: controller.document == null
                ? null
                : () => controller.copyPlainText(),
            child: const Text('复制纯文本'),
          ),
          PushButton(
            controlSize: ControlSize.small,
            secondary: true,
            semanticLabel: '复制 Markdown',
            onPressed: controller.document == null
                ? null
                : () => controller.copyMarkdown(),
            child: const Text('复制 Markdown'),
          ),
          PushButton(
            controlSize: ControlSize.small,
            secondary: true,
            semanticLabel: '创建副本',
            onPressed: controller.document == null
                ? null
                : () => controller.duplicate(),
            child: const Text('创建副本'),
          ),
          PushButton(
            controlSize: ControlSize.small,
            secondary: true,
            semanticLabel: '移到回收站',
            onPressed: controller.document == null
                ? null
                : () => controller.moveToTrash(),
            child: const Text('移到回收站'),
          ),
          if (controller.lastTrashPath != null)
            PushButton(
              controlSize: ControlSize.small,
              semanticLabel: '撤销回收',
              onPressed: () => controller.undoTrash(),
              child: const Text('撤销回收'),
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
