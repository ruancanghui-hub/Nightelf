import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// Static Mermaid source and non-interactive workflow canvas.
class WorkflowWorkspace extends StatelessWidget {
  const WorkflowWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 440),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MacosTheme.of(context).dividerColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const source = _MermaidSource();
          const canvas = _StaticCanvas();
          if (constraints.maxWidth < 620) {
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [source, SizedBox(height: 14), canvas],
            );
          }
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: source),
              SizedBox(width: 14),
              Expanded(flex: 2, child: canvas),
            ],
          );
        },
      ),
    );
  }
}

class _MermaidSource extends StatelessWidget {
  const _MermaidSource();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _innerDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mermaid 源码', style: MacosTheme.of(context).typography.headline),
          const SizedBox(height: 16),
          DefaultTextStyle(
            style: MacosTheme.of(
              context,
            ).typography.body.copyWith(height: 1.6, fontFamily: 'Menlo'),
            child: const Text(
              'flowchart LR\n  A[读取变更]\n  B[生成说明]\n'
              '  C[人工确认]\n  A --> B --> C',
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticCanvas extends StatelessWidget {
  const _StaticCanvas();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _innerDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                '静态画布 · 不可互动',
                style: MacosTheme.of(context).typography.headline,
              ),
              Text(
                '未执行 · 视觉模拟',
                style: MacosTheme.of(context).typography.caption1,
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _WorkflowNode(label: '读取变更'),
          const Center(child: Text('↓')),
          const _WorkflowNode(label: '生成说明'),
          const Center(child: Text('↓')),
          const _WorkflowNode(label: '人工确认'),
        ],
      ),
    );
  }
}

class _WorkflowNode extends StatelessWidget {
  const _WorkflowNode({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: MacosTheme.of(context).primaryColor.withValues(alpha: 0.32),
        ),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}

BoxDecoration _innerDecoration(BuildContext context) => BoxDecoration(
  color: const Color(0x12000000),
  borderRadius: BorderRadius.circular(9),
  border: Border.all(color: MacosTheme.of(context).dividerColor),
);
