import 'package:ai_workbench/app/ai_workbench_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the no-vault welcome state', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AiWorkbenchApp()));
    await tester.pump(Duration.zero);

    expect(find.text('打开 AI 工作台'), findsOneWidget);
    expect(find.text('创建 Vault'), findsOneWidget);
    expect(find.text('打开 Vault'), findsOneWidget);
  });
}
