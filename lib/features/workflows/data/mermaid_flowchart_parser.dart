import 'package:ai_workbench/features/workflows/domain/workflow_diagnostic.dart';
import 'package:ai_workbench/features/workflows/domain/workflow_graph.dart';

class MermaidParseResult {
  const MermaidParseResult._({this.graph, required this.diagnostics});

  factory MermaidParseResult.success(WorkflowGraph graph) {
    return MermaidParseResult._(graph: graph, diagnostics: const []);
  }

  factory MermaidParseResult.failure(List<WorkflowDiagnostic> diagnostics) {
    return MermaidParseResult._(diagnostics: List.unmodifiable(diagnostics));
  }

  final WorkflowGraph? graph;
  final List<WorkflowDiagnostic> diagnostics;

  bool get isSuccess => graph != null && diagnostics.isEmpty;
}

/// Conservative line-oriented Mermaid flowchart subset parser.
class MermaidFlowchartParser {
  const MermaidFlowchartParser();

  static final RegExp _header = RegExp(
    r'^(?:flowchart|graph)\s+(TD|TB|BT|LR|RL)\s*$',
    caseSensitive: false,
  );
  static final RegExp _nodeIdToken = RegExp(
    r'[A-Za-z_][A-Za-z0-9_]*(?:-[A-Za-z0-9_]+)*',
  );
  static final RegExp _edgeOp = RegExp(r'(-->|---|-\.->)');

  MermaidParseResult parse(String source) {
    final diagnostics = <WorkflowDiagnostic>[];
    final statements = _collectStatements(source);
    if (statements.isEmpty) {
      return MermaidParseResult.failure([
        const WorkflowDiagnostic(
          line: 1,
          column: 1,
          message: '缺少 flowchart/graph 头部',
        ),
      ]);
    }

    final header = statements.first;
    final headerMatch = _header.firstMatch(header.text);
    if (headerMatch == null) {
      diagnostics.add(
        WorkflowDiagnostic(
          line: header.line,
          column: 1,
          message: '缺少 flowchart/graph 头部或方向不受支持',
        ),
      );
      return MermaidParseResult.failure(diagnostics);
    }

    final direction = _directionFor(headerMatch.group(1)!.toUpperCase());
    final nodes = <String, WorkflowNode>{};
    final nodeOrder = <String>[];
    final edges = <WorkflowEdge>[];
    var edgeIndex = 0;

    for (final statement in statements.skip(1)) {
      final text = statement.text.trim();
      if (text.isEmpty) {
        continue;
      }
      final lower = text.toLowerCase();
      if (lower.startsWith('subgraph')) {
        diagnostics.add(
          WorkflowDiagnostic(
            line: statement.line,
            column: 1,
            message: '首版暂不支持 subgraph',
          ),
        );
        continue;
      }
      if (lower == 'end') {
        // Closing token for unsupported subgraph blocks; skip after diagnostic.
        continue;
      }

      if (_edgeOp.hasMatch(text)) {
        final chain = _parseEdgeChain(text, statement.line);
        if (chain.error != null) {
          diagnostics.add(chain.error!);
          continue;
        }
        for (final node in chain.nodes) {
          final conflict = _upsertNode(nodes, nodeOrder, node, statement.line);
          if (conflict != null) {
            diagnostics.add(conflict);
          }
        }
        for (final edge in chain.edges) {
          edges.add(
            WorkflowEdge(
              id: 'e${++edgeIndex}',
              fromId: edge.fromId,
              toId: edge.toId,
              label: edge.label,
              style: edge.style,
            ),
          );
        }
        continue;
      }

      final node = _parseNodeToken(text);
      if (node == null) {
        diagnostics.add(
          WorkflowDiagnostic(
            line: statement.line,
            column: 1,
            message: '无法解析的语句：$text',
          ),
        );
        continue;
      }
      final conflict = _upsertNode(nodes, nodeOrder, node, statement.line);
      if (conflict != null) {
        diagnostics.add(conflict);
      }
    }

    if (diagnostics.isNotEmpty) {
      return MermaidParseResult.failure(diagnostics);
    }

    return MermaidParseResult.success(
      WorkflowGraph(
        direction: direction,
        nodes: [for (final id in nodeOrder) nodes[id]!],
        edges: edges,
      ),
    );
  }

  WorkflowDirection _directionFor(String token) => switch (token) {
    'TD' || 'TB' => WorkflowDirection.topDown,
    'BT' => WorkflowDirection.bottomUp,
    'LR' => WorkflowDirection.leftRight,
    'RL' => WorkflowDirection.rightLeft,
    _ => WorkflowDirection.topDown,
  };

  WorkflowDiagnostic? _upsertNode(
    Map<String, WorkflowNode> nodes,
    List<String> nodeOrder,
    WorkflowNode node,
    int line,
  ) {
    final existing = nodes[node.id];
    if (existing == null) {
      nodes[node.id] = node;
      nodeOrder.add(node.id);
      return null;
    }

    final existingIsBare =
        existing.shape == WorkflowNodeShape.plain &&
        existing.label == existing.id;
    final incomingIsBare =
        node.shape == WorkflowNodeShape.plain && node.label == node.id;

    if (existingIsBare && !incomingIsBare) {
      nodes[node.id] = node;
      return null;
    }
    if (incomingIsBare) {
      return null;
    }
    if (existing.shape != node.shape || existing.label != node.label) {
      return WorkflowDiagnostic(
        line: line,
        column: 1,
        message: '节点 ${node.id} 声明冲突',
      );
    }
    return null;
  }

  _EdgeChainResult _parseEdgeChain(String text, int line) {
    final nodes = <WorkflowNode>[];
    final edges = <_PendingEdge>[];
    var cursor = 0;
    WorkflowNode? previous;

    while (cursor < text.length) {
      while (cursor < text.length && text[cursor].trim().isEmpty) {
        cursor += 1;
      }
      if (cursor >= text.length) {
        break;
      }

      if (previous != null) {
        final opMatch = _edgeOp.matchAsPrefix(text, cursor);
        if (opMatch == null) {
          return _EdgeChainResult.error(
            WorkflowDiagnostic(
              line: line,
              column: cursor + 1,
              message: '缺少边运算符',
            ),
          );
        }
        cursor = opMatch.end;
        var label = '';
        while (cursor < text.length && text[cursor].trim().isEmpty) {
          cursor += 1;
        }
        if (cursor < text.length && text[cursor] == '|') {
          final end = text.indexOf('|', cursor + 1);
          if (end < 0) {
            return _EdgeChainResult.error(
              WorkflowDiagnostic(
                line: line,
                column: cursor + 1,
                message: '边标签缺少结束 |',
              ),
            );
          }
          label = text.substring(cursor + 1, end);
          cursor = end + 1;
        }
        while (cursor < text.length && text[cursor].trim().isEmpty) {
          cursor += 1;
        }
        final next = _readNodeAt(text, cursor);
        if (next == null) {
          return _EdgeChainResult.error(
            WorkflowDiagnostic(
              line: line,
              column: cursor + 1,
              message: '边缺少目标节点',
            ),
          );
        }
        nodes.add(next.node);
        edges.add(
          _PendingEdge(
            fromId: previous.id,
            toId: next.node.id,
            label: label,
            style: _styleFor(opMatch.group(0)!),
          ),
        );
        previous = next.node;
        cursor = next.end;
        continue;
      }

      final first = _readNodeAt(text, cursor);
      if (first == null) {
        return _EdgeChainResult.error(
          WorkflowDiagnostic(
            line: line,
            column: cursor + 1,
            message: '边缺少起始节点',
          ),
        );
      }
      nodes.add(first.node);
      previous = first.node;
      cursor = first.end;
    }

    if (edges.isEmpty) {
      return _EdgeChainResult.error(
        WorkflowDiagnostic(line: line, column: 1, message: '未解析到有效边'),
      );
    }
    return _EdgeChainResult(nodes: nodes, edges: edges);
  }

  WorkflowEdgeStyle _styleFor(String op) => switch (op) {
    '-.->' => WorkflowEdgeStyle.dotted,
    '---' => WorkflowEdgeStyle.line,
    _ => WorkflowEdgeStyle.solid,
  };

  _NodeRead? _readNodeAt(String text, int start) {
    if (start >= text.length) {
      return null;
    }
    final idMatch = _nodeIdToken.matchAsPrefix(text, start);
    if (idMatch == null) {
      return null;
    }
    final id = idMatch.group(0)!;
    var end = idMatch.end;
    if (end >= text.length) {
      return _NodeRead(
        node: WorkflowNode(id: id, label: id, shape: WorkflowNodeShape.plain),
        end: end,
      );
    }
    final opener = text[end];
    if (opener == '[' || opener == '(' || opener == '{') {
      final closer = opener == '['
          ? ']'
          : opener == '('
          ? ')'
          : '}';
      final closeIndex = text.indexOf(closer, end + 1);
      if (closeIndex < 0) {
        return null;
      }
      final label = text.substring(end + 1, closeIndex);
      final shape = opener == '['
          ? WorkflowNodeShape.rectangle
          : opener == '('
          ? WorkflowNodeShape.rounded
          : WorkflowNodeShape.diamond;
      return _NodeRead(
        node: WorkflowNode(id: id, label: label, shape: shape),
        end: closeIndex + 1,
      );
    }
    return _NodeRead(
      node: WorkflowNode(id: id, label: id, shape: WorkflowNodeShape.plain),
      end: end,
    );
  }

  WorkflowNode? _parseNodeToken(String text) {
    final read = _readNodeAt(text, 0);
    if (read == null) {
      return null;
    }
    final rest = text.substring(read.end).trim();
    if (rest.isNotEmpty) {
      return null;
    }
    return read.node;
  }

  List<_Statement> _collectStatements(String source) {
    final statements = <_Statement>[];
    final lines = source.split('\n');
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      if (line.endsWith('\r')) {
        line = line.substring(0, line.length - 1);
      }
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('%%')) {
        continue;
      }
      for (final part in trimmed.split(';')) {
        final statement = part.trim();
        if (statement.isEmpty) {
          continue;
        }
        statements.add(_Statement(line: i + 1, text: statement));
      }
    }
    return statements;
  }
}

class _Statement {
  const _Statement({required this.line, required this.text});

  final int line;
  final String text;
}

class _NodeRead {
  const _NodeRead({required this.node, required this.end});

  final WorkflowNode node;
  final int end;
}

class _PendingEdge {
  const _PendingEdge({
    required this.fromId,
    required this.toId,
    required this.label,
    required this.style,
  });

  final String fromId;
  final String toId;
  final String label;
  final WorkflowEdgeStyle style;
}

class _EdgeChainResult {
  const _EdgeChainResult({
    this.nodes = const [],
    this.edges = const [],
    this.error,
  });

  factory _EdgeChainResult.error(WorkflowDiagnostic diagnostic) {
    return _EdgeChainResult(error: diagnostic);
  }

  final List<WorkflowNode> nodes;
  final List<_PendingEdge> edges;
  final WorkflowDiagnostic? error;
}
