import 'package:ai_workbench/features/metadata/application/metadata_controller.dart';
import 'package:ai_workbench/features/metadata/domain/resource_metadata.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// Creates, renames, deletes a collection and edits its members.
class CollectionEditorSheet extends StatefulWidget {
  const CollectionEditorSheet({
    super.key,
    required this.metadataController,
    required this.allResources,
    this.collection,
    this.onClose,
  });

  final MetadataController metadataController;
  final List<WorkbenchResource> allResources;
  final CollectionRecord? collection;
  final VoidCallback? onClose;

  @override
  State<CollectionEditorSheet> createState() => _CollectionEditorSheetState();
}

class _CollectionEditorSheetState extends State<CollectionEditorSheet> {
  late final TextEditingController _nameController;
  late Set<String> _memberIds;
  String? _error;
  bool _busy = false;

  bool get _isEditing => widget.collection != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.collection?.name ?? '',
    );
    _memberIds = {...?widget.collection?.resourceIds};
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _titleFor(String id) {
    for (final resource in widget.allResources) {
      if (resource.id == id) {
        return resource.title;
      }
    }
    return null;
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_isEditing) {
        await widget.metadataController.renameCollection(
          widget.collection!.id,
          _nameController.text,
        );
        await widget.metadataController.setCollectionMembers(
          widget.collection!.id,
          _memberIds.toList(),
        );
      } else {
        final created = await widget.metadataController.createCollection(
          _nameController.text,
        );
        await widget.metadataController.setCollectionMembers(
          created.id,
          _memberIds.toList(),
        );
      }
      widget.onClose?.call();
    } on Object catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _delete() async {
    final collection = widget.collection;
    if (collection == null) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.metadataController.deleteCollection(collection.id);
      widget.onClose?.call();
    } on Object catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;
    final missingIds = _memberIds.where((id) => _titleFor(id) == null).toList();

    return ColoredBox(
      color: MacosTheme.of(context).canvasColor.withValues(alpha: 0.96),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      _isEditing ? '编辑集合' : '新建集合',
                      style: typography.title2,
                    ),
                    const Spacer(),
                    PushButton(
                      controlSize: ControlSize.small,
                      secondary: true,
                      semanticLabel: '关闭集合编辑',
                      onPressed: _busy ? null : widget.onClose,
                      child: const Text('关闭'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('删除集合不会删除其中的资源。缺失成员显示为“缺失资源”。', style: typography.body),
                const SizedBox(height: 12),
                Semantics(
                  label: '集合名称',
                  textField: true,
                  child: MacosTextField(
                    controller: _nameController,
                    placeholder: '集合名称',
                    enabled: !_busy,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: typography.caption1),
                ],
                const SizedBox(height: 12),
                Text('成员', style: typography.subheadline),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView(
                    children: [
                      for (final resource in widget.allResources)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  resource.title,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              PushButton(
                                controlSize: ControlSize.small,
                                secondary: !_memberIds.contains(resource.id),
                                semanticLabel:
                                    (_memberIds.contains(resource.id)
                                        ? '移出集合：'
                                        : '加入集合：') +
                                    resource.title,
                                onPressed: _busy
                                    ? null
                                    : () {
                                        setState(() {
                                          if (_memberIds.contains(
                                            resource.id,
                                          )) {
                                            _memberIds.remove(resource.id);
                                          } else {
                                            _memberIds.add(resource.id);
                                          }
                                        });
                                      },
                                child: Text(
                                  _memberIds.contains(resource.id)
                                      ? '已加入'
                                      : '加入',
                                ),
                              ),
                            ],
                          ),
                        ),
                      for (final missingId in missingIds)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '缺失资源（$missingId）',
                                  style: typography.caption1,
                                ),
                              ),
                              PushButton(
                                controlSize: ControlSize.small,
                                secondary: true,
                                semanticLabel: '移除缺失成员：$missingId',
                                onPressed: _busy
                                    ? null
                                    : () => setState(
                                        () => _memberIds.remove(missingId),
                                      ),
                                child: const Text('移除'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_isEditing)
                      PushButton(
                        controlSize: ControlSize.large,
                        secondary: true,
                        semanticLabel: '删除集合',
                        onPressed: _busy ? null : _delete,
                        child: const Text('删除集合'),
                      ),
                    const Spacer(),
                    PushButton(
                      controlSize: ControlSize.large,
                      semanticLabel: '保存集合',
                      onPressed: _busy ? null : _save,
                      child: Text(_busy ? '保存中…' : '保存'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
