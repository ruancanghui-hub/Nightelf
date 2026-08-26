import 'package:ai_workbench/features/workflows/data/workflow_layout_repository.dart';
import 'package:ai_workbench/features/workflows/domain/workflow_graph.dart';
import 'package:ai_workbench/features/workflows/domain/workflow_layout.dart';
import 'package:flutter/foundation.dart';

class WorkflowCanvasController extends ChangeNotifier {
  WorkflowCanvasController({
    required WorkflowLayoutRepository layoutRepository,
    this.nodeWidth = 220,
    this.nodeHeight = 92,
    this.siblingGap = 80,
    this.levelGap = 120,
  }) : _layoutRepository = layoutRepository;

  final WorkflowLayoutRepository _layoutRepository;
  final double nodeWidth;
  final double nodeHeight;
  final double siblingGap;
  final double levelGap;

  WorkflowGraph? _graph;
  WorkflowLayout? _layout;
  final Set<String> _selectedNodeIds = {};
  bool _locked = false;

  WorkflowGraph? get graph => _graph;
  WorkflowLayout? get layout => _layout;
  Set<String> get selectedNodeIds => Set.unmodifiable(_selectedNodeIds);
  bool get locked => _locked;
  double get scale => _layout?.viewport.scale ?? 1;

  Future<void> loadGraph({
    required String workflowId,
    required WorkflowGraph graph,
  }) async {
    // Load stored layout before publishing `_graph`, otherwise a rebuild can
    // pair a new graph with a stale positions map and crash the canvas.
    final stored = await _layoutRepository.load(workflowId);
    final positions = Map<String, CanvasPoint>.from(stored?.positions ?? {});
    _pruneAndFillPositions(positions, graph);
    _graph = graph;
    _layout = WorkflowLayout(
      workflowId: workflowId,
      positions: positions,
      viewport: stored?.viewport ?? const WorkflowViewport(),
      collapsedNodeIds: {
        for (final id in stored?.collapsedNodeIds ?? const <String>{})
          if (positions.containsKey(id)) id,
      },
    );
    _selectedNodeIds.removeWhere((id) => !positions.containsKey(id));
    notifyListeners();
  }

  void moveNode(String nodeId, double dx, double dy) {
    if (_locked) {
      return;
    }
    final layout = _layout;
    final point = layout?.positions[nodeId];
    if (layout == null || point == null) {
      return;
    }
    final next = Map<String, CanvasPoint>.from(layout.positions);
    next[nodeId] = point.translate(dx, dy);
    _layout = layout.copyWith(positions: next);
    notifyListeners();
  }

  void setNodePosition(String nodeId, CanvasPoint position) {
    final layout = _layout;
    if (layout == null || !layout.positions.containsKey(nodeId)) {
      return;
    }
    _layout = layout.copyWith(
      positions: {...layout.positions, nodeId: position},
    );
    notifyListeners();
  }

  void setViewport(WorkflowViewport viewport) {
    final layout = _layout;
    if (layout == null) {
      return;
    }
    _layout = layout.copyWith(viewport: viewport);
    notifyListeners();
  }

  void fitToView({double padding = 80}) {
    final layout = _layout;
    final graph = _graph;
    if (layout == null || graph == null || graph.nodes.isEmpty) {
      return;
    }
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    for (final node in graph.nodes) {
      final point = layout.positions[node.id];
      if (point == null) {
        continue;
      }
      minX = minX < point.x ? minX : point.x;
      minY = minY < point.y ? minY : point.y;
      maxX = maxX > point.x + nodeWidth ? maxX : point.x + nodeWidth;
      maxY = maxY > point.y + nodeHeight ? maxY : point.y + nodeHeight;
    }
    if (!minX.isFinite) {
      return;
    }
    final width = (maxX - minX) + padding * 2;
    final height = (maxY - minY) + padding * 2;
    final scaleX = width <= 0 ? 1.0 : 900 / width;
    final scaleY = height <= 0 ? 1.0 : 560 / height;
    final scale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.15, 4.0);
    _layout = layout.copyWith(
      viewport: WorkflowViewport(
        offsetX: -(minX - padding) * scale,
        offsetY: -(minY - padding) * scale,
        scale: scale,
      ),
    );
    notifyListeners();
  }

  void selectNodes(Set<String> nodeIds, {bool additive = false}) {
    if (!additive) {
      _selectedNodeIds
        ..clear()
        ..addAll(nodeIds);
    } else {
      _selectedNodeIds.addAll(nodeIds);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedNodeIds.clear();
    notifyListeners();
  }

  void setLocked(bool value) {
    _locked = value;
    notifyListeners();
  }

  Future<void> persist() async {
    final layout = _layout;
    if (layout == null) {
      return;
    }
    await _layoutRepository.save(layout);
  }

  void _pruneAndFillPositions(
    Map<String, CanvasPoint> positions,
    WorkflowGraph graph,
  ) {
    final living = graph.nodes.map((n) => n.id).toSet();
    positions.removeWhere((id, _) => !living.contains(id));
    final missing = [
      for (final node in graph.nodes)
        if (!positions.containsKey(node.id)) node.id,
    ];
    if (missing.isEmpty) {
      return;
    }
    final auto = _autoLayout(graph);
    for (final id in missing) {
      positions[id] = auto[id] ?? const CanvasPoint(0, 0);
    }
  }

  Map<String, CanvasPoint> _autoLayout(WorkflowGraph graph) {
    final levels = _computeLevels(graph);
    final byLevel = <int, List<String>>{};
    for (final entry in levels.entries) {
      byLevel.putIfAbsent(entry.value, () => []).add(entry.key);
    }
    final levelKeys = byLevel.keys.toList()..sort();
    final positions = <String, CanvasPoint>{};
    for (final level in levelKeys) {
      final ids = byLevel[level]!;
      final totalWidth = ids.length * nodeWidth + (ids.length - 1) * siblingGap;
      var x = -totalWidth / 2;
      for (final id in ids) {
        final point = switch (graph.direction) {
          WorkflowDirection.topDown => CanvasPoint(
            x,
            level * (nodeHeight + levelGap),
          ),
          WorkflowDirection.bottomUp => CanvasPoint(
            x,
            -level * (nodeHeight + levelGap),
          ),
          WorkflowDirection.leftRight => CanvasPoint(
            level * (nodeWidth + levelGap),
            x,
          ),
          WorkflowDirection.rightLeft => CanvasPoint(
            -level * (nodeWidth + levelGap),
            x,
          ),
        };
        positions[id] = point;
        x += nodeWidth + siblingGap;
      }
    }
    return positions;
  }

  Map<String, int> _computeLevels(WorkflowGraph graph) {
    final incoming = <String, int>{for (final node in graph.nodes) node.id: 0};
    final outgoing = <String, List<String>>{
      for (final node in graph.nodes) node.id: <String>[],
    };
    for (final edge in graph.edges) {
      incoming[edge.toId] = (incoming[edge.toId] ?? 0) + 1;
      outgoing.putIfAbsent(edge.fromId, () => []).add(edge.toId);
    }
    final levels = <String, int>{};
    final queue = [
      for (final node in graph.nodes)
        if ((incoming[node.id] ?? 0) == 0) node.id,
    ];
    if (queue.isEmpty && graph.nodes.isNotEmpty) {
      queue.add(graph.nodes.first.id);
    }
    for (final id in queue) {
      levels[id] = 0;
    }
    var index = 0;
    while (index < queue.length) {
      final id = queue[index++];
      final level = levels[id] ?? 0;
      for (final next in outgoing[id] ?? const <String>[]) {
        final nextLevel = level + 1;
        if (!levels.containsKey(next) || levels[next]! < nextLevel) {
          levels[next] = nextLevel;
        }
        if (!queue.contains(next)) {
          queue.add(next);
        }
      }
    }
    for (final node in graph.nodes) {
      levels.putIfAbsent(node.id, () => 0);
    }
    return levels;
  }
}
