import 'package:ai_workbench/app/theme/workbench_theme.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

class AiWorkbenchApp extends StatelessWidget {
  const AiWorkbenchApp({super.key, this.themeMode = ThemeMode.dark});

  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: 'AI Workbench',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: WorkbenchTheme.light(),
      darkTheme: WorkbenchTheme.dark(),
      home: const _WorkbenchWelcomePage(),
    );
  }
}

class _WorkbenchWelcomePage extends StatelessWidget {
  const _WorkbenchWelcomePage();

  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      child: MacosScaffold(
        children: [
          ContentArea(
            builder: (context, scrollController) =>
                const Center(child: Text('AI Workbench')),
          ),
        ],
      ),
    );
  }
}
