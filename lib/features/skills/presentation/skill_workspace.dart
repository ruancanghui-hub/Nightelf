import 'dart:io';

import 'package:ai_workbench/features/editor/presentation/text_editor_workspace.dart';
import 'package:ai_workbench/features/skills/application/skill_controller.dart';
import 'package:ai_workbench/features/skills/presentation/skill_file_tree.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path/path.dart' as p;

/// Live SKILL folder workspace with lazy tree, editor, and system actions.
class SkillWorkspace extends StatelessWidget {
  const SkillWorkspace({super.key, this.controller, this.fallback});

  final SkillController? controller;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null) {
      return fallback ?? const _MockSkillSurface();
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.skill == null) {
          return fallback ?? const _MockSkillSurface();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SkillActionsBar(controller: controller),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tree = _SkillTreePane(controller: controller);
                  final preview = _SkillPreviewPane(controller: controller);
                  if (!constraints.hasBoundedHeight ||
                      constraints.maxWidth < 560) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 180, child: tree),
                        const SizedBox(height: 12),
                        Expanded(child: preview),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 220, child: tree),
                      const SizedBox(width: 12),
                      Expanded(child: preview),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SkillActionsBar extends StatelessWidget {
  const _SkillActionsBar({required this.controller});

  final SkillController controller;

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
            semanticLabel: '在 Finder 中显示',
            onPressed: () => controller.revealInFinder(),
            child: const Text('Finder'),
          ),
          PushButton(
            controlSize: ControlSize.small,
            secondary: true,
            semanticLabel: '在终端打开',
            onPressed: () => controller.openTerminal(),
            child: const Text('终端'),
          ),
          PushButton(
            controlSize: ControlSize.small,
            secondary: true,
            semanticLabel: '创建副本',
            onPressed: () => controller.duplicate(),
            child: const Text('创建副本'),
          ),
          PushButton(
            controlSize: ControlSize.small,
            secondary: true,
            semanticLabel: '移到回收站',
            onPressed: () => controller.moveToTrash(),
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

class _SkillTreePane extends StatelessWidget {
  const _SkillTreePane({required this.controller});

  final SkillController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _innerDecoration(context),
      child: SkillFileTree(
        nodes: controller.rootChildren,
        selectedRelativePath: controller.selectedRelativePath,
        onOpen: (path) => controller.openNode(path),
        onExpand: (node) => controller.expandDirectory(node),
      ),
    );
  }
}

class _SkillPreviewPane extends StatelessWidget {
  const _SkillPreviewPane({required this.controller});

  final SkillController controller;

  @override
  Widget build(BuildContext context) {
    final kind = controller.previewKind;
    final session = controller.session;
    if (kind == SkillPreviewKind.text && session != null) {
      return TextEditorWorkspace(
        session: session,
        title: p.basename(controller.selectedRelativePath ?? '文件'),
      );
    }
    if (kind == SkillPreviewKind.image &&
        controller.imageAbsolutePath != null) {
      return Container(
        alignment: Alignment.center,
        decoration: _innerDecoration(context),
        child: Image.file(
          File(controller.imageAbsolutePath!),
          fit: BoxFit.contain,
        ),
      );
    }
    if (kind == SkillPreviewKind.binary) {
      return Container(
        alignment: Alignment.center,
        decoration: _innerDecoration(context),
        child: Text(
          '二进制文件已交由系统打开',
          style: MacosTheme.of(context).typography.body,
        ),
      );
    }
    return Container(
      alignment: Alignment.center,
      decoration: _innerDecoration(context),
      child: Text('选择文件以预览', style: MacosTheme.of(context).typography.body),
    );
  }
}

class _MockSkillSurface extends StatelessWidget {
  const _MockSkillSurface();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 410),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MacosTheme.of(context).dividerColor),
      ),
      child: Text(
        '打开 Vault 中的 SKILL 文件夹以浏览与编辑。',
        style: MacosTheme.of(context).typography.body,
      ),
    );
  }
}

BoxDecoration _innerDecoration(BuildContext context) => BoxDecoration(
  color: const Color(0x12000000),
  borderRadius: BorderRadius.circular(9),
  border: Border.all(color: MacosTheme.of(context).dividerColor),
);
