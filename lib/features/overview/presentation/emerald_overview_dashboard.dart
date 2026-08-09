import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/shell/presentation/emerald_interactive_surface.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The home surface shown before a resource is opened. It deliberately keeps
/// navigation and resource opening in the shell so the dashboard remains a
/// presentational view over the user's real Vault records.
class EmeraldOverviewDashboard extends StatelessWidget {
  const EmeraldOverviewDashboard({
    required this.resources,
    required this.recentResources,
    required this.labelFor,
    required this.onTypeSelected,
    required this.onResourceSelected,
    super.key,
  });

  final List<WorkbenchResource> resources;
  final List<WorkbenchResource> recentResources;
  final String Function(ResourceType type) labelFor;
  final ValueChanged<ResourceType> onTypeSelected;
  final ValueChanged<WorkbenchResource> onResourceSelected;

  static const _canvas = Color(0xFF030B09);
  static const _panel = Color(0xE60A1916);
  static const _border = Color(0xFF1B4D40);
  static const _muted = Color(0xFF9BB4AB);
  static const _emerald = Color(0xFF5DE7A7);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _canvas,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 860;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 58,
              ),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _mainColumn(),
                        const SizedBox(height: 20),
                        _statusColumn(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _mainColumn()),
                        const SizedBox(width: 26),
                        SizedBox(
                          width: (constraints.maxWidth * 0.26)
                              .clamp(304, 348)
                              .toDouble(),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: _statusColumn(),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _mainColumn() => Padding(
    padding: const EdgeInsets.only(top: 29),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 27),
          child: Text(
            '今晚想整理什么？',
            style: TextStyle(
              color: Color(0xFFF2FFF8),
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.only(left: 27),
          child: Text(
            '集中管理你的 AI 资源，让灵感与效率回航。',
            style: TextStyle(color: _muted, fontSize: 15),
          ),
        ),
        const SizedBox(height: 46),
        _recentPanel(),
        const SizedBox(height: 24),
        _dropZone(),
      ],
    ),
  );

  Widget _recentPanel() => Container(
    padding: const EdgeInsets.fromLTRB(18, 17, 18, 12),
    decoration: BoxDecoration(
      color: _panel,
      border: Border.all(color: _border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Text(
              '最近使用的资源',
              style: TextStyle(
                color: Color(0xFFF2FFF8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            Text('查看全部  ›', style: TextStyle(color: _muted, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterChip('全部', selected: true, onTap: () {}),
            for (final type in ResourceType.values)
              _filterChip(labelFor(type), onTap: () => onTypeSelected(type)),
          ],
        ),
        const SizedBox(height: 12),
        for (final resource in recentResources.take(8)) _resourceRow(resource),
      ],
    ),
  );

  Widget _filterChip(
    String label, {
    required VoidCallback onTap,
    bool selected = false,
  }) => Semantics(
    button: true,
    label: '筛选：$label',
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF123F32) : const Color(0xFF081410),
            border: Border.all(
              color: selected ? _emerald : const Color(0xFF16352B),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: TextStyle(color: selected ? _emerald : _muted, fontSize: 12),
          ),
        ),
      ),
    ),
  );

  Widget _resourceRow(WorkbenchResource resource) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Semantics(
      button: true,
      label: '打开 ${resource.title}',
      child: EmeraldInteractiveSurface(
        onTap: () => onResourceSelected(resource),
        borderRadius: BorderRadius.circular(8),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        height: 48,
        showSelectedBorder: false,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF123127))),
          ),
          child: Row(
            children: [
              Icon(_iconFor(resource.type), color: _emerald, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  resource.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFE3F3EA), fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B211A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  labelFor(resource.type),
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ),
              const SizedBox(width: 16),
              const Text('刚刚', style: TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(width: 10),
              const Icon(LucideIcons.ellipsis, color: _muted, size: 17),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _dropZone() => Container(
    width: double.infinity,
    height: 140,
    decoration: BoxDecoration(
      color: const Color(0xFF061611),
      border: Border.all(color: _emerald, width: 1.4),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(color: Color(0x605DE7A7), blurRadius: 18)],
    ),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.cloudUpload, color: _emerald, size: 34),
        SizedBox(height: 10),
        Text(
          '拖入文件到工作台',
          style: TextStyle(
            color: Color(0xFFF2FFF8),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 7),
        Text(
          '支持导入提示词文件、文件夹、MCP 配置、链接列表、Workflow 文件等',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _statusColumn() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _vaultAlert(),
      const SizedBox(height: 18),
      _todayCard(),
      const SizedBox(height: 18),
      _syncCard(),
    ],
  );

  Widget _vaultAlert() => SizedBox(
    height: 241,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/vault-status-forest.png',
            fit: BoxFit.cover,
            alignment: Alignment.bottomRight,
            color: const Color(0xAA0A241C),
            colorBlendMode: BlendMode.multiply,
          ),
          const ColoredBox(color: Color(0x94030B09)),
          ShadAlert(
            icon: const Icon(
              LucideIcons.shieldCheck,
              color: _emerald,
              size: 29,
            ),
            title: const Text('Vault 已就绪'),
            description: const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('你的 AI 资源库运行正常，所有分类与索引已同步完成。\n\n查看状态详情  ›'),
            ),
            decoration: ShadDecoration(
              color: const Color(0x00000000),
              border: const ShadBorder.fromBorderSide(
                ShadBorderSide(color: _border),
                radius: BorderRadius.all(Radius.circular(16)),
                padding: EdgeInsets.all(20),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _todayCard() => _statusCard('今日概览', const [
    _StatRow(LucideIcons.messageCircle, '新增资源', '12'),
    _StatRow(LucideIcons.folderOpen, '打开资源', '28'),
    _StatRow(LucideIcons.star, '收藏资源', '7'),
    _StatRow(LucideIcons.clock3, '节省时间', '2.6 小时'),
  ], height: 249);

  Widget _syncCard() => _statusCard('同步状态', const [
    _StatRow(LucideIcons.cloud, '所有数据已同步', '✓'),
    SizedBox(height: 8),
    _SyncButton(),
  ], height: 214);

  Widget _statusCard(
    String title,
    List<Widget> children, {
    required double height,
  }) => SizedBox(
    height: height,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF2FFF8),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    ),
  );

  static IconData _iconFor(ResourceType type) => switch (type) {
    ResourceType.aiPrompt => LucideIcons.messageCircle,
    ResourceType.skillFolder => LucideIcons.folder,
    ResourceType.mcpConfiguration => LucideIcons.slidersHorizontal,
    ResourceType.websiteLink => LucideIcons.globe,
    ResourceType.workflowFile => LucideIcons.workflow,
  };
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF9BB4AB), size: 17),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFFBDD0C7), fontSize: 13),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFF2FFF8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _SyncButton extends StatelessWidget {
  const _SyncButton();
  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFF1B4D40)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.refreshCw, color: Color(0xFFBDD0C7), size: 16),
        SizedBox(width: 8),
        Text('立即同步', style: TextStyle(color: Color(0xFFE3F3EA), fontSize: 13)),
      ],
    ),
  );
}
