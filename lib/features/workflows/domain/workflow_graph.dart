enum WorkflowDirection { topDown, bottomUp, leftRight, rightLeft }

enum WorkflowNodeShape { rectangle, rounded, diamond, plain }

enum WorkflowEdgeStyle { solid, dotted, line }

enum WorkflowComponentNodeType { process, prompt, skill, mcp, link }

extension WorkflowComponentNodeTypeLabel on WorkflowComponentNodeType {
  String get idPrefix => switch (this) {
    WorkflowComponentNodeType.process => 'node',
    WorkflowComponentNodeType.prompt => 'prompt',
    WorkflowComponentNodeType.skill => 'skill',
    WorkflowComponentNodeType.mcp => 'mcp',
    WorkflowComponentNodeType.link => 'link',
  };

  String get label => switch (this) {
    WorkflowComponentNodeType.process => '流程节点',
    WorkflowComponentNodeType.prompt => 'AI 提示词',
    WorkflowComponentNodeType.skill => 'SKILL',
    WorkflowComponentNodeType.mcp => 'MCP',
    WorkflowComponentNodeType.link => '网站链接',
  };

  String get toolbarLabel => switch (this) {
    WorkflowComponentNodeType.process => '流程',
    WorkflowComponentNodeType.prompt => 'Prompt',
    WorkflowComponentNodeType.skill => 'SKILL',
    WorkflowComponentNodeType.mcp => 'MCP',
    WorkflowComponentNodeType.link => '链接',
  };

  WorkflowNodeShape get shape => switch (this) {
    WorkflowComponentNodeType.process => WorkflowNodeShape.rectangle,
    WorkflowComponentNodeType.prompt => WorkflowNodeShape.rounded,
    WorkflowComponentNodeType.skill => WorkflowNodeShape.rectangle,
    WorkflowComponentNodeType.mcp => WorkflowNodeShape.diamond,
    WorkflowComponentNodeType.link => WorkflowNodeShape.rounded,
  };
}

class WorkflowNode {
  const WorkflowNode({
    required this.id,
    required this.label,
    required this.shape,
  });

  final String id;
  final String label;
  final WorkflowNodeShape shape;

  WorkflowNode copyWith({String? id, String? label, WorkflowNodeShape? shape}) {
    return WorkflowNode(
      id: id ?? this.id,
      label: label ?? this.label,
      shape: shape ?? this.shape,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkflowNode &&
        other.id == id &&
        other.label == label &&
        other.shape == shape;
  }

  @override
  int get hashCode => Object.hash(id, label, shape);
}

class WorkflowEdge {
  const WorkflowEdge({
    required this.id,
    required this.fromId,
    required this.toId,
    this.label = '',
    this.style = WorkflowEdgeStyle.solid,
  });

  final String id;
  final String fromId;
  final String toId;
  final String label;
  final WorkflowEdgeStyle style;

  @override
  bool operator ==(Object other) {
    return other is WorkflowEdge &&
        other.id == id &&
        other.fromId == fromId &&
        other.toId == toId &&
        other.label == label &&
        other.style == style;
  }

  @override
  int get hashCode => Object.hash(id, fromId, toId, label, style);
}

class WorkflowGraph {
  const WorkflowGraph({
    required this.direction,
    required this.nodes,
    required this.edges,
  });

  final WorkflowDirection direction;
  final List<WorkflowNode> nodes;
  final List<WorkflowEdge> edges;

  @override
  bool operator ==(Object other) {
    return other is WorkflowGraph &&
        other.direction == direction &&
        _listEquals(other.nodes, nodes) &&
        _listEquals(other.edges, edges);
  }

  @override
  int get hashCode =>
      Object.hash(direction, Object.hashAll(nodes), Object.hashAll(edges));
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}
