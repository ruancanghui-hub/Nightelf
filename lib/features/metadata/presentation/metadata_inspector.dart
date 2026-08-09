import 'package:ai_workbench/features/metadata/application/metadata_controller.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// Edits description, tags, favorites, and related resources for one item.
class MetadataInspector extends StatefulWidget {
  const MetadataInspector({
    super.key,
    required this.resource,
    required this.typeLabel,
    required this.statusLabel,
    required this.metadataController,
    required this.allResources,
    this.onOpenRelated,
  });

  final WorkbenchResource resource;
  final String typeLabel;
  final String statusLabel;
  final MetadataController metadataController;
  final List<WorkbenchResource> allResources;
  final ValueChanged<WorkbenchResource>? onOpenRelated;

  @override
  State<MetadataInspector> createState() => _MetadataInspectorState();
}

class _MetadataInspectorState extends State<MetadataInspector> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;
  String? _relinkTargetId;

  @override
  void initState() {
    super.initState();
    final meta = widget.metadataController.metadataFor(widget.resource.id);
    _descriptionController = TextEditingController(text: meta.description);
    _tagsController = TextEditingController(text: meta.tags.join(', '));
    widget.metadataController.addListener(_onMetadataChanged);
  }

  @override
  void didUpdateWidget(covariant MetadataInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resource.id != widget.resource.id) {
      final meta = widget.metadataController.metadataFor(widget.resource.id);
      _descriptionController.text = meta.description;
      _tagsController.text = meta.tags.join(', ');
      _relinkTargetId = null;
    }
    if (oldWidget.metadataController != widget.metadataController) {
      oldWidget.metadataController.removeListener(_onMetadataChanged);
      widget.metadataController.addListener(_onMetadataChanged);
    }
  }

  @override
  void dispose() {
    widget.metadataController.removeListener(_onMetadataChanged);
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _onMetadataChanged() {
    if (!mounted) {
      return;
    }
    final meta = widget.metadataController.metadataFor(widget.resource.id);
    if (_descriptionController.text != meta.description &&
        !_descriptionController.selection.isValid) {
      _descriptionController.text = meta.description;
    }
    final tagsText = meta.tags.join(', ');
    if (_tagsController.text != tagsText &&
        !_tagsController.selection.isValid) {
      _tagsController.text = tagsText;
    }
    setState(() {});
  }

  Map<String, String> get _titleById => {
    for (final resource in widget.allResources) resource.id: resource.title,
  };

  Future<void> _persistDescription() async {
    await widget.metadataController.updateDescription(
      widget.resource.id,
      _descriptionController.text,
    );
  }

  Future<void> _persistTags() async {
    final tags = _tagsController.text
        .split(RegExp(r'[,，]'))
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    await widget.metadataController.updateTags(widget.resource.id, tags);
  }

  Future<void> _addRelated(String relatedId) async {
    final current = widget.metadataController
        .metadataFor(widget.resource.id)
        .relatedResourceIds;
    if (relatedId == widget.resource.id || current.contains(relatedId)) {
      return;
    }
    await widget.metadataController.setRelatedResourceIds(widget.resource.id, [
      ...current,
      relatedId,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;
    final meta = widget.metadataController.metadataFor(widget.resource.id);
    final related = widget.metadataController.relatedRefsFor(
      widget.resource.id,
      titleLookup: (id) => _titleById[id],
    );
    final candidates = widget.allResources
        .where((resource) => resource.id != widget.resource.id)
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MacosTheme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('检查器', style: typography.headline),
          const SizedBox(height: 16),
          Text('类型：${widget.typeLabel}'),
          const SizedBox(height: 8),
          Text('资源 ID：${widget.resource.id}'),
          if (widget.resource.relativePath != null) ...[
            const SizedBox(height: 8),
            Text('路径：${widget.resource.relativePath}'),
          ],
          const SizedBox(height: 8),
          Text('数据源：Vault 文件'),
          const SizedBox(height: 12),
          Text('状态：${widget.statusLabel}', style: typography.caption1),
          const SizedBox(height: 16),
          const WorkbenchFieldLabel('描述'),
          const SizedBox(height: 6),
          WorkbenchInput(
            controller: _descriptionController,
            maxLines: 3,
            placeholder: '补充说明',
            semanticLabel: '资源描述',
            onEditingComplete: _persistDescription,
            onSubmitted: (_) => _persistDescription(),
          ),
          const SizedBox(height: 12),
          const WorkbenchFieldLabel('标签'),
          const SizedBox(height: 6),
          WorkbenchInput(
            controller: _tagsController,
            placeholder: '用逗号分隔',
            semanticLabel: '资源标签',
            onEditingComplete: _persistTags,
            onSubmitted: (_) => _persistTags(),
          ),
          const SizedBox(height: 16),
          WorkbenchButton(
            semanticLabel: meta.isFavorite
                ? '取消收藏：${widget.resource.title}'
                : '收藏：${widget.resource.title}',
            onPressed: () =>
                widget.metadataController.toggleFavorite(widget.resource.id),
            child: Text(meta.isFavorite ? '取消收藏' : '加入收藏'),
          ),
          const SizedBox(height: 8),
          Text('收藏、标签与关联保存在当前 Vault 内。', style: typography.caption1),
          const SizedBox(height: 16),
          Text('关联资源', style: typography.subheadline),
          const SizedBox(height: 8),
          if (related.isEmpty)
            Text('暂无关联', style: typography.caption1)
          else
            for (final ref in related)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      ref.isMissing ? '缺失资源（${ref.resourceId}）' : ref.title,
                      style: typography.body,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (!ref.isMissing && widget.onOpenRelated != null)
                          WorkbenchButton(
                            size: WorkbenchButtonSize.sm,
                            variant: WorkbenchButtonVariant.outline,
                            semanticLabel: '打开关联：${ref.title}',
                            onPressed: () {
                              WorkbenchResource? target;
                              for (final item in widget.allResources) {
                                if (item.id == ref.resourceId) {
                                  target = item;
                                  break;
                                }
                              }
                              if (target != null) {
                                widget.onOpenRelated!(target);
                              }
                            },
                            child: const Text('打开'),
                          ),
                        WorkbenchButton(
                          size: WorkbenchButtonSize.sm,
                          variant: WorkbenchButtonVariant.outline,
                          semanticLabel: '移除关联：${ref.resourceId}',
                          onPressed: () =>
                              widget.metadataController.removeRelatedResource(
                                widget.resource.id,
                                ref.resourceId,
                              ),
                          child: const Text('移除'),
                        ),
                        if (ref.isMissing)
                          WorkbenchButton(
                            size: WorkbenchButtonSize.sm,
                            variant: WorkbenchButtonVariant.outline,
                            semanticLabel: '重新关联：${ref.resourceId}',
                            onPressed: () => setState(
                              () => _relinkTargetId = ref.resourceId,
                            ),
                            child: const Text('重新关联'),
                          ),
                      ],
                    ),
                    if (_relinkTargetId == ref.resourceId) ...[
                      const SizedBox(height: 6),
                      for (final candidate in candidates.take(8))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: WorkbenchButton(
                            size: WorkbenchButtonSize.sm,
                            semanticLabel: '关联到：${candidate.title}',
                            onPressed: () async {
                              await widget.metadataController
                                  .relinkRelatedResource(
                                    resourceId: widget.resource.id,
                                    missingId: ref.resourceId,
                                    replacementId: candidate.id,
                                  );
                              if (mounted) {
                                setState(() => _relinkTargetId = null);
                              }
                            },
                            child: Text(candidate.title),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
          const SizedBox(height: 8),
          Text('添加关联', style: typography.caption1),
          const SizedBox(height: 6),
          for (final candidate in candidates.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: WorkbenchButton(
                size: WorkbenchButtonSize.sm,
                variant: WorkbenchButtonVariant.outline,
                semanticLabel: '添加关联：${candidate.title}',
                onPressed: () => _addRelated(candidate.id),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(candidate.title, overflow: TextOverflow.ellipsis),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text('编辑会在约 0.6 秒后自动保存，也可按 ⌘S。', style: typography.caption1),
        ],
      ),
    );
  }
}
