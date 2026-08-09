import 'package:ai_workbench/features/import/application/import_controller.dart';
import 'package:ai_workbench/features/import/data/vault_import_repository.dart';
import 'package:ai_workbench/features/import/presentation/import_review_sheet.dart';
import 'package:ai_workbench/features/import/presentation/vault_drop_target.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart'
    as shell;
import 'package:ai_workbench/features/shell/domain/workbench_resource_mapper.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_shell.dart';
import 'package:ai_workbench/features/vault/application/vault_controller.dart';
import 'package:ai_workbench/features/vault/application/vault_state.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
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
  bool _reviewOpen = false;
  String? _bannerMessage;
  shell.ResourceType? _preferredShellType;

  @override
  void initState() {
    super.initState();
    _importController = ImportController(
      repository: VaultImportRepository(),
      onImported: (paths) => widget.vaultController.refreshPaths(paths),
    )..addListener(_onImportChanged);
  }

  @override
  void dispose() {
    _importController
      ..removeListener(_onImportChanged)
      ..dispose();
    super.dispose();
  }

  void _onImportChanged() {
    if (mounted) {
      setState(() {});
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
    final resources = widget.openState.resources
        .map(workbenchResourceFromRecord)
        .toList();

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
                  resources: resources,
                  onDestinationChanged: (type) {
                    setState(() => _preferredShellType = type);
                  },
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
