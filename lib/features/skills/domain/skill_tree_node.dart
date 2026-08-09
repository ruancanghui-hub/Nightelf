class SkillTreeNode {
  SkillTreeNode({
    required this.name,
    required this.relativePath,
    required this.isDirectory,
    this.childrenLoaded = false,
    List<SkillTreeNode>? children,
  }) : children = children ?? <SkillTreeNode>[];

  final String name;
  final String relativePath;
  final bool isDirectory;
  bool childrenLoaded;
  final List<SkillTreeNode> children;
}
