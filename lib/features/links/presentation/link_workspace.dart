import 'package:ai_workbench/features/links/application/link_controller.dart';
import 'package:ai_workbench/features/links/presentation/link_in_app_browser.dart';
import 'package:ai_workbench/features/metadata/application/metadata_controller.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:macos_ui/macos_ui.dart';

typedef LinkBrowserBuilder =
    Widget Function(
      BuildContext context,
      String url,
      VoidCallback onOpenExternally,
    );

class LinkWorkspace extends StatelessWidget {
  const LinkWorkspace({
    super.key,
    this.controller,
    this.resource,
    this.metadataController,
    this.onToggleFavorite,
    this.browserBuilder,
    this.showInspector = true,
    this.fallback,
    this.onRenamed,
  });

  final LinkController? controller;
  final WorkbenchResource? resource;
  final MetadataController? metadataController;
  final Future<void> Function(String resourceId)? onToggleFavorite;
  final LinkBrowserBuilder? browserBuilder;
  final bool showInspector;
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
        return _LinkEditor(
          controller: controller,
          resource: resource,
          metadataController: metadataController,
          onToggleFavorite: onToggleFavorite,
          browserBuilder: browserBuilder,
          showInspector: showInspector,
          onRenamed: onRenamed,
        );
      },
    );
  }
}

class _LinkEditor extends StatefulWidget {
  const _LinkEditor({
    required this.controller,
    this.resource,
    this.metadataController,
    this.onToggleFavorite,
    this.browserBuilder,
    this.showInspector = true,
    this.onRenamed,
  });

  final LinkController controller;
  final WorkbenchResource? resource;
  final MetadataController? metadataController;
  final Future<void> Function(String resourceId)? onToggleFavorite;
  final LinkBrowserBuilder? browserBuilder;
  final bool showInspector;
  final Future<void> Function(String relativePath)? onRenamed;

  @override
  State<_LinkEditor> createState() => _LinkEditorState();
}

class _LinkEditorState extends State<_LinkEditor> {
  late final TextEditingController _urlController;
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  String? _boundId;
  String _browserUrl = '';

  @override
  void initState() {
    super.initState();
    final document = widget.controller.document;
    _titleController = TextEditingController(text: document?.title ?? '');
    _urlController = TextEditingController(text: widget.controller.draftUrl);
    _notesController = TextEditingController(
      text: widget.controller.draftNotes,
    );
    _boundId = document?.id;
    _browserUrl = document?.uri.toString() ?? widget.controller.draftUrl;
  }

  @override
  void didUpdateWidget(covariant _LinkEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final document = widget.controller.document;
    final id = document?.id;
    if (id != null && id != _boundId) {
      _boundId = id;
      _titleController.text = document?.title ?? '';
      _urlController.text = widget.controller.draftUrl;
      _notesController.text = widget.controller.draftNotes;
      _browserUrl = document?.uri.toString() ?? widget.controller.draftUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveTitle(String value) async {
    final renamed = await widget.controller.rename(value);
    await widget.onRenamed?.call(renamed.relativePath);
  }

  Future<void> _saveAddress(String value) async {
    widget.controller.updateDraftUrl(value);
    await widget.controller.save();
    final document = widget.controller.document;
    if (document == null || widget.controller.errorMessage != null) {
      return;
    }
    setState(() => _browserUrl = document.uri.toString());
  }

  Future<void> _saveNotes() async {
    widget.controller.updateDraftNotes(_notesController.text);
    await widget.controller.save();
  }

  Widget _buildBrowser(BuildContext context) {
    void openExternally() {
      widget.controller.openExternally();
    }

    final custom = widget.browserBuilder;
    if (custom != null) {
      return custom(context, _browserUrl, openExternally);
    }
    return LinkInAppBrowser(
      key: ValueKey(_boundId ?? _browserUrl),
      url: _browserUrl,
      addressController: _urlController,
      onAddressSubmitted: _saveAddress,
      onExternalScheme: widget.controller.openExternalUri,
      onOpenExternally: openExternally,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF020B08),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final header = _LinkIdentityHeader(controller: widget.controller);
          final browser = Container(
            key: const ValueKey('link-browser-pane'),
            constraints: const BoxConstraints(minHeight: 360),
            child: _buildBrowser(context),
          );
          final inspector = _LinkDetailsInspector(
            key: const ValueKey('link-details-inspector'),
            controller: widget.controller,
            resource: widget.resource,
            metadataController: widget.metadataController,
            onToggleFavorite: widget.onToggleFavorite,
            titleController: _titleController,
            notesController: _notesController,
            onSaveTitle: _saveTitle,
            onSaveNotes: _saveNotes,
          );

          if (compact) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: 12),
                  SizedBox(height: 440, child: browser),
                  if (widget.showInspector) ...[
                    const SizedBox(height: 16),
                    inspector,
                  ],
                ],
              ),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
                        child: browser,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.showInspector) SizedBox(width: 302, child: inspector),
            ],
          );
        },
      ),
    );
  }
}

class _LinkIdentityHeader extends StatelessWidget {
  const _LinkIdentityHeader({required this.controller});

  final LinkController controller;

  @override
  Widget build(BuildContext context) {
    final document = controller.document!;
    return Container(
      key: const ValueKey('link-workspace-header'),
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Color(0xFF06120E),
        border: Border(
          bottom: BorderSide(color: Color(0xFF173B30)),
          right: BorderSide(color: Color(0xFF173B30)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0B2A20),
              border: Border.all(color: const Color(0xFF2A765A)),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              LucideIcons.globe,
              color: Color(0xFF5DE7A7),
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF1FFF7),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  document.uri.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9BB4AB),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0A2A20),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF245B48)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF5DE7A7),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 6, height: 6),
                ),
                SizedBox(width: 6),
                Text(
                  '已保存',
                  style: TextStyle(color: Color(0xFF5DE7A7), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkDetailsInspector extends StatefulWidget {
  const _LinkDetailsInspector({
    super.key,
    required this.controller,
    required this.resource,
    required this.metadataController,
    required this.onToggleFavorite,
    required this.titleController,
    required this.notesController,
    required this.onSaveTitle,
    required this.onSaveNotes,
  });

  final LinkController controller;
  final WorkbenchResource? resource;
  final MetadataController? metadataController;
  final Future<void> Function(String resourceId)? onToggleFavorite;
  final TextEditingController titleController;
  final TextEditingController notesController;
  final ValueChanged<String> onSaveTitle;
  final VoidCallback onSaveNotes;

  @override
  State<_LinkDetailsInspector> createState() => _LinkDetailsInspectorState();
}

class _LinkDetailsInspectorState extends State<_LinkDetailsInspector> {
  late final TextEditingController _tagsController;
  var _editingTags = false;

  @override
  void initState() {
    super.initState();
    _tagsController = TextEditingController(text: _tags.join(', '));
    widget.metadataController?.addListener(_onMetadataChanged);
  }

  @override
  void didUpdateWidget(covariant _LinkDetailsInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metadataController != widget.metadataController) {
      oldWidget.metadataController?.removeListener(_onMetadataChanged);
      widget.metadataController?.addListener(_onMetadataChanged);
    }
    if (oldWidget.resource?.id != widget.resource?.id) {
      _tagsController.text = _tags.join(', ');
      _editingTags = false;
    }
  }

  @override
  void dispose() {
    widget.metadataController?.removeListener(_onMetadataChanged);
    _tagsController.dispose();
    super.dispose();
  }

  List<String> get _tags {
    final resource = widget.resource;
    final metadata = widget.metadataController;
    if (resource != null && metadata != null) {
      final tags = metadata.metadataFor(resource.id).tags;
      if (tags.isNotEmpty) {
        return tags;
      }
    }
    return widget.controller.document?.tags ?? const [];
  }

  bool get _isFavorite {
    final resource = widget.resource;
    final metadata = widget.metadataController;
    if (resource != null && metadata != null) {
      return metadata.metadataFor(resource.id).isFavorite;
    }
    return resource?.isFavorite ?? false;
  }

  void _onMetadataChanged() {
    if (!mounted) {
      return;
    }
    if (!_tagsController.selection.isValid) {
      _tagsController.text = _tags.join(', ');
    }
    setState(() {});
  }

  Future<void> _persistTags(String value) async {
    final resource = widget.resource;
    final metadata = widget.metadataController;
    if (resource == null || metadata == null) {
      return;
    }
    final tags = value
        .split(RegExp(r'[,，]'))
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    await metadata.updateTags(resource.id, tags);
    if (mounted) {
      setState(() => _editingTags = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final resource = widget.resource;
    if (resource == null) {
      return;
    }
    final metadata = widget.metadataController;
    if (metadata != null) {
      await metadata.toggleFavorite(resource.id);
      return;
    }
    await widget.onToggleFavorite?.call(resource.id);
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.controller.document!;
    final tags = _tags;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: const BoxDecoration(
        color: Color(0xFF06120E),
        border: Border(left: BorderSide(color: Color(0xFF173B30))),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '链接信息',
              style: TextStyle(
                color: Color(0xFFF1FFF7),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            const WorkbenchFieldLabel('标题'),
            const SizedBox(height: 7),
            WorkbenchInput(
              key: const ValueKey('link-title-field'),
              controller: widget.titleController,
              placeholder: '输入标题',
              onSubmitted: widget.onSaveTitle,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(child: WorkbenchFieldLabel('标签')),
                if (widget.metadataController != null)
                  WorkbenchIconButton(
                    icon: const Icon(LucideIcons.plus, size: 15),
                    semanticLabel: '编辑标签',
                    onPressed: () => setState(() => _editingTags = true),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                if (tags.isEmpty)
                  const Text(
                    '暂无标签',
                    style: TextStyle(color: Color(0xFF789087), fontSize: 12),
                  )
                else
                  for (final tag in tags) _TagChip(label: tag),
              ],
            ),
            if (_editingTags) ...[
              const SizedBox(height: 9),
              WorkbenchInput(
                key: const ValueKey('link-tags-field'),
                controller: _tagsController,
                placeholder: '用逗号分隔',
                autofocus: true,
                onSubmitted: _persistTags,
              ),
            ],
            const SizedBox(height: 20),
            const WorkbenchFieldLabel('备注'),
            const SizedBox(height: 7),
            WorkbenchInput(
              key: const ValueKey('link-notes-field'),
              controller: widget.notesController,
              placeholder: '补充网站用途或阅读提示',
              maxLines: 4,
              onEditingComplete: widget.onSaveNotes,
            ),
            const SizedBox(height: 20),
            const _InspectorDivider(),
            _InspectorActionRow(
              key: const ValueKey('link-favorite-button'),
              icon: LucideIcons.heart,
              label: '收藏',
              value: _isFavorite ? '已开启' : '未收藏',
              onTap: widget.resource == null ? null : _toggleFavorite,
            ),
            const _InspectorActionRow(
              icon: LucideIcons.clock3,
              label: '最后访问',
              value: '刚刚',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: WorkbenchButton(
                    key: const ValueKey('link-copy-button'),
                    size: WorkbenchButtonSize.lg,
                    expands: true,
                    semanticLabel: '复制链接',
                    onPressed: widget.controller.copyUrl,
                    leading: const Icon(LucideIcons.copy, size: 16),
                    child: const Text('复制链接'),
                  ),
                ),
                const SizedBox(width: 8),
                WorkbenchIconButton(
                  key: const ValueKey('link-external-button'),
                  tooltip: '在外部浏览器打开',
                  semanticLabel: '在外部浏览器打开',
                  variant: WorkbenchButtonVariant.outline,
                  icon: const Icon(LucideIcons.externalLink, size: 17),
                  onPressed: widget.controller.openExternally,
                ),
              ],
            ),
            if (widget.controller.errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                widget.controller.errorMessage!,
                style: const TextStyle(
                  color: MacosColors.systemRedColor,
                  fontSize: 11,
                ),
              ),
            ] else if (widget.controller.statusMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                widget.controller.statusMessage!,
                style: const TextStyle(color: Color(0xFF9BB4AB), fontSize: 11),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              document.relativePath,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF5D756B), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF123126),
        border: Border.all(color: const Color(0xFF2A5B47)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFFCEE4D8), fontSize: 11),
      ),
    );
  }
}

class _InspectorDivider extends StatelessWidget {
  const _InspectorDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      child: ColoredBox(color: Color(0xFF173B30)),
    );
  }
}

class _InspectorActionRow extends StatelessWidget {
  const _InspectorActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: '$label：$value',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 45,
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFB8CCC3), size: 17),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFD9EAE1),
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(color: Color(0xFF9BB4AB), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
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
