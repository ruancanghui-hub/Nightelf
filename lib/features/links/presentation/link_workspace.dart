import 'package:ai_workbench/features/links/application/link_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

class LinkWorkspace extends StatelessWidget {
  const LinkWorkspace({super.key, this.controller, this.fallback});

  final LinkController? controller;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null) {
      return fallback ?? const _MockLinkSurface();
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.document == null) {
          return fallback ?? const _MockLinkSurface();
        }
        return _LinkEditor(controller: controller);
      },
    );
  }
}

class _LinkEditor extends StatefulWidget {
  const _LinkEditor({required this.controller});

  final LinkController controller;

  @override
  State<_LinkEditor> createState() => _LinkEditorState();
}

class _LinkEditorState extends State<_LinkEditor> {
  late final TextEditingController _urlController;
  late final TextEditingController _notesController;
  String? _boundId;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.controller.draftUrl);
    _notesController = TextEditingController(
      text: widget.controller.draftNotes,
    );
    _boundId = widget.controller.document?.id;
  }

  @override
  void didUpdateWidget(covariant _LinkEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final id = widget.controller.document?.id;
    if (id != null && id != _boundId) {
      _boundId = id;
      _urlController.text = widget.controller.draftUrl;
      _notesController.text = widget.controller.draftNotes;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final typography = MacosTheme.of(context).typography;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PushButton(
              controlSize: ControlSize.small,
              semanticLabel: '复制链接',
              onPressed: () => controller.copyUrl(),
              child: const Text('复制链接'),
            ),
            PushButton(
              controlSize: ControlSize.small,
              secondary: true,
              semanticLabel: '保存链接',
              onPressed: () => controller.save(),
              child: const Text('保存'),
            ),
            PushButton(
              controlSize: ControlSize.small,
              secondary: true,
              semanticLabel: '在外部浏览器打开',
              onPressed: () => controller.openExternally(),
              child: const Text('外部浏览器'),
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
            if (controller.errorMessage != null)
              Text(
                controller.errorMessage!,
                style: typography.caption1.copyWith(
                  color: MacosColors.systemRedColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('链接地址', style: typography.headline),
        const SizedBox(height: 6),
        Semantics(
          label: '网站链接地址',
          textField: true,
          child: MacosTextField(
            controller: _urlController,
            placeholder: 'https://example.com',
            onChanged: controller.updateDraftUrl,
          ),
        ),
        const SizedBox(height: 12),
        Text('备注', style: typography.headline),
        const SizedBox(height: 6),
        Expanded(
          child: Semantics(
            label: '网站链接备注',
            textField: true,
            child: MacosTextField(
              controller: _notesController,
              placeholder: '可选备注',
              maxLines: null,
              onChanged: controller.updateDraftNotes,
            ),
          ),
        ),
      ],
    );
  }
}

class _MockLinkSurface extends StatelessWidget {
  const _MockLinkSurface();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 320),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MacosTheme.of(context).dividerColor),
      ),
      child: Text(
        '打开或粘贴一个网站链接以开始。',
        style: MacosTheme.of(context).typography.body,
      ),
    );
  }
}
