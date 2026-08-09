import 'package:ai_workbench/features/metadata/domain/resource_metadata.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// Lists synchronized collections under the fixed destinations.
class CollectionSidebarSection extends StatelessWidget {
  const CollectionSidebarSection({
    super.key,
    required this.collections,
    required this.selectedCollectionId,
    required this.onCollectionSelected,
    required this.onCreateCollection,
    required this.onEditCollection,
  });

  final List<CollectionRecord> collections;
  final String? selectedCollectionId;
  final ValueChanged<CollectionRecord?> onCollectionSelected;
  final VoidCallback onCreateCollection;
  final ValueChanged<CollectionRecord> onEditCollection;

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('集合', style: typography.subheadline)),
            PushButton(
              controlSize: ControlSize.small,
              secondary: true,
              semanticLabel: '新建集合',
              onPressed: onCreateCollection,
              child: const Text('新建'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (collections.isEmpty)
          Text('暂无集合', style: typography.caption1)
        else
          for (final collection in collections)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: PushButton(
                      controlSize: ControlSize.small,
                      color: collection.id == selectedCollectionId
                          ? MacosTheme.of(context).primaryColor
                          : null,
                      semanticLabel: '集合：${collection.name}',
                      onPressed: () {
                        if (collection.id == selectedCollectionId) {
                          onCollectionSelected(null);
                        } else {
                          onCollectionSelected(collection);
                        }
                      },
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          collection.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  PushButton(
                    controlSize: ControlSize.small,
                    secondary: true,
                    semanticLabel: '编辑集合：${collection.name}',
                    onPressed: () => onEditCollection(collection),
                    child: const Text('编辑'),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
