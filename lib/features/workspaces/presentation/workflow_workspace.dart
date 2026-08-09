import 'package:ai_workbench/features/workflows/application/workflow_controller.dart';
import 'package:ai_workbench/features/workflows/presentation/workflow_canvas.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

class WorkflowWorkspace extends StatelessWidget {
  const WorkflowWorkspace({
    super.key,
    this.controller,
    this.fallback,
    this.onRenamed,
  });

  final WorkflowController? controller;
  final Widget? fallback;
  final Future<void> Function(String relativePath)? onRenamed;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null) {
      return fallback ?? const _MockWorkflowSurface();
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.document == null) {
          return fallback ?? const _MockWorkflowSurface();
        }
        return _WorkflowEditor(
          controller: controller,
          onRenamed: onRenamed,
        );
      },
    );
  }
}

class _WorkflowEditor extends StatefulWidget {
  const _WorkflowEditor({required this.controller, this.onRenamed});

  final WorkflowController controller;
  final Future<void> Function(String relativePath)? onRenamed;

  @override
  State<_WorkflowEditor> createState() => _WorkflowEditorState();
}

class _WorkflowEditorState extends State<_WorkflowEditor> {
  late final TextEditingController _sourceController;
  late final TextEditingController _titleController;
  String? _boundPath;
  String? _boundId;

  @override
  void initState() {
    super.initState();
    _sourceController = TextEditingController(text: widget.controller.source);
    _titleController = TextEditingController(
      text: widget.controller.document?.title ?? '',
    );
    _boundPath = widget.controller.document?.relativePath;
    _boundId = widget.controller.document?.id;
    widget.controller.addListener(_syncFromController);
  }

  @override
  void didUpdateWidget(covariant _WorkflowEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncFromController);
      widget.controller.addListener(_syncFromController);
      _syncFromController();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromController);
    _sourceController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _syncFromController() {
    final path = widget.controller.document?.relativePath;
    final id = widget.controller.document?.id;
    final next = widget.controller.source;
    final pathChanged = path != null && path != _boundPath;
    final loadedIntoEmpty =
        path != null && _sourceController.text.isEmpty && next.isNotEmpty;
    if (pathChanged || loadedIntoEmpty) {
      _boundPath = path;
      if (_sourceController.text != next) {
        _sourceController.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    }
    if (id != null && id != _boundId) {
      _boundId = id;
      _titleController.text = widget.controller.document?.title ?? '';
    }
  }

  Future<void> _saveTitle() async {
    final renamed = await widget.controller.rename(_titleController.text);
    await widget.onRenamed?.call(renamed.relativePath);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final typography = MacosTheme.of(context).typography;
    final diagnostics = controller.diagnostics;
    return Container(
      constraints: const BoxConstraints(minHeight: 440),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MacosTheme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: 'Workflow 标题',
                  textField: true,
                  child: MacosTextField(
                    controller: _titleController,
                    placeholder: '输入标题',
                    onSubmitted: (_) => _saveTitle(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PushButton(
                controlSize: ControlSize.small,
                semanticLabel: '保存标题',
                onPressed: _saveTitle,
                child: const Text('保存标题'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PushButton(
                controlSize: ControlSize.small,
                semanticLabel: '源码模式',
                onPressed: () => controller.setMode(WorkflowViewMode.source),
                child: Text(
                  controller.mode == WorkflowViewMode.source ? '源码 ✓' : '源码',
                ),
              ),
              PushButton(
                controlSize: ControlSize.small,
                semanticLabel: '画布模式',
                onPressed: controller.canUseCanvas
                    ? () => controller.setMode(WorkflowViewMode.canvas)
                    : null,
                child: Text(
                  controller.mode == WorkflowViewMode.canvas ? '画布 ✓' : '画布',
                ),
              ),
              PushButton(
                controlSize: ControlSize.small,
                semanticLabel: '保存 Workflow',
                onPressed: () => controller.saveSource(),
                child: const Text('保存'),
              ),
              if (controller.statusMessage != null)
                Text(controller.statusMessage!, style: typography.caption1),
            ],
          ),
          if (diagnostics.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0x33B91C1C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '源码无效：L${diagnostics.first.line}:C${diagnostics.first.column} ${diagnostics.first.message}',
                      style: typography.caption1,
                    ),
                  ),
                  PushButton(
                    controlSize: ControlSize.small,
                    semanticLabel: '返回源码',
                    onPressed: () =>
                        controller.setMode(WorkflowViewMode.source),
                    child: const Text('返回源码'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: controller.mode == WorkflowViewMode.canvas
                ? WorkflowCanvas(controller: controller.canvasController)
                : MacosTextField(
                    controller: _sourceController,
                    maxLines: null,
                    minLines: 18,
                    onChanged: controller.updateSource,
                    placeholder: 'Mermaid flowchart 源码',
                    style: typography.body.copyWith(fontFamily: 'Menlo'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MockWorkflowSurface extends StatelessWidget {
  const _MockWorkflowSurface();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 240),
      alignment: Alignment.center,
      child: Text(
        '选择或新建一个 Workflow 文件',
        style: MacosTheme.of(context).typography.body,
      ),
    );
  }
}
