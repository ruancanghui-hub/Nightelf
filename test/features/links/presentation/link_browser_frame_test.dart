import 'package:ai_workbench/features/links/presentation/link_in_app_browser.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  Future<void> pumpFrame(
    WidgetTester tester, {
    Size size = const Size(820, 640),
    bool canGoBack = true,
    bool canGoForward = true,
    bool isLoading = false,
    String? error,
    VoidCallback? onBack,
    VoidCallback? onForward,
    VoidCallback? onReload,
    VoidCallback? onExternal,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MacosApp(
        theme: MacosThemeData.dark(),
        home: MacosWindow(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LinkBrowserFrame(
              url: 'https://mariuti.com/flutter-shadcn-ui/',
              canGoBack: canGoBack,
              canGoForward: canGoForward,
              isLoading: isLoading,
              error: error,
              onBack: onBack,
              onForward: onForward,
              onReload: onReload,
              onExternal: onExternal,
              child: const ColoredBox(
                key: ValueKey('fake-browser-content'),
                color: Color(0xFF111820),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('browser frame exposes address and working navigation actions', (
    tester,
  ) async {
    var backCount = 0;
    var forwardCount = 0;
    var reloadCount = 0;
    var externalCount = 0;

    await pumpFrame(
      tester,
      onBack: () => backCount += 1,
      onForward: () => forwardCount += 1,
      onReload: () => reloadCount += 1,
      onExternal: () => externalCount += 1,
    );

    expect(find.text('https://mariuti.com/flutter-shadcn-ui/'), findsOneWidget);
    expect(find.byKey(const ValueKey('fake-browser-content')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('link-browser-back')));
    await tester.tap(find.byKey(const ValueKey('link-browser-forward')));
    await tester.tap(find.byKey(const ValueKey('link-browser-refresh')));
    await tester.tap(find.byKey(const ValueKey('link-browser-external')));

    expect(backCount, 1);
    expect(forwardCount, 1);
    expect(reloadCount, 1);
    expect(externalCount, 1);
  });

  testWidgets('browser frame reports disabled history and load state', (
    tester,
  ) async {
    var backCount = 0;
    var forwardCount = 0;
    await pumpFrame(
      tester,
      canGoBack: false,
      canGoForward: false,
      isLoading: true,
      error: '无法加载：测试错误',
      onBack: () => backCount += 1,
      onForward: () => forwardCount += 1,
      onReload: () {},
      onExternal: () {},
    );

    await tester.tap(find.byKey(const ValueKey('link-browser-back')));
    await tester.tap(find.byKey(const ValueKey('link-browser-forward')));

    expect(backCount, 0);
    expect(forwardCount, 0);
    expect(find.text('加载中…'), findsOneWidget);
    expect(find.text('无法加载：测试错误'), findsOneWidget);
  });

  testWidgets('browser frame remains bounded at a narrow desktop width', (
    tester,
  ) async {
    await pumpFrame(
      tester,
      size: const Size(560, 520),
      onBack: () {},
      onForward: () {},
      onReload: () {},
      onExternal: () {},
    );

    expect(find.byKey(const ValueKey('link-browser-frame')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('browser frame can expose an editable address contract', (
    tester,
  ) async {
    final addressController = TextEditingController(
      text: 'https://mariuti.com/flutter-shadcn-ui/',
    );
    addTearDown(addressController.dispose);
    String? submitted;
    await tester.binding.setSurfaceSize(const Size(820, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MacosApp(
        theme: MacosThemeData.dark(),
        home: MacosWindow(
          child: LinkBrowserFrame(
            url: addressController.text,
            addressController: addressController,
            onAddressSubmitted: (value) => submitted = value,
            canGoBack: false,
            canGoForward: false,
            isLoading: false,
            error: null,
            onBack: null,
            onForward: null,
            onReload: () {},
            onExternal: () {},
            child: const ColoredBox(color: Color(0xFF111820)),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('link-browser-address')),
      'https://example.com/docs',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);

    expect(submitted, 'https://example.com/docs');
  });
}
