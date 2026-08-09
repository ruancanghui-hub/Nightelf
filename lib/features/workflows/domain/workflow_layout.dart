class CanvasPoint {
  const CanvasPoint(this.x, this.y);

  final double x;
  final double y;

  CanvasPoint translate(double dx, double dy) => CanvasPoint(x + dx, y + dy);

  @override
  bool operator ==(Object other) =>
      other is CanvasPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

class WorkflowViewport {
  const WorkflowViewport({this.offsetX = 0, this.offsetY = 0, this.scale = 1});

  final double offsetX;
  final double offsetY;
  final double scale;

  WorkflowViewport copyWith({double? offsetX, double? offsetY, double? scale}) {
    return WorkflowViewport(
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      scale: scale ?? this.scale,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WorkflowViewport &&
      other.offsetX == offsetX &&
      other.offsetY == offsetY &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(offsetX, offsetY, scale);
}

class WorkflowLayout {
  const WorkflowLayout({
    required this.workflowId,
    required this.positions,
    required this.viewport,
    this.collapsedNodeIds = const {},
  });

  final String workflowId;
  final Map<String, CanvasPoint> positions;
  final WorkflowViewport viewport;
  final Set<String> collapsedNodeIds;

  WorkflowLayout copyWith({
    String? workflowId,
    Map<String, CanvasPoint>? positions,
    WorkflowViewport? viewport,
    Set<String>? collapsedNodeIds,
  }) {
    return WorkflowLayout(
      workflowId: workflowId ?? this.workflowId,
      positions: positions ?? this.positions,
      viewport: viewport ?? this.viewport,
      collapsedNodeIds: collapsedNodeIds ?? this.collapsedNodeIds,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkflowLayout &&
        other.workflowId == workflowId &&
        other.viewport == viewport &&
        _mapEquals(other.positions, positions) &&
        _setEquals(other.collapsedNodeIds, collapsedNodeIds);
  }

  @override
  int get hashCode => Object.hash(
    workflowId,
    viewport,
    Object.hashAll(positions.entries.map((e) => Object.hash(e.key, e.value))),
    Object.hashAll(collapsedNodeIds),
  );
}

bool _mapEquals(Map<String, CanvasPoint> left, Map<String, CanvasPoint> right) {
  if (left.length != right.length) {
    return false;
  }
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

bool _setEquals(Set<String> left, Set<String> right) {
  if (left.length != right.length) {
    return false;
  }
  return left.containsAll(right);
}
