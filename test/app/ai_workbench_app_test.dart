import 'dart:async';

import 'package:ai_workbench/app/ai_workbench_app.dart';
import 'package:ai_workbench/app/theme/workbench_theme.dart';
import 'package:ai_workbench/shared/platform/directory_picker_service.dart';
import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  testWidgets('renders the Nightelf application title', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AiWorkbenchApp(hasVault: true, skipRestore: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(
      tester.widget<MacosApp>(find.byType(MacosApp)).title,
      'Nightelf 工作台',
    );
    expect(find.text('Nightelf 工作台'), findsOneWidget);
  });

  testWidgets('uses the dark workbench theme by default', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AiWorkbenchApp(hasVault: true, skipRestore: true),
      ),
    );
    await tester.pump(Duration.zero);

    expect(
      tester.widget<AiWorkbenchApp>(find.byType(AiWorkbenchApp)).themeMode,
      ThemeMode.dark,
    );
  });

  testWidgets('uses the emerald welcome screen before a Vault is opened', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: AiWorkbenchApp(skipRestore: true)),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('开启你的 Nightelf 工作台'), findsOneWidget);
    final logo = tester.widget<Image>(
      find.byKey(const ValueKey('nightelf-welcome-logo')),
    );
    expect((logo.image as AssetImage).assetName, 'assets/nightelf-logo.png');
    expect(logo.width, 96);
    expect(logo.height, 96);
    expect(logo.fit, BoxFit.contain);
    expect(find.text('创建 Vault'), findsOneWidget);
    expect(find.text('打开 Vault'), findsOneWidget);
  });

  testWidgets('disables welcome actions while picking a directory', (
    tester,
  ) async {
    final picker = _HangingDirectoryPicker();
    await tester.pumpWidget(
      ProviderScope(
        child: AiWorkbenchApp(skipRestore: true, directoryPicker: picker),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    await tester.tap(find.text('打开 Vault'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('正在选择文件夹…'), findsOneWidget);
    final openButton = tester.widget<WorkbenchButton>(
      find.ancestor(
        of: find.text('打开 Vault'),
        matching: find.byType(WorkbenchButton),
      ),
    );
    expect(openButton.onPressed, isNull);
    expect(openButton.enabled, isFalse);

    picker.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('正在选择文件夹…'), findsNothing);
  });

  testWidgets('welcome open button accepts a mouse tap with slight movement', (
    tester,
  ) async {
    final picker = _HangingDirectoryPicker();
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: AiWorkbenchApp(skipRestore: true, directoryPicker: picker),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    final button = find.text('打开 Vault');
    final center = tester.getCenter(button);
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(2, 3));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('正在选择文件夹…'), findsOneWidget);
    picker.complete(null);
    await tester.pumpAndSettle();
  });

  testWidgets('shows the Nightelf splash for 900 ms before the app home', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: AiWorkbenchApp(skipRestore: true)),
    );

    expect(
      find.byKey(const ValueKey('nightelf-splash-screen')),
      findsOneWidget,
    );
    expect(find.text('创建 Vault'), findsNothing);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 899));
    expect(
      find.byKey(const ValueKey('nightelf-splash-screen')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nightelf-splash-screen')), findsNothing);
    expect(find.text('创建 Vault'), findsOneWidget);
  });

  testWidgets('can render with the light workbench theme', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AiWorkbenchApp(
          themeMode: ThemeMode.light,
          hasVault: true,
          skipRestore: true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('Nightelf 工作台'), findsOneWidget);
  });

  test('provides distinct dark and light macOS theme tokens', () {
    expect(WorkbenchTheme.dark().brightness, Brightness.dark);
    expect(WorkbenchTheme.dark().canvasColor, const Color(0xFF1C1C1E));
    expect(WorkbenchTheme.light().brightness, Brightness.light);
    expect(WorkbenchTheme.light().canvasColor, const Color(0xFFF5F5F7));
  });
}

class _HangingDirectoryPicker implements DirectoryPickerService {
  final Completer<PickedDirectory?> _completer = Completer<PickedDirectory?>();

  void complete(String? path) {
    if (!_completer.isCompleted) {
      _completer.complete(
        path == null ? null : PickedDirectory(path: path),
      );
    }
  }

  @override
  Future<PickedDirectory?> pickDirectory({
    String? dialogTitle,
    String? initialDirectory,
    bool allowCreate = true,
  }) {
    return _completer.future;
  }

  @override
  Future<PickedDirectory?> resolveBookmark(String bookmarkBase64) async => null;

  @override
  Future<String?> createBookmark(String path) async => null;

  @override
  Future<void> stopAccessing(String path) async {}
}
