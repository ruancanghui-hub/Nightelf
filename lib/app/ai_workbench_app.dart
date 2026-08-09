import 'dart:io';

import 'package:ai_workbench/app/theme/workbench_theme.dart';
import 'package:ai_workbench/app/vault_providers.dart';
import 'package:ai_workbench/features/import/presentation/open_vault_workbench.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_shell.dart';
import 'package:ai_workbench/features/vault/application/vault_controller.dart';
import 'package:ai_workbench/features/vault/application/vault_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path/path.dart' as p;

class AiWorkbenchApp extends ConsumerStatefulWidget {
  const AiWorkbenchApp({
    super.key,
    this.themeMode = ThemeMode.dark,
    this.hasVault = false,
    this.skipRestore = false,
  });

  final ThemeMode themeMode;

  /// Test-only override: when true, show the shell without a live controller.
  final bool hasVault;
  final bool skipRestore;

  @override
  ConsumerState<AiWorkbenchApp> createState() => _AiWorkbenchAppState();
}

class _AiWorkbenchAppState extends ConsumerState<AiWorkbenchApp> {
  @override
  void initState() {
    super.initState();
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
      title: 'AI Workbench',
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
    final path = await FilePicker.getDirectoryPath(
      dialogTitle: '选择用于创建 Vault 的文件夹',
    );
    if (path == null) {
      return;
    }
    final root = Directory(path);
    final name = p.basename(root.path);
    await controller.createVault(root, name.isEmpty ? '我的资源库' : name);
  }

  Future<void> _openVault(VaultController controller) async {
    final path = await FilePicker.getDirectoryPath(
      dialogTitle: '选择要打开的 Vault 文件夹',
    );
    if (path == null) {
      return;
    }
    await controller.openVault(Directory(path));
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
          builder: (context, scrollController) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('打开 AI 工作台'),
                  const SizedBox(height: 8),
                  const Text('每个 Vault 文件夹是独立工作区，收藏与资源互不共享。'),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(errorMessage!),
                  ],
                  const SizedBox(height: 20),
                  PushButton(
                    controlSize: ControlSize.large,
                    onPressed: () {
                      onCreate();
                    },
                    child: const Text('创建 Vault'),
                  ),
                  const SizedBox(height: 12),
                  PushButton(
                    controlSize: ControlSize.large,
                    onPressed: () {
                      onOpen();
                    },
                    child: const Text('打开 Vault'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
