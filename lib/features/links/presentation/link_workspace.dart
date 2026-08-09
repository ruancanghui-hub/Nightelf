import 'package:ai_workbench/features/links/application/link_controller.dart';
import 'package:ai_workbench/features/links/presentation/link_in_app_browser.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

class LinkWorkspace extends StatelessWidget {
  const LinkWorkspace({
    super.key,
    this.controller,
    this.fallback,
    this.onRenamed,
  });

  final LinkController? controller;
  final Widget? fallback;
  final Future<void> Function(String relativePath)? onRenamed;

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
        return _LinkEditor(controller: controller, onRenamed: onRenamed);
      },
    );
  }
}

class _LinkEditor extends StatefulWidget {
  const _LinkEditor({required this.controller, this.onRenamed});

  final LinkController controller;
  final Future<void> Function(String relativePath)? onRenamed;

  @override
  State<_LinkEditor> createState() => _LinkEditorState();
}

class _LinkEditorState extends State<_LinkEditor> {
  late final TextEditingController _urlController;
  late final TextEditingController _titleController;
  String? _boundId;
  String _browserUrl = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.controller.document?.title ?? '',
    );
    _urlController = TextEditingController(text: widget.controller.draftUrl);
    _boundId = widget.controller.document?.id;
    _browserUrl = widget.controller.document?.uri.toString() ??
        widget.controller.draftUrl;
  }

  @override
  void didUpdateWidget(covariant _LinkEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final id = widget.controller.document?.id;
    if (id != null && id != _boundId) {
      _boundId = id;
      _titleController.text = widget.controller.document?.title ?? '';
      _urlController.text = widget.controller.draftUrl;
      _browserUrl = widget.controller.document?.uri.toString() ??
          widget.controller.draftUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveTitle() async {
    final renamed = await widget.controller.rename(_titleController.text);
    await widget.onRenamed?.call(renamed.relativePath);
  }

  Future<void> _saveAndBrowse() async {
    await widget.controller.save();
    final document = widget.controller.document;
    if (document == null) {
      return;
    }
    setState(() => _browserUrl = document.uri.toString());
  }

  void _browseDraft() {
    setState(() => _browserUrl = _urlController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final typography = MacosTheme.of(context).typography;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: '网站链接标题',
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
              semanticLabel: '复制链接',
              onPressed: () => controller.copyUrl(),
              child: const Text('复制链接'),
            ),
            PushButton(
              controlSize: ControlSize.small,
              secondary: true,
              semanticLabel: '保存并在内置浏览器打开',
              onPressed: _saveAndBrowse,
              child: const Text('保存并打开'),
            ),
            PushButton(
              controlSize: ControlSize.small,
              secondary: true,
              semanticLabel: '在内置浏览器打开当前地址',
              onPressed: _browseDraft,
              child: const Text('打开'),
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
              semanticLabel: controller.isFloatingBubble
                  ? '关闭桌面悬浮球'
                  : '设为桌面悬浮球',
              onPressed: () =>
                  controller.setFloatingBubble(!controller.isFloatingBubble),
              child: Text(
                controller.isFloatingBubble ? '关闭悬浮球' : '设为悬浮球',
              ),
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
            onSubmitted: (_) => _saveAndBrowse(),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LinkInAppBrowser(
            key: ValueKey(_boundId ?? _browserUrl),
            url: _browserUrl,
            onExternalScheme: controller.openExternalUri,
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
        '打开或粘贴一个网站链接以在内置浏览器中查看。',
        style: MacosTheme.of(context).typography.body,
      ),
    );
  }
}
