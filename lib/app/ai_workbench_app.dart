import 'dart:io';

import 'package:ai_workbench/app/theme/workbench_theme.dart';
import 'package:ai_workbench/app/vault_providers.dart';
import 'package:ai_workbench/features/import/presentation/open_vault_workbench.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_shell.dart';
import 'package:ai_workbench/features/vault/application/vault_controller.dart';
import 'package:ai_workbench/features/vault/application/vault_state.dart';
import 'package:ai_workbench/shared/platform/directory_picker_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path/path.dart' as p;

class AiWorkbenchApp extends ConsumerStatefulWidget {
  const AiWorkbenchApp({
    super.key,
    this.themeMode = ThemeMode.dark,
    this.hasVault = false,
    this.skipRestore = false,
    this.directoryPicker,
  });

  final ThemeMode themeMode;

  /// Test-only override: when true, show the shell without a live controller.
  final bool hasVault;
  final bool skipRestore;
  final DirectoryPickerService? directoryPicker;

  @override
  ConsumerState<AiWorkbenchApp> createState() => _AiWorkbenchAppState();
}

class _AiWorkbenchAppState extends ConsumerState<AiWorkbenchApp> {
  late final DirectoryPickerService _directoryPicker;
  var _pickingDirectory = false;

  @override
  void initState() {
    super.initState();
    _directoryPicker =
        widget.directoryPicker ?? defaultDirectoryPickerService();
    if (!widget.hasVault && !widget.skipRestore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(vaultControllerProvider).restoreLastVault();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(vaultControllerProvider);

    return MacosApp(
      title: 'Nightelf · AI 工作台',
      debugShowCheckedModeBanner: false,
      themeMode: widget.themeMode,
      theme: WorkbenchTheme.light(),
      darkTheme: WorkbenchTheme.dark(),
      home: widget.hasVault
          ? const WorkbenchShell()
          : ListenableBuilder(
              listenable: controller,
              builder: (context, _) =>
                  _homeForState(controller, controller.state),
            ),
    );
  }

  Widget _homeForState(VaultController controller, VaultState state) {
    return switch (state) {
      VaultOpen() => OpenVaultWorkbench(
        vaultController: controller,
        openState: state,
      ),
      VaultOpening() => const _StatusScaffold(message: '正在打开 Vault…'),
      VaultFailure(:final message) => _WelcomeScaffold(
        errorMessage: message,
        onCreate: () => _createVault(controller),
        onOpen: () => _openVault(controller),
      ),
      VaultClosed() => _WelcomeScaffold(
        onCreate: () => _createVault(controller),
        onOpen: () => _openVault(controller),
      ),
    };
  }

  Future<void> _createVault(VaultController controller) async {
    final path = await _pickDirectory(
      dialogTitle: '选择用于创建 Vault 的文件夹（将直接作为资源库根目录）',
      allowCreate: true,
    );
    if (path == null) {
      return;
    }
    final root = Directory(path);
    final name = p.basename(root.path);
    await controller.createVault(root, name.isEmpty ? '我的资源库' : name);
  }

  Future<void> _openVault(VaultController controller) async {
    final path = await _pickDirectory(
      dialogTitle: '选择要打开的 Vault 文件夹（含 .ai-vault.json 的根目录）',
      allowCreate: false,
    );
    if (path == null) {
      return;
    }
    final root = await _resolveVaultRoot(Directory(path));
    await controller.openVault(root);
  }

  /// If the user picked a typed subfolder (e.g. workflows/), open the parent Vault.
  Future<Directory> _resolveVaultRoot(Directory selected) async {
    final marker = File(p.join(selected.path, '.ai-vault.json'));
    if (await marker.exists()) {
      return selected;
    }
    const typed = {'prompts', 'skills', 'mcp', 'links', 'workflows', 'assets'};
    final base = p.basename(selected.path);
    if (!typed.contains(base)) {
      return selected;
    }
    final parent = selected.parent;
    final parentMarker = File(p.join(parent.path, '.ai-vault.json'));
    if (await parentMarker.exists()) {
      return parent;
    }
    return selected;
  }

  Future<String?> _pickDirectory({
    required String dialogTitle,
    required bool allowCreate,
  }) async {
    if (_pickingDirectory) {
      return null;
    }
    // Avoid setState during the PushButton tap gesture (macos_ui crashes).
    _pickingDirectory = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) {
        return null;
      }
      return _directoryPicker.pickDirectory(
        dialogTitle: dialogTitle,
        allowCreate: allowCreate,
      );
    } on MissingPluginException {
      // Hot restart can drop native channels; fall back to file_picker.
      return FilePicker.getDirectoryPath(dialogTitle: dialogTitle);
    } finally {
      _pickingDirectory = false;
    }
  }
}

class _StatusScaffold extends StatelessWidget {
  const _StatusScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      children: [
        ContentArea(
          builder: (context, scrollController) => Center(child: Text(message)),
        ),
      ],
    );
  }
}

class _WelcomeScaffold extends StatelessWidget {
  const _WelcomeScaffold({
    required this.onCreate,
    required this.onOpen,
    this.errorMessage,
  });

  final Future<void> Function() onCreate;
  final Future<void> Function() onOpen;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      children: [
        ContentArea(
          builder: (context, scrollController) => Container(
            color: const Color(0xFF030B09),
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 510),
              child: Container(
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: const Color(0xE60A1916),
                  border: Border.all(color: const Color(0xFF1B4D40)),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x405DE7A7), blurRadius: 24),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.leafyGreen,
                      color: Color(0xFF5DE7A7),
                      size: 48,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '开启你的绿光工作台',
                      style: TextStyle(
                        color: Color(0xFFF2FFF8),
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '把 AI 提示词、SKILL、MCP 配置、网站链接与工作流收进一个可同步的本地 Vault。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9BB4AB), height: 1.55),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '打开时请选择含 .ai-vault.json 的 Vault 根目录。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF6F9184), fontSize: 12),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFFFA6A6)),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: PushButton(
                        controlSize: ControlSize.large,
                        onPressed: onCreate,
                        child: const Text('创建 Vault'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: PushButton(
                        controlSize: ControlSize.large,
                        secondary: true,
                        onPressed: onOpen,
                        child: const Text('打开 Vault'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
