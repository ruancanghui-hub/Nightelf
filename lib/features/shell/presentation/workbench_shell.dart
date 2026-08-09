import 'package:ai_workbench/features/command_palette/presentation/command_palette.dart';
import 'package:ai_workbench/features/library/presentation/resource_list_pane.dart';
import 'package:ai_workbench/features/metadata/application/metadata_controller.dart';
import 'package:ai_workbench/features/metadata/domain/resource_metadata.dart';
import 'package:ai_workbench/features/metadata/presentation/collection_editor_sheet.dart';
import 'package:ai_workbench/features/shell/application/workbench_controller.dart';
import 'package:ai_workbench/features/shell/application/workbench_intents.dart';
import 'package:ai_workbench/features/shell/application/workbench_shortcuts.dart';
import 'package:ai_workbench/features/shell/application/workspace_tabs_controller.dart';
import 'package:ai_workbench/features/shell/data/workspace_restoration_repository.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/shell/domain/workspace_tab.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_sidebar.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_toolbar.dart';
import 'package:ai_workbench/features/shell/presentation/workspace_tab_strip.dart';
import 'package:ai_workbench/features/workspaces/presentation/workspace_content.dart';
import 'package:flutter/foundation.dart';
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
    this.restorationRepository,
  });

  final List<WorkbenchResource>? resources;
  final ValueChanged<ResourceType>? onDestinationChanged;
  final String? vaultRootPath;
  final Future<void> Function(String resourceId)? onToggleFavorite;
  final MetadataController? metadataController;
  final WorkspaceRestorationRepository? restorationRepository;

  @override
  State<WorkbenchShell> createState() => WorkbenchShellState();
}

class WorkbenchShellState extends State<WorkbenchShell> {
  late final WorkbenchController _controller;
  late final WorkspaceTabsController _tabsController;
  late final FocusNode _sidebarFocusNode;
  late final FocusNode _contentFocusNode;
  bool _isPaletteOpen = false;
  bool _inspectorVisible = true;
  double _sidebarWidth = 248;
  CollectionRecord? _editingCollection;
  bool _creatingCollection = false;
  bool _didRestore = false;

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
    _sidebarFocusNode = FocusNode(debugLabel: 'workbench-sidebar');
    _contentFocusNode = FocusNode(debugLabel: 'workbench-content');
    _controller = WorkbenchController(resources: widget.resources)
      ..addListener(_refresh);
    _tabsController = WorkspaceTabsController()..addListener(_onTabsChanged);
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
    _restoreWorkspace();
  }

  @override
  void didUpdateWidget(covariant WorkbenchShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.resources, widget.resources) &&
        widget.resources != null) {
      _controller.replaceResources(widget.resources!);
      if (!_didRestore) {
        _restoreWorkspace();
      }
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
      ..removeListener(_onTabsChanged)
      ..dispose();
    _sidebarFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _onTabsChanged() {
    _persistWorkspace();
    _refresh();
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

  Future<void> _restoreWorkspace() async {
    final repo = widget.restorationRepository;
    if (repo == null || _didRestore) {
      return;
    }
    final known = _controller.allResources.map((item) => item.id).toSet();
    if (known.isEmpty) {
      return;
    }
    final state = await repo.load(knownResourceIds: known);
    if (!mounted) {
      return;
    }
    _didRestore = true;
    _sidebarWidth = state.sidebarWidth;
    _inspectorVisible = state.inspectorVisible;
    for (final id in state.openResourceIds) {
      final resource = _controller.resourceById(id);
      if (resource != null) {
        _tabsController.openTab(_tabFor(resource));
      }
    }
    final activeId = state.activeResourceId;
    if (activeId != null) {
      final resource = _controller.resourceById(activeId);
      if (resource != null) {
        _tabsController.activateTab(activeId);
        _controller.selectResource(resource);
      }
    }
    _refresh();
  }

  Future<void> _persistWorkspace() async {
    final repo = widget.restorationRepository;
    if (repo == null) {
      return;
    }
    await repo.save(
      WorkspaceRestorationState(
        openResourceIds: _tabsController.tabs
            .map((tab) => tab.resourceId)
            .toList(growable: false),
        activeResourceId: _tabsController.activeResourceId,
        sidebarWidth: _sidebarWidth,
        inspectorVisible: _inspectorVisible,
      ),
    );
  }

  WorkspaceTab _tabFor(WorkbenchResource resource) => WorkspaceTab(
    resourceId: resource.id,
    title: resource.title,
    type: resource.type,
  );

  WorkbenchResource? get _activeResource {
    final activeId = _tabsController.activeResourceId;
    return activeId == null ? null : _controller.resourceById(activeId);
  }

  /// Content follows the current destination: never keep showing another
  /// category's tab after the sidebar selection changes.
  WorkbenchResource? get _contentResource {
    final matching = _controller.selectedResources;
    if (matching.isEmpty) {
      return null;
    }
    final active = _activeResource;
    if (active != null &&
        matching.any((resource) => resource.id == active.id)) {
      return active;
    }
    if (_tabsController.activeResourceId == null) {
      return null;
    }
    return matching.first;
  }

  void _selectDestination(ResourceType type) {
    _controller.selectDestination(type);
    widget.onDestinationChanged?.call(type);
    final matching = _controller.selectedResources;
    if (matching.isNotEmpty) {
      _tabsController.openTab(_tabFor(matching.first));
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

  void _toggleInspector() {
    setState(() => _inspectorVisible = !_inspectorVisible);
    _persistWorkspace();
  }

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

  Map<Type, Action<Intent>> get _actions => {
    OpenCommandPaletteIntent: CallbackAction<OpenCommandPaletteIntent>(
      onInvoke: (_) {
        _openPalette();
        return null;
      },
    ),
    QuickOpenIntent: CallbackAction<QuickOpenIntent>(
      onInvoke: (_) {
        _openPalette();
        return null;
      },
    ),
    SaveDocumentIntent: CallbackAction<SaveDocumentIntent>(
      onInvoke: (_) {
        // Document editors handle ⌘S in their own focus scope.
        return null;
      },
    ),
    SyncVaultIntent: CallbackAction<SyncVaultIntent>(
      onInvoke: (_) {
        // Disabled until Phase 5 registers a sync action.
        return null;
      },
    ),
    CloseActiveTabIntent: CallbackAction<CloseActiveTabIntent>(
      onInvoke: (_) {
        final activeId = _tabsController.activeResourceId;
        if (activeId != null) {
          _closeTab(activeId);
        }
        return null;
      },
    ),
    FocusSidebarIntent: CallbackAction<FocusSidebarIntent>(
      onInvoke: (_) {
        _sidebarFocusNode.requestFocus();
        return null;
      },
    ),
    FocusContentIntent: CallbackAction<FocusContentIntent>(
      onInvoke: (_) {
        _contentFocusNode.requestFocus();
        return null;
      },
    ),
    ToggleInspectorIntent: CallbackAction<ToggleInspectorIntent>(
      onInvoke: (_) {
        _toggleInspector();
        return null;
      },
    ),
    DismissIntent: CallbackAction<DismissIntent>(
      onInvoke: (_) {
        if (_isPaletteOpen) {
          _closePalette();
        }
        return null;
      },
    ),
  };

  @override
  Widget build(BuildContext context) {
    final metadata = widget.metadataController;
    final editing = _editingCollection;
    final showEditor =
        metadata != null && (_creatingCollection || editing != null);
    final palette = _isPaletteOpen
        ? CommandPalette(
            resources: _controller.allResources,
            onResourceSelected: _openResource,
            onDismissed: _closePalette,
          )
        : null;

    return Shortcuts(
      shortcuts: workbenchShortcuts(),
      child: Actions(
        actions: _actions,
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final mediaWidth = MediaQuery.sizeOf(context).width;
              final width =
                  constraints.maxWidth.isFinite && constraints.maxWidth > 0
                  ? constraints.maxWidth
                  : (mediaWidth > 0 ? mediaWidth : 1440);
              final compactSidebar = width < 760;
              final collapseInspector = width < 980 || !_inspectorVisible;

              return MacosWindow(
                child: Stack(
                  children: [
                    MacosScaffold(
                      children: [
                        ContentArea(
                          builder: (context, scrollController) {
                            return Column(
                              children: [
                                WorkbenchToolbar(
                                  onGlobalSearch: _openPalette,
                                  onToggleInspector: _toggleInspector,
                                  inspectorVisible: !collapseInspector,
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      WorkbenchSidebar(
                                        controller: _controller,
                                        compact: compactSidebar,
                                        focusNode: _sidebarFocusNode,
                                        onDestinationSelected:
                                            _selectDestination,
                                        onResourceSelected: _openResource,
                                        collections:
                                            metadata?.collections ?? const [],
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
                                        onToggleFavorite:
                                            widget.onToggleFavorite,
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
                                                resource: _contentResource,
                                                vaultRootPath:
                                                    widget.vaultRootPath,
                                                onToggleFavorite:
                                                    widget.onToggleFavorite,
                                                metadataController: metadata,
                                                allResources:
                                                    _controller.allResources,
                                                onOpenRelated: _openResource,
                                                showInspector:
                                                    !collapseInspector,
                                                contentFocusNode:
                                                    _contentFocusNode,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    if (palette != null) palette,
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
              );
            },
          ),
        ),
      ),
    );
  }
}
