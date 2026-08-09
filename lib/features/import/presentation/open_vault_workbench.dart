import 'dart:async';
import 'dart:io';

import 'package:ai_workbench/features/import/application/import_controller.dart';
import 'package:ai_workbench/features/import/data/vault_import_repository.dart';
import 'package:ai_workbench/features/import/presentation/import_review_sheet.dart';
import 'package:ai_workbench/features/import/presentation/vault_drop_target.dart';
import 'package:ai_workbench/features/links/application/link_controller.dart';
import 'package:ai_workbench/features/links/data/file_link_repository.dart';
import 'package:ai_workbench/features/metadata/application/metadata_controller.dart';
import 'package:ai_workbench/features/metadata/data/json_metadata_repository.dart';
import 'package:ai_workbench/features/mcp/application/mcp_controller.dart';
import 'package:ai_workbench/features/mcp/data/file_mcp_repository.dart';
import 'package:ai_workbench/features/prompts/application/prompt_controller.dart';
import 'package:ai_workbench/features/prompts/data/file_prompt_repository.dart';
import 'package:ai_workbench/features/shell/data/workspace_restoration_repository.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart'
    as shell;
import 'package:ai_workbench/features/shell/domain/workbench_resource_mapper.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_shell.dart';
import 'package:ai_workbench/features/skills/application/skill_controller.dart';
import 'package:ai_workbench/features/skills/data/file_skill_repository.dart';
import 'package:ai_workbench/features/vault/application/vault_controller.dart';
import 'package:ai_workbench/features/vault/application/vault_state.dart';
import 'package:ai_workbench/features/workflows/application/workflow_controller.dart';
import 'package:ai_workbench/features/workflows/data/file_workflow_repository.dart';
import 'package:ai_workbench/features/workflows/data/json_workflow_layout_repository.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:ai_workbench/shared/platform/directory_picker_service.dart';
import 'package:ai_workbench/shared/platform/flutter_clipboard_service.dart';
import 'package:ai_workbench/shared/platform/macos_system_open_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

class OpenVaultWorkbench extends StatefulWidget {
  const OpenVaultWorkbench({
    super.key,
    required this.vaultController,
    required this.openState,
  });

  final VaultController vaultController;
  final VaultOpen openState;

  @override
  State<OpenVaultWorkbench> createState() => _OpenVaultWorkbenchState();
}

class _OpenVaultWorkbenchState extends State<OpenVaultWorkbench> {
  late final ImportController _importController;
  late MetadataController _metadataController;
  late PromptController _promptController;
  late SkillController _skillController;
  late McpController _mcpController;
  late LinkController _linkController;
  late WorkflowController _workflowController;
  late WorkspaceRestorationRepository _restorationRepository;
  bool _reviewOpen = false;
  String? _bannerMessage;
  shell.ResourceType? _preferredShellType;
  final GlobalKey<WorkbenchShellState> _shellKey =
      GlobalKey<WorkbenchShellState>();
  List<shell.WorkbenchResource>? _cachedResources;
  Object? _cachedResourcesKey;

  @override
  void initState() {
    super.initState();
    final root = widget.openState.handle.root;
    _metadataController = _createMetadataController(root);
    _promptController = _createPromptController(root);
    _skillController = _createSkillController(root);
    _mcpController = _createMcpController(root);
    _linkController = _createLinkController(root);
    _workflowController = _createWorkflowController(root);
    _restorationRepository = WorkspaceRestorationRepository(vaultRoot: root);
    _importController = ImportController(
      repository: VaultImportRepository(),
      onImported: (paths) => widget.vaultController.refreshPaths(paths),
    )..addListener(_onImportChanged);
    _metadataController.addListener(_onMetadataChanged);
    _loadMetadata();
    unawaited(_linkController.restoreFloatingBubbles());
  }

  @override
  void didUpdateWidget(covariant OpenVaultWorkbench oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openState.handle.root.path !=
        widget.openState.handle.root.path) {
      _metadataController
        ..removeListener(_onMetadataChanged)
        ..dispose();
      _promptController.dispose();
      _skillController.dispose();
      _mcpController.dispose();
      _linkController.dispose();
      _workflowController.dispose();
      final root = widget.openState.handle.root;
      _metadataController = _createMetadataController(root)
        ..addListener(_onMetadataChanged);
      _promptController = _createPromptController(root);
      _skillController = _createSkillController(root);
      _mcpController = _createMcpController(root);
      _linkController = _createLinkController(root);
      _workflowController = _createWorkflowController(root);
      _restorationRepository = WorkspaceRestorationRepository(vaultRoot: root);
      _cachedResources = null;
      _cachedResourcesKey = null;
      _loadMetadata();
      unawaited(_linkController.restoreFloatingBubbles());
    } else if (!identical(
      oldWidget.openState.resources,
      widget.openState.resources,
    )) {
      _cachedResources = null;
      _cachedResourcesKey = null;
      _shellKey.currentState?.applyFavoriteIds(_metadataController.favoriteIds);
      _shellKey.currentState?.applyRecentEntries(
        _metadataController.recentEntries,
      );
    }
  }

  @override
  void dispose() {
    _workflowController.dispose();
    _linkController.dispose();
    _mcpController.dispose();
    _skillController.dispose();
    _promptController.dispose();
    _metadataController
      ..removeListener(_onMetadataChanged)
      ..dispose();
    _importController
      ..removeListener(_onImportChanged)
      ..dispose();
    super.dispose();
  }

  MetadataController _createMetadataController(Directory root) {
    return MetadataController(
      repository: JsonMetadataRepository(vaultRoot: root),
    );
  }

  PromptController _createPromptController(Directory root) {
    return PromptController(
      repository: FilePromptRepository(vaultRoot: root),
      clipboard: const FlutterClipboardService(),
      vaultRootPath: root.path,
    );
  }

  SkillController _createSkillController(Directory root) {
    return SkillController(
      repository: FileSkillRepository(vaultRoot: root),
      systemOpen: MacosSystemOpenService(),
      vaultRootPath: root.path,
    );
  }

  McpController _createMcpController(Directory root) {
    return McpController(
      repository: FileMcpRepository(vaultRoot: root),
      clipboard: const FlutterClipboardService(),
      systemOpen: MacosSystemOpenService(),
      vaultRootPath: root.path,
    );
  }

  LinkController _createLinkController(Directory root) {
    return LinkController(
      repository: FileLinkRepository(vaultRoot: root),
      clipboard: const FlutterClipboardService(),
      systemOpen: MacosSystemOpenService(),
      vaultRootPath: root.path,
    );
  }

  WorkflowController _createWorkflowController(Directory root) {
    return WorkflowController(
      repository: FileWorkflowRepository(vaultRoot: root),
      layoutRepository: JsonWorkflowLayoutRepository(root: root),
      vaultRootPath: root.path,
    );
  }

  void _onImportChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onMetadataChanged() {
    if (!mounted) {
      return;
    }
    _cachedResources = null;
    _cachedResourcesKey = null;
    _shellKey.currentState?.applyFavoriteIds(_metadataController.favoriteIds);
    _shellKey.currentState?.applyRecentEntries(
      _metadataController.recentEntries,
    );
  }

  List<shell.WorkbenchResource> _resourcesForShell() {
    final favoriteIds = _metadataController.favoriteIds;
    final key = Object.hash(
      identityHashCode(widget.openState.resources),
      Object.hashAllUnordered(favoriteIds),
    );
    final cached = _cachedResources;
    if (cached != null && _cachedResourcesKey == key) {
      return cached;
    }
    final mapped = widget.openState.resources.map((record) {
      final resource = workbenchResourceFromRecord(record);
      return resource.copyWith(isFavorite: favoriteIds.contains(resource.id));
    }).toList(growable: false);
    _cachedResources = mapped;
    _cachedResourcesKey = key;
    return mapped;
  }

  Future<void> _loadMetadata() async {
    await _metadataController.load();
    if (!mounted) {
      return;
    }
    _shellKey.currentState?.applyFavoriteIds(_metadataController.favoriteIds);
    _shellKey.currentState?.applyRecentEntries(
      _metadataController.recentEntries,
    );
  }

  Future<void> _toggleFavorite(String resourceId) async {
    await _metadataController.toggleFavorite(resourceId);
  }

  Future<void> _openCreated(String relativePath, String message) async {
    await widget.vaultController.refreshPaths({relativePath});
    if (!mounted) {
      return;
    }
    setState(() => _bannerMessage = message);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        _shellKey.currentState?.openByRelativePath(relativePath) ??
            Future<void>.value(),
      );
    });
  }

  Future<void> _createPrompt() async {
    try {
      final created = await _promptController.create(
        title: '未命名提示词',
        body: '# 新提示词\n\n在此粘贴或编写内容。\n',
      );
      await _openCreated(created.relativePath, '已新建提示词，可修改标题并粘贴内容');
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _bannerMessage = '新建失败：$error');
    }
  }

  Future<void> _onResourceRenamed(String relativePath) async {
    await widget.vaultController.refreshPaths({relativePath});
    if (!mounted) {
      return;
    }
    setState(() => _bannerMessage = '已更新标题');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        _shellKey.currentState?.openByRelativePath(relativePath) ??
            Future<void>.value(),
      );
    });
  }

  Future<void> _duplicatePrompt(shell.WorkbenchResource resource) async {
    final relativePath = resource.relativePath;
    if (relativePath == null) {
      return;
    }
    try {
      await _promptController.open(relativePath);
      final duplicated = await _promptController.duplicate();
      await _openCreated(duplicated.relativePath, '已复制文件：${duplicated.title}');
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _bannerMessage = '复制失败：$error');
    }
  }

  Future<void> _importSkill() async {
    try {
      final selected = await defaultDirectoryPickerService().pickDirectory(
        dialogTitle: '选择 SKILL 文件夹',
        allowCreate: false,
      );
      if (selected == null) {
        return;
      }
      final imported = await _skillController.importDirectory(
        Directory(selected),
      );
      await _openCreated(
        imported.relativeDirectory,
        '已导入 SKILL：${imported.title}',
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _bannerMessage = '导入 SKILL 失败：$error');
    }
  }

  Future<void> _createMcp() async {
    try {
      final created = await _mcpController.create(
        title: '未命名 MCP',
        jsonText: '{\n  "mcpServers": {}\n}\n',
      );
      await _openCreated(created.relativePath, '已新建 MCP 配置');
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _bannerMessage = '新建 MCP 失败：$error');
    }
  }

  Future<void> _createLink() async {
    try {
      final created = await _linkController.create(
        title: '未命名链接',
        url: 'https://example.com',
      );
      await _openCreated(created.relativePath, '已新建网站链接，可修改地址');
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _bannerMessage = '新建链接失败：$error');
    }
  }

  Future<void> _pasteLink() async {
    try {
      final created = await _linkController.createFromClipboard();
      await _openCreated(created.relativePath, '已识别并保存链接：${created.uri}');
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _bannerMessage = '粘贴链接失败：$error');
    }
  }

  Future<void> _createWorkflow() async {
    try {
      final created = await _workflowController.create(title: '未命名流程');
      await _openCreated(created.relativePath, '已新建 Workflow，可编辑源码或切换画布');
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _bannerMessage = '新建 Workflow 失败：$error');
    }
  }

  Future<void> _importWorkflow() async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: '选择 Workflow 文件',
        type: FileType.custom,
        allowedExtensions: const ['mmd', 'md', 'yaml', 'yml', 'json'],
      );
      final path = result?.files.single.path;
      if (path == null) {
        return;
      }
      final imported = await _workflowController.importFile(path);
      await _openCreated(imported.relativePath, '已导入 Workflow：${imported.title}');
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _bannerMessage = '导入 Workflow 失败：$error');
    }
  }

  ResourceType? get _preferredVaultType {
    final type = _preferredShellType;
    if (type == null) {
      return null;
    }
    return switch (type) {
      shell.ResourceType.aiPrompt => ResourceType.prompt,
      shell.ResourceType.skillFolder => ResourceType.skill,
      shell.ResourceType.mcpConfiguration => ResourceType.mcp,
      shell.ResourceType.websiteLink => ResourceType.link,
      shell.ResourceType.workflowFile => ResourceType.workflow,
    };
  }

  Future<void> _onPathsDropped(List<String> paths) async {
    await _importController.prepare(paths, preferredType: _preferredVaultType);
    setState(() {
      _reviewOpen = true;
      _bannerMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final resources = _resourcesForShell();

    return VaultDropTarget(
      preferredType: _preferredVaultType,
      onPathsDropped: _onPathsDropped,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              if (_bannerMessage != null)
                ColoredBox(
                  color: MacosColors.controlAccentColor.withValues(alpha: 0.15),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(_bannerMessage!),
                  ),
                ),
              Expanded(
                child: WorkbenchShell(
                  key: _shellKey,
                  resources: resources,
                  vaultRootPath: widget.openState.handle.root.path,
                  onDestinationChanged: (type) {
                    _preferredShellType = type;
                  },
                  onToggleFavorite: _toggleFavorite,
                  metadataController: _metadataController,
                  promptController: _promptController,
                  skillController: _skillController,
                  mcpController: _mcpController,
                  linkController: _linkController,
                  workflowController: _workflowController,
                  onCreatePrompt: _createPrompt,
                  onDuplicatePrompt: _duplicatePrompt,
                  onImportSkill: _importSkill,
                  onCreateMcp: _createMcp,
                  onCreateLink: _createLink,
                  onPasteLink: _pasteLink,
                  onCreateWorkflow: _createWorkflow,
                  onImportWorkflow: _importWorkflow,
                  onRenamed: _onResourceRenamed,
                  restorationRepository: _restorationRepository,
                ),
              ),
            ],
          ),
          if (_reviewOpen)
            ImportReviewSheet(
              controller: _importController,
              vault: widget.openState.handle,
              onClose: () => setState(() => _reviewOpen = false),
            ),
        ],
      ),
    );
  }
}
