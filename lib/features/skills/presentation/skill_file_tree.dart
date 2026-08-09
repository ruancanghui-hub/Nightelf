import 'package:ai_workbench/features/skills/domain/skill_tree_node.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

class SkillFileTree extends StatelessWidget {
  const SkillFileTree({
    required this.nodes,
    required this.selectedRelativePath,
    required this.onOpen,
    required this.onExpand,
    super.key,
  });

  final List<SkillTreeNode> nodes;
  final String? selectedRelativePath;
  final ValueChanged<String> onOpen;
  final ValueChanged<SkillTreeNode> onExpand;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final node in nodes)
          _SkillTreeTile(
            node: node,
            depth: 0,
            selectedRelativePath: selectedRelativePath,
            onOpen: onOpen,
            onExpand: onExpand,
          ),
      ],
    );
  }
}

class _SkillTreeTile extends StatelessWidget {
  const _SkillTreeTile({
    required this.node,
    required this.depth,
    required this.selectedRelativePath,
    required this.onOpen,
    required this.onExpand,
  });

  final SkillTreeNode node;
  final int depth;
  final String? selectedRelativePath;
  final ValueChanged<String> onOpen;
  final ValueChanged<SkillTreeNode> onExpand;

  @override
  Widget build(BuildContext context) {
    final selected = selectedRelativePath == node.relativePath;
    final typography = MacosTheme.of(context).typography;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PushButton(
          controlSize: ControlSize.small,
          secondary: !selected,
          semanticLabel: node.isDirectory
              ? '展开 ${node.name}'
              : '打开 ${node.name}',
          onPressed: () {
            if (node.isDirectory) {
              onExpand(node);
            } else {
              onOpen(node.relativePath);
            }
          },
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: depth * 12.0),
              child: Text(
                node.isDirectory ? '▸ ${node.name}/' : node.name,
                style: typography.body,
              ),
            ),
          ),
        ),
        if (node.isDirectory && node.childrenLoaded)
          for (final child in node.children)
            _SkillTreeTile(
              node: child,
              depth: depth + 1,
              selectedRelativePath: selectedRelativePath,
              onOpen: onOpen,
              onExpand: onExpand,
            ),
      ],
    );
  }
}
