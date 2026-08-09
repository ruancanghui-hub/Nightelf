import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// A browser-shaped visual frame that never navigates or accesses a network.
class WebsiteWorkspace extends StatelessWidget {
  const WebsiteWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 430,
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MacosTheme.of(context).dividerColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const _WindowDot(color: Color(0xFFFF5F57)),
                const _WindowDot(color: Color(0xFFFFBD2E)),
                const _WindowDot(color: Color(0xFF28C840)),
                const SizedBox(width: 4),
                Text('‹  ›  ↻', style: MacosTheme.of(context).typography.body),
                Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x16000000),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: MacosTheme.of(context).dividerColor,
                    ),
                  ),
                  child: const Text('https://developer.apple.com/design/'),
                ),
              ],
            ),
          ),
          Container(height: 1, color: MacosTheme.of(context).dividerColor),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(28),
              color: const Color(0x0CFFFFFF),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '内部浏览器 · 静态预览',
                    textAlign: TextAlign.center,
                    style: MacosTheme.of(context).typography.title1,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '不会发起网络请求',
                    style: MacosTheme.of(context).typography.headline,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: MacosTheme.of(context).dividerColor,
                      ),
                    ),
                    child: const Text('此页面不可导航'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowDot extends StatelessWidget {
  const _WindowDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
