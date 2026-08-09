import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// Editable-looking SKILL source preview with no editing or persistence.
class SkillWorkspace extends StatelessWidget {
  const SkillWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 410),
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final directory = const _DirectoryPreview();
          final source = const _SkillSource();
          if (!constraints.hasBoundedHeight || constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [directory, const SizedBox(height: 14), source],
            );
          }
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 180, child: _DirectoryPreview()),
              SizedBox(width: 14),
              Expanded(child: _SkillSource()),
            ],
          );
        },
      ),
    );
  }
}

class _DirectoryPreview extends StatelessWidget {
  const _DirectoryPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _innerDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('目录预览', style: MacosTheme.of(context).typography.headline),
          const SizedBox(height: 14),
          const Text('▾ product-copy/'),
          const SizedBox(height: 10),
          const Text('   SKILL.md'),
          const SizedBox(height: 8),
          const Text('   references/'),
          const SizedBox(height: 8),
          const Text('   examples.md'),
        ],
      ),
    );
  }
}

class _SkillSource extends StatelessWidget {
  const _SkillSource();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _innerDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'SKILL.md',
                style: MacosTheme.of(context).typography.headline,
              ),
              Text(
                '模拟可编辑外观',
                style: MacosTheme.of(context).typography.caption1,
              ),
            ],
          ),
          const SizedBox(height: 18),
          DefaultTextStyle(
            style: MacosTheme.of(
              context,
            ).typography.body.copyWith(height: 1.65, fontFamily: 'Menlo'),
            child: const Text(
              '---\nname: product-copy\n'
              'description: 为产品界面撰写简洁文案\n---\n\n'
              '# 产品文案\n\n使用清晰、简短且可执行的表达。',
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _panelDecoration(BuildContext context) => BoxDecoration(
  color: MacosTheme.of(context).canvasColor,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: MacosTheme.of(context).dividerColor),
  boxShadow: const [
    BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 12)),
  ],
);

BoxDecoration _innerDecoration(BuildContext context) => BoxDecoration(
  color: const Color(0x12000000),
  borderRadius: BorderRadius.circular(9),
  border: Border.all(color: MacosTheme.of(context).dividerColor),
);
