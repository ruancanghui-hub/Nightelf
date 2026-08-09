import 'package:ai_workbench/features/shell/presentation/workbench_sidebar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatRelativeOpenedAt covers common chinese buckets', () {
    final now = DateTime(2026, 8, 9, 18, 0);

    expect(formatRelativeOpenedAt(null, now: now), '最近');
    expect(
      formatRelativeOpenedAt(now.subtract(const Duration(seconds: 20)), now: now),
      '刚刚',
    );
    expect(
      formatRelativeOpenedAt(now.subtract(const Duration(minutes: 5)), now: now),
      '5 分钟前',
    );
    expect(
      formatRelativeOpenedAt(now.subtract(const Duration(hours: 2)), now: now),
      '2 小时前',
    );
    expect(
      formatRelativeOpenedAt(DateTime(2026, 8, 8, 10), now: now),
      '昨天',
    );
    expect(
      formatRelativeOpenedAt(DateTime(2026, 8, 6, 10), now: now),
      '3 天前',
    );
  });
}
