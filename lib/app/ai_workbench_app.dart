import 'dart:async';
import 'dart:io';
import 'dart:ui' show PointerDeviceKind;

import 'package:ai_workbench/app/theme/workbench_theme.dart';
import 'package:ai_workbench/app/nightelf_splash_screen.dart';
import 'package:ai_workbench/app/vault_providers.dart';
import 'package:ai_workbench/features/import/presentation/open_vault_workbench.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_shell.dart';
import 'package:ai_workbench/features/vault/application/vault_controller.dart';
import 'package:ai_workbench/features/vault/application/vault_state.dart';
import 'package:ai_workbench/shared/platform/directory_picker_service.dart';
import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart';
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
  var _vaultBusy = false;
  var _showSplash = true;
  var _restorePending = false;

  @override
  void initState() {
    super.initState();
    _directoryPicker =
        widget.directoryPicker ?? defaultDirectoryPickerService();
    if (!widget.hasVault && !widget.skipRestore) {
      _restorePending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_restoreLastVault());
      });
    }
  }

  Future<void> _restoreLastVault() async {
    try {
      await ref.read(vaultControllerProvider).restoreLastVault();
    } finally {
      if (mounted) {
        setState(() => _restorePending = false);
      } else {
        _restorePending = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(vaultControllerProvider);

    return MacosApp(
      title: 'Nightelf 工作台',
      debugShowCheckedModeBanner: false,
      themeMode: widget.themeMode,
      theme: WorkbenchTheme.light(),
      darkTheme: WorkbenchTheme.dark(),
      home: WorkbenchShadScope(
        child: _showSplash
            ? NightelfSplashScreen(
                onFinished: () {
                  if (mounted) {
                    setState(() => _showSplash = false);
                  }
                },
              )
            : widget.hasVault
            ? const WorkbenchShell()
            : ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final state = controller.state;
                  if (_restorePending && state is VaultClosed) {
                    return const _StatusScaffold(message: '正在打开 Vault…');
                  }
                  return _homeForState(controller, state);
                },
              ),
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
        busy: _vaultBusy,
        errorMessage: message,
        onCreate: () => _createVault(controller),
        onOpen: () => _openVault(controller),
      ),
      VaultClosed() => _WelcomeScaffold(
        busy: _vaultBusy,
        onCreate: () => _createVault(controller),
        onOpen: () => _openVault(controller),
      ),
    };
  }

  Future<void> _createVault(VaultController controller) async {
    if (_vaultBusy) {
      return;
    }
    // Finish the button tap before disabling controls / opening a native panel.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted || _vaultBusy) {
      return;
    }
    setState(() => _vaultBusy = true);
    try {
      final picked = await _pickDirectory(
        dialogTitle: '选择用于创建 Vault 的文件夹（将直接作为资源库根目录）',
        allowCreate: true,
      );
      if (picked == null) {
        return;
      }
      final root = Directory(picked.path);
      final name = p.basename(root.path);
      await controller.createVault(
        root,
        name.isEmpty ? '我的资源库' : name,
        bookmarkBase64: picked.bookmarkBase64,
      );
    } finally {
      if (mounted) {
        setState(() => _vaultBusy = false);
      } else {
        _vaultBusy = false;
      }
    }
  }

  Future<void> _openVault(VaultController controller) async {
    if (_vaultBusy) {
      return;
    }
    // Finish the button tap before disabling controls / opening a native panel.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted || _vaultBusy) {
      return;
    }
    setState(() => _vaultBusy = true);
    try {
      final picked = await _pickDirectory(
        dialogTitle: '选择要打开的 Vault 文件夹（含 .ai-vault.json 的根目录）',
        allowCreate: false,
      );
      if (picked == null) {
        return;
      }
      final root = await _resolveVaultRoot(Directory(picked.path));
      var bookmark = picked.bookmarkBase64;
      if (root.path != picked.path) {
        try {
          bookmark =
              await _directoryPicker.createBookmark(root.path) ?? bookmark;
        } catch (_) {
          // Keep the picked bookmark if parent bookmark creation fails.
        }
      }
      await controller.openVault(root, bookmarkBase64: bookmark);
    } finally {
      if (mounted) {
        setState(() => _vaultBusy = false);
      } else {
        _vaultBusy = false;
      }
    }
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

  Future<PickedDirectory?> _pickDirectory({
    required String dialogTitle,
    required bool allowCreate,
  }) async {
    if (!mounted) {
      return null;
    }
    try {
      return await _directoryPicker.pickDirectory(
        dialogTitle: dialogTitle,
        allowCreate: allowCreate,
      );
    } on MissingPluginException {
      // Hot restart can drop native channels; fall back to file_picker.
      final path = await FilePicker.getDirectoryPath(dialogTitle: dialogTitle);
      if (path == null || path.trim().isEmpty) {
        return null;
      }
      return PickedDirectory(path: path);
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
    this.busy = false,
    this.errorMessage,
  });

  final Future<void> Function() onCreate;
  final Future<void> Function() onOpen;
  final bool busy;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      children: [
        ContentArea(
          builder: (context, scrollController) => ColoredBox(
            color: const Color(0xFF030B09),
            // Full-height scrollables steal desktop mouse drags from buttons.
            // Keep the card centered, scroll only when content overflows, and
            // never treat mouse movement as a scroll drag on this page.
            child: ScrollConfiguration(
              behavior: const _WelcomeScrollBehavior(),
              child: CustomScrollView(
                controller: scrollController,
                primary: false,
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 510),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(36, 40, 36, 40),
                            decoration: BoxDecoration(
                              color: const Color(0xE60A1916),
                              border: Border.all(
                                color: const Color(0xFF1B4D40),
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x405DE7A7),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/nightelf-logo.png',
                                  key: const ValueKey('nightelf-welcome-logo'),
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.contain,
                                  semanticLabel: 'Nightelf Logo',
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  '开启你的 Nightelf 工作台',
                                  textAlign: TextAlign.center,
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
                                  style: TextStyle(
                                    color: Color(0xFF9BB4AB),
                                    height: 1.55,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  '打开时请选择含 .ai-vault.json 的 Vault 根目录。',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF6F9184),
                                    fontSize: 12,
                                  ),
                                ),
                                if (errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFFFA6A6),
                                    ),
                                  ),
                                ],
                                if (busy) ...[
                                  const SizedBox(height: 16),
                                  const Text(
                                    '正在选择文件夹…',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF5DE7A7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 28),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: WorkbenchButton(
                                    size: WorkbenchButtonSize.lg,
                                    expands: true,
                                    enabled: !busy,
                                    onPressed: busy ? null : () => onCreate(),
                                    child: const Text('创建 Vault'),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: WorkbenchButton(
                                    size: WorkbenchButtonSize.lg,
                                    variant: WorkbenchButtonVariant.outline,
                                    expands: true,
                                    enabled: !busy,
                                    onPressed: busy ? null : () => onOpen(),
                                    child: const Text('打开 Vault'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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

/// Welcome page should not treat mouse movement as scrolling, or button taps
/// feel unreliable on large desktop windows.
class _WelcomeScrollBehavior extends ScrollBehavior {
  const _WelcomeScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}
