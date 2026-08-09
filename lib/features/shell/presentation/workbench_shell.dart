import 'package:ai_workbench/features/command_palette/presentation/command_palette.dart';
import 'package:ai_workbench/features/library/presentation/resource_list_pane.dart';
import 'package:ai_workbench/features/metadata/application/metadata_controller.dart';
import 'package:ai_workbench/features/metadata/domain/resource_metadata.dart';
import 'package:ai_workbench/features/metadata/presentation/collection_editor_sheet.dart';
import 'package:ai_workbench/features/shell/application/workbench_controller.dart';
import 'package:ai_workbench/features/shell/application/workspace_tabs_controller.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/shell/domain/workspace_tab.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_sidebar.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_toolbar.dart';
import 'package:ai_workbench/features/shell/presentation/workspace_tab_strip.dart';
import 'package:ai_workbench/features/workspaces/presentation/workspace_content.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// A dark/light Apple-style three-region shell for mock or Vault-backed records.
class WorkbenchShell extends StatefulWidget {
  const WorkbenchShell({
    super.key,
    this.resources,
    this.onDestinationChanged,
    this.vaultRootPath,
    this.onToggleFavorite,
    this.metadataController,
  });

  final List<WorkbenchResource>? resources;
  final ValueChanged<ResourceType>? onDestinationChanged;
  final String? vaultRootPath;
  final Future<void> Function(String resourceId)? onToggleFavorite;
  final MetadataController? metadataController;

  @override
  State<WorkbenchShell> createState() => WorkbenchShellState();
}

class WorkbenchShellState extends State<WorkbenchShell> {
  late final WorkbenchController _controller;
  late final WorkspaceTabsController _tabsController;
  bool _isPaletteOpen = false;
  CollectionRecord? _editingCollection;
  bool _creatingCollection = false;

  void applyFavoriteIds(Set<String> favoriteIds) {
    _controller.applyFavoriteIds(favoriteIds);
  }

  void applyRecentResourceIds(List<String> recentResourceIds) {
    _controller.applyRecentResourceIds(recentResourceIds);
  }

  Set<String> toggleFavorite(String resourceId) {
    return _controller.toggleFavorite(resourceId);
  }

  @override
  void initState() {
    super.initState();
    _controller = WorkbenchController(resources: widget.resources)
      ..addListener(_refresh);
    _tabsController = WorkspaceTabsController()..addListener(_refresh);
    widget.metadataController?.addListener(_onMetadataChanged);
    if (widget.metadataController != null) {
      _controller.applyRecentResourceIds(
        widget.metadataController!.recentResourceIds,
      );
      _controller.applyFavoriteIds(widget.metadataController!.favoriteIds);
    }
    if (_controller.allResources.isNotEmpty) {
      _tabsController.openTab(_tabFor(_controller.selectedResource));
    }
  }

  @override
  void didUpdateWidget(covariant WorkbenchShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.resources, widget.resources) &&
        widget.resources != null) {
      _controller.replaceResources(widget.resources!);
    }
    if (oldWidget.metadataController != widget.metadataController) {
      oldWidget.metadataController?.removeListener(_onMetadataChanged);
      widget.metadataController?.addListener(_onMetadataChanged);
      _onMetadataChanged();
    }
  }

  @override
  void dispose() {
    widget.metadataController?.removeListener(_onMetadataChanged);
    _controller
      ..removeListener(_refresh)
      ..dispose();
    _tabsController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _onMetadataChanged() {
    final metadata = widget.metadataController;
    if (metadata == null) {
      return;
    }
    _controller.applyFavoriteIds(metadata.favoriteIds);
    _controller.applyRecentResourceIds(metadata.recentResourceIds);
    final selectedId = _controller.selectedCollectionId;
    if (selectedId != null) {
      CollectionRecord? selected;
      for (final collection in metadata.collections) {
        if (collection.id == selectedId) {
          selected = collection;
          break;
        }
      }
      if (selected == null) {
        _controller.selectCollection(collectionId: null, memberIds: null);
      } else {
        _controller.selectCollection(
          collectionId: selected.id,
          memberIds: selected.resourceIds.toSet(),
        );
      }
    }
    _refresh();
  }

  void _refresh() => setState(() {});

  WorkspaceTab _tabFor(WorkbenchResource resource) => WorkspaceTab(
    resourceId: resource.id,
    title: resource.title,
    type: resource.type,
  );

  WorkbenchResource? get _activeResource {
    final activeId = _tabsController.activeResourceId;
    return activeId == null ? null : _controller.resourceById(activeId);
  }

  void _selectDestination(ResourceType type) {
    _controller.selectDestination(type);
    widget.onDestinationChanged?.call(type);
    if (_controller.allResources.isNotEmpty &&
        _controller.selectedResources.isNotEmpty) {
      _tabsController.openTab(_tabFor(_controller.selectedResource));
    }
  }

  Future<void> _openResource(WorkbenchResource resource) async {
    _controller.selectResource(resource);
    _tabsController.openTab(_tabFor(resource));
    if (_isPaletteOpen) {
      setState(() => _isPaletteOpen = false);
    }
    await widget.metadataController?.recordRecent(resource.id);
  }

  void _activateTab(String resourceId) {
    final resource = _controller.resourceById(resourceId);
    if (resource == null) {
      return;
    }
    _tabsController.activateTab(resourceId);
    _controller.selectResource(resource);
    widget.metadataController?.recordRecent(resourceId);
  }

  void _closeTab(String resourceId) {
    _tabsController.closeTab(resourceId);
    final activeId = _tabsController.activeResourceId;
    final resource = activeId == null
        ? null
        : _controller.resourceById(activeId);
    if (resource != null) {
      _controller.selectResource(resource);
    }
  }

  void _openPalette() => setState(() => _isPaletteOpen = true);

  void _closePalette() => setState(() => _isPaletteOpen = false);

  void _selectCollection(CollectionRecord? collection) {
    if (collection == null) {
      _controller.selectCollection(collectionId: null, memberIds: null);
      return;
    }
    _controller.selectCollection(
      collectionId: collection.id,
      memberIds: collection.resourceIds.toSet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metadata = widget.metadataController;
    final editing = _editingCollection;
    final showEditor =
        metadata != null && (_creatingCollection || editing != null);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _openPalette,
        const SingleActivator(LogicalKeyboardKey.escape): _closePalette,
      },
      child: Focus(
        autofocus: true,
        child: MacosWindow(
          child: Stack(
            children: [
              MacosScaffold(
                children: [
                  ContentArea(
                    builder: (context, scrollController) => Column(
                      children: [
                        WorkbenchToolbar(onGlobalSearch: _openPalette),
                        Expanded(
                          child: Row(
                            children: [
                              WorkbenchSidebar(
                                controller: _controller,
                                onDestinationSelected: _selectDestination,
                                onResourceSelected: _openResource,
                                collections: metadata?.collections ?? const [],
                                onCollectionSelected: metadata == null
                                    ? null
                                    : _selectCollection,
                                onCreateCollection: metadata == null
                                    ? null
                                    : () => setState(() {
                                        _creatingCollection = true;
                                        _editingCollection = null;
                                      }),
                                onEditCollection: metadata == null
                                    ? null
                                    : (collection) => setState(() {
                                        _creatingCollection = false;
                                        _editingCollection = collection;
                                      }),
                              ),
                              ResourceListPane(
                                controller: _controller,
                                onResourceSelected: _openResource,
                                onToggleFavorite: widget.onToggleFavorite,
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    WorkspaceTabStrip(
                                      controller: _tabsController,
                                      onTabActivated: _activateTab,
                                      onTabClosed: _closeTab,
                                    ),
                                    Expanded(
                                      child: WorkspaceContent(
                                        resource: _activeResource,
                                        vaultRootPath: widget.vaultRootPath,
                                        onToggleFavorite:
                                            widget.onToggleFavorite,
                                        metadataController: metadata,
                                        allResources: _controller.allResources,
                                        onOpenRelated: _openResource,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_isPaletteOpen)
                CommandPalette(
                  resources: _controller.allResources,
                  onResourceSelected: _openResource,
                  onDismissed: _closePalette,
                ),
              if (showEditor)
                CollectionEditorSheet(
                  metadataController: metadata,
                  allResources: _controller.allResources,
                  collection: editing,
                  onClose: () => setState(() {
                    _creatingCollection = false;
                    _editingCollection = null;
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
