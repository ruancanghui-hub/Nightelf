import 'package:ai_workbench/features/metadata/application/metadata_controller.dart';
import 'package:ai_workbench/features/metadata/data/metadata_repository.dart';
import 'package:ai_workbench/features/metadata/domain/resource_metadata.dart';
import 'package:ai_workbench/features/metadata/presentation/collection_sidebar_section.dart';
import 'package:ai_workbench/features/shell/application/workbench_controller.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

class _MemoryMetadataRepository implements MetadataRepository {
  MetadataSnapshot snapshot = const MetadataSnapshot();

  @override
  Future<MetadataSnapshot> load() async => snapshot;

  @override
  Future<void> saveResource(ResourceMetadata metadata) async {
    final resources = Map<String, ResourceMetadata>.from(snapshot.resources);
    resources[metadata.resourceId] = metadata;
    snapshot = MetadataSnapshot(
      resources: resources,
      collections: snapshot.collections,
      recentResourceIds: snapshot.recentResourceIds,
    );
  }

  @override
  Future<void> saveCollection(CollectionRecord collection) async {
    final collections = List<CollectionRecord>.from(snapshot.collections);
    final index = collections.indexWhere((item) => item.id == collection.id);
    if (index < 0) {
      collections.add(collection);
    } else {
      collections[index] = collection;
    }
    snapshot = MetadataSnapshot(
      resources: snapshot.resources,
      collections: collections,
      recentResourceIds: snapshot.recentResourceIds,
    );
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    snapshot = MetadataSnapshot(
      resources: snapshot.resources,
      collections: snapshot.collections
          .where((item) => item.id != collectionId)
          .toList(),
      recentResourceIds: snapshot.recentResourceIds,
    );
  }

  @override
  Future<void> recordRecent(String resourceId) async {
    snapshot = MetadataSnapshot(
      resources: snapshot.resources,
      collections: snapshot.collections,
      recentResourceIds: [
        resourceId,
        ...snapshot.recentResourceIds.where((id) => id != resourceId),
      ],
    );
  }
}

void main() {
  testWidgets('collection sidebar filters and shows missing members later', (
    tester,
  ) async {
    final repo = _MemoryMetadataRepository()
      ..snapshot = const MetadataSnapshot(
        collections: [
          CollectionRecord(
            id: 'col-1',
            name: '发布',
            resourceIds: ['prompt-release-notes', 'missing-1'],
          ),
        ],
      );
    final metadata = MetadataController(repository: repo, idFactory: () => 'x');
    await metadata.load();

    final controller = WorkbenchController();
    CollectionRecord? selected;

    await tester.pumpWidget(
      MacosApp(
        home: MacosWindow(
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              return WorkbenchFocusHarness(
                child: Column(
                  children: [
                    CollectionSidebarSection(
                      collections: metadata.collections,
                      selectedCollectionId: controller.selectedCollectionId,
                      onCollectionSelected: (collection) {
                        selected = collection;
                        controller.selectCollection(
                          collectionId: collection?.id,
                          memberIds: collection?.resourceIds.toSet(),
                        );
                      },
                      onCreateCollection: () {},
                      onEditCollection: (_) {},
                    ),
                    Text(
                      'visible:${controller.selectedResources.map((e) => e.id).join(',')}',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('发布'), findsOneWidget);
    await tester.tap(find.text('发布'));
    await tester.pump();
    expect(selected?.id, 'col-1');
    expect(controller.selectedResources.map((e) => e.id), [
      'prompt-release-notes',
    ]);
  });

  test('workbench recent ids resolve only present resources', () {
    final controller = WorkbenchController();
    controller.applyRecentResourceIds([
      'missing',
      'prompt-release-notes',
      'mcp-local-docs',
    ]);
    expect(controller.recentResources.map((e) => e.id), [
      'prompt-release-notes',
      'mcp-local-docs',
    ]);
  });
}

class WorkbenchFocusHarness extends StatelessWidget {
  const WorkbenchFocusHarness({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
