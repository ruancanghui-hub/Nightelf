import 'package:ai_workbench/app/theme/workbench_theme.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_shell.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

class AiWorkbenchApp extends ConsumerWidget {
  const AiWorkbenchApp({
    super.key,
    this.themeMode = ThemeMode.dark,
    this.hasVault = false,
  });

  final ThemeMode themeMode;
  final bool hasVault;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MacosApp(
      title: 'AI Workbench',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: WorkbenchTheme.light(),
      darkTheme: WorkbenchTheme.dark(),
      home: hasVault ? const WorkbenchShell() : const _NoVaultWelcome(),
    );
  }
}

class _NoVaultWelcome extends StatelessWidget {
  const _NoVaultWelcome();

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      children: [
        ContentArea(
          builder: (context, scrollController) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('打开 AI 工作台'),
                PushButton(
                  controlSize: ControlSize.large,
                  onPressed: null,
                  child: Text('创建 Vault'),
                ),
                PushButton(
                  controlSize: ControlSize.large,
                  onPressed: null,
                  child: Text('打开 Vault'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
