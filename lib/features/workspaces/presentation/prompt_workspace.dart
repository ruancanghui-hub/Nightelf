import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// Editable-looking prompt source with no editor or persistence behavior.
class PromptWorkspace extends StatelessWidget {
  const PromptWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 380),
      decoration: _surfaceDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SurfaceHeader(title: '提示词源码', trailing: '模拟可编辑外观'),
          Padding(
            padding: const EdgeInsets.all(22),
            child: DefaultTextStyle(
              style: MacosTheme.of(
                context,
              ).typography.body.copyWith(height: 1.7, fontFamily: 'Menlo'),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('# 发布说明助手'),
                  SizedBox(height: 14),
                  Text('你是一位产品发布说明编辑。'),
                  SizedBox(height: 10),
                  Text('请将输入的变更整理为：'),
                  SizedBox(height: 8),
                  Text('1. 摘要\n2. 用户可见变化\n3. 升级提示'),
                  SizedBox(height: 18),
                  Text('{{changes}}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _surfaceDecoration(BuildContext context) => BoxDecoration(
  color: MacosTheme.of(context).canvasColor,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: MacosTheme.of(context).dividerColor),
  boxShadow: const [
    BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 12)),
  ],
);

class _SurfaceHeader extends StatelessWidget {
  const _SurfaceHeader({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MacosTheme.of(context).dividerColor),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text(title, style: MacosTheme.of(context).typography.headline),
          Text(trailing, style: MacosTheme.of(context).typography.caption1),
        ],
      ),
    );
  }
}
