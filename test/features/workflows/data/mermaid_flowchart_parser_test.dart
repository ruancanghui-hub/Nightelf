import 'package:ai_workbench/features/workflows/data/mermaid_flowchart_parser.dart';
import 'package:ai_workbench/features/workflows/domain/workflow_graph.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = MermaidFlowchartParser();

  test('parses common nodes, labels, directions, and edges', () {
    const source = '''flowchart TD
draft[读取内容草稿] --> check{内容检查}
check -->|通过| adapt(多平台适配)
adapt -.-> output[生成发布文件]
''';
    final result = parser.parse(source);
    expect(result.isSuccess, isTrue);
    expect(result.graph!.direction, WorkflowDirection.topDown);
    expect(result.graph!.nodes.map((n) => n.id), [
      'draft',
      'check',
      'adapt',
      'output',
    ]);
    expect(result.graph!.edges[1].label, '通过');
    expect(result.graph!.edges[2].style, WorkflowEdgeStyle.dotted);
  });

  test('rejects unsupported subgraph without losing source location', () {
    final result = parser.parse('flowchart TD\nsubgraph A\nend');
    expect(result.diagnostics.single.line, 2);
    expect(result.diagnostics.single.message, contains('首版暂不支持 subgraph'));
  });

  test('supports comments semicolons unicode and empty-ish graphs', () {
    const source = '''
%% comment
flowchart LR
a[你好]; b(世界)
a --> b
''';
    final result = parser.parse(source);
    expect(result.isSuccess, isTrue);
    expect(result.graph!.direction, WorkflowDirection.leftRight);
    expect(result.graph!.nodes.map((n) => n.label), ['你好', '世界']);
  });

  test('rejects missing header and conflicting declarations', () {
    expect(parser.parse('a --> b').diagnostics, isNotEmpty);
    final conflict = parser.parse('''flowchart TD
a[one]
a[two]
''');
    expect(conflict.diagnostics.single.message, contains('冲突'));
  });

  test('fills bare references from later declarations', () {
    final result = parser.parse('''flowchart TD
a --> b
a[开始]
b{判断}
''');
    expect(result.isSuccess, isTrue);
    expect(result.graph!.nodes.first.label, '开始');
    expect(result.graph!.nodes[1].shape, WorkflowNodeShape.diamond);
  });
}
