import 'dart:async';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/shell/presentation/emerald_interactive_surface.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_sidebar.dart';
import 'package:ai_workbench/app/vault_providers.dart';
import 'package:ai_workbench/features/sync/application/git_sync_service.dart';
import 'package:ai_workbench/features/vault/application/vault_state.dart';
import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The home surface shown before a resource is opened. It deliberately keeps
/// navigation and resource opening in the shell so the dashboard remains a
/// presentational view over the user's real Vault records.
class EmeraldOverviewDashboard extends StatelessWidget {
  const EmeraldOverviewDashboard({
    required this.resources,
    required this.recentResources,
    required this.recentOpenedAt,
    required this.labelFor,
    required this.onTypeSelected,
    required this.onResourceSelected,
    this.onSwitchVault,
    this.onFavoritesSelected,
    super.key,
  });

  final List<WorkbenchResource> resources;
  final List<WorkbenchResource> recentResources;
  final DateTime? Function(String resourceId) recentOpenedAt;
  final String Function(ResourceType type) labelFor;
  final ValueChanged<ResourceType> onTypeSelected;
  final ValueChanged<WorkbenchResource> onResourceSelected;
  final VoidCallback? onSwitchVault;
  final VoidCallback? onFavoritesSelected;

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
                  style: const TextStyle(
                    color: Color(0xFFE3F3EA),
                    fontSize: 14,
                  ),
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
              Text(
                formatRelativeOpenedAt(recentOpenedAt(resource.id)),
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
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
          if (onSwitchVault != null)
            Positioned(
              top: 12,
              right: 12,
              child: WorkbenchIconButton(
                icon: const Icon(LucideIcons.folders, color: _emerald),
                tooltip: '切换 Vault',
                semanticLabel: '切换 Vault',
                onPressed: onSwitchVault,
              ),
            ),
        ],
      ),
    ),
  );

  Widget _todayCard() {
    final stats = _TodayOverviewStats.from(
      resources: resources,
      recentResources: recentResources,
      recentOpenedAt: recentOpenedAt,
    );

    return _statusCard('今日概览', [
      _StatRow(
        LucideIcons.messageCircle,
        '今日更新',
        stats.updatedToday.toString(),
      ),
      _StatRow(LucideIcons.folderOpen, '今日打开', stats.openedToday.toString()),
      _StatRow(
        LucideIcons.star,
        '收藏资源',
        stats.favoriteCount.toString(),
        semanticLabel: '打开收藏夹列表',
        onTap: onFavoritesSelected,
      ),
      _StatRow(LucideIcons.library, '资源总数', stats.resourceCount.toString()),
    ], height: 249);
  }

  Widget _syncCard() => _statusCard('同步状态', [
    _StatRow(LucideIcons.cloud, 'Git 同步', '—'),
    const SizedBox(height: 8),
    _VaultSyncSection(),
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

class _TodayOverviewStats {
  const _TodayOverviewStats({
    required this.updatedToday,
    required this.openedToday,
    required this.favoriteCount,
    required this.resourceCount,
  });

  final int updatedToday;
  final int openedToday;
  final int favoriteCount;
  final int resourceCount;

  factory _TodayOverviewStats.from({
    required List<WorkbenchResource> resources,
    required List<WorkbenchResource> recentResources,
    required DateTime? Function(String resourceId) recentOpenedAt,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    return _TodayOverviewStats(
      updatedToday: resources
          .where((resource) => _isSameLocalDay(resource.modifiedAt, current))
          .length,
      openedToday: recentResources
          .where(
            (resource) => _isSameLocalDay(recentOpenedAt(resource.id), current),
          )
          .length,
      favoriteCount: resources.where((resource) => resource.isFavorite).length,
      resourceCount: resources.length,
    );
  }

  static bool _isSameLocalDay(DateTime? value, DateTime current) {
    if (value == null) {
      return false;
    }
    final local = value.toLocal();
    final today = current.toLocal();
    return local.year == today.year &&
        local.month == today.month &&
        local.day == today.day;
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(
    this.icon,
    this.label,
    this.value, {
    this.semanticLabel,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      key: ValueKey('stat-row-$label'),
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

    final action = onTap;
    if (action == null) {
      return row;
    }
    return Semantics(
      button: true,
      container: true,
      enabled: true,
      excludeSemantics: true,
      label: semanticLabel ?? label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: action,
          child: row,
        ),
      ),
    );
  }
}

class _VaultSyncSection extends ConsumerStatefulWidget {
  const _VaultSyncSection();

  @override
  ConsumerState<_VaultSyncSection> createState() => _VaultSyncSectionState();
}

class _VaultSyncSectionState extends ConsumerState<_VaultSyncSection> {
  bool _loading = true;
  bool _enabled = false;
  bool _autoPullEnabled = false;
  bool _autoPushEnabled = false;
  String? _remoteUrl;
  String? _message;
  bool _syncing = false;

  String? _vaultRootPath;

  Future<void> _load() async {
    try {
      final vaultState = ref.read(vaultControllerProvider).state;
      if (vaultState is! VaultOpen) {
        setState(() {
          _vaultRootPath = null;
          _loading = false;
          _enabled = false;
          _remoteUrl = null;
          _message = null;
        });
        return;
      }
      final rootPath = vaultState.handle.root.path;
      _vaultRootPath = rootPath;
      final settings = ref.read(appSettingsProvider);
      final enabled = await settings.readVaultSyncEnabled(rootPath);
      final remoteUrl = await settings.readVaultSyncRemoteUrl(rootPath);
      final autoPullEnabled = await settings.readVaultAutoPullEnabled(rootPath);
      final autoPushEnabled = await settings.readVaultAutoPushEnabled(rootPath);
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _enabled = enabled;
        _autoPullEnabled = autoPullEnabled;
        _autoPushEnabled = autoPushEnabled;
        _remoteUrl = remoteUrl;
        _message = null;
      });
    } on StateError catch (_) {
      // Many widget tests render the dashboard without a ProviderScope.
      // In that case, we gracefully degrade the sync section.
      if (!mounted) {
        return;
      }
      setState(() {
        _vaultRootPath = null;
        _loading = false;
        _enabled = false;
        _autoPullEnabled = false;
        _autoPushEnabled = false;
        _remoteUrl = null;
        _message = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _VaultSyncSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If vault root changed (switch vault), reload config.
    try {
      final vaultState = ref.read(vaultControllerProvider).state;
      final rootPath = vaultState is VaultOpen
          ? vaultState.handle.root.path
          : null;
      if (rootPath != _vaultRootPath) {
        _load();
      }
    } on StateError catch (_) {
      // No ProviderScope; nothing to reload.
    }
  }

  Future<void> _showEnableDialog() async {
    final controller = TextEditingController(text: _remoteUrl ?? '');
    String remoteUrlDraft = controller.text;
    var autoPullDraft = _autoPullEnabled;
    var autoPushDraft = _autoPushEnabled;
    await showMacosAlertDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return MacosAlertDialog(
              appIcon: const Icon(
                LucideIcons.refreshCw,
                color: Color(0xFF5DE7A7),
                size: 40,
              ),
              title: const Text('启用 Git 同步'),
              message: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '为当前 Vault 绑定一个远程仓库。之后你在两台电脑上都打开同一个 Vault 并启用同步，就可以沉淀到同一份数据。',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9BB4AB)),
                    ),
                    const SizedBox(height: 12),
                    MacosTextField(
                      controller: controller,
                      placeholder:
                          'https://github.com/.../repo.git 或 git@github.com:.../repo.git',
                      onChanged: (v) {
                        remoteUrlDraft = v;
                        setStateDialog(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    PushButton(
                      controlSize: ControlSize.large,
                      secondary: !autoPullDraft,
                      onPressed: () {
                        autoPullDraft = !autoPullDraft;
                        setStateDialog(() {});
                      },
                      child: Text(autoPullDraft ? '自动 pull：开启' : '自动 pull：关闭'),
                    ),
                    const SizedBox(height: 10),
                    PushButton(
                      controlSize: ControlSize.large,
                      secondary: !autoPushDraft,
                      onPressed: () {
                        autoPushDraft = !autoPushDraft;
                        setStateDialog(() {});
                      },
                      child: Text(autoPushDraft ? '自动 push：开启' : '自动 push：关闭'),
                    ),
                  ],
                ),
              ),
              primaryButton: PushButton(
                controlSize: ControlSize.large,
                onPressed: () async {
                  final rootPath = _vaultRootPath;
                  if (rootPath == null) {
                    Navigator.of(dialogContext).pop();
                    return;
                  }
                  final nav = Navigator.of(dialogContext);
                  final remote = remoteUrlDraft.trim();
                  await ref
                      .read(appSettingsProvider)
                      .writeVaultSyncConfig(
                        vaultRootPath: rootPath,
                        enabled: true,
                        remoteUrl: remote,
                      );
                  await ref
                      .read(appSettingsProvider)
                      .writeVaultAutoPullEnabled(
                        vaultRootPath: rootPath,
                        enabled: autoPullDraft,
                      );
                  await ref
                      .read(appSettingsProvider)
                      .writeVaultAutoPushEnabled(
                        vaultRootPath: rootPath,
                        enabled: autoPushDraft,
                      );
                  if (!mounted) {
                    return;
                  }
                  nav.pop();
                },
                child: const Text('启用并保存'),
              ),
              secondaryButton: PushButton(
                controlSize: ControlSize.large,
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('取消'),
              ),
            );
          },
        );
      },
    );
    await _load();
  }

  Future<void> _syncNow() async {
    final rootPath = _vaultRootPath;
    if (rootPath == null) {
      return;
    }
    final remoteUrl = _remoteUrl;
    if (remoteUrl == null || remoteUrl.trim().isEmpty) {
      setState(() => _message = '未配置 remote URL。');
      return;
    }
    setState(() {
      _syncing = true;
      _message = null;
    });

    final git = GitSyncService();
    final vaultController = ref.read(vaultControllerProvider);
    final result = await git.syncVault(
      vaultRootPath: rootPath,
      remoteUrl: remoteUrl,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _syncing = false;
      _message = switch (result.status) {
        GitSyncStatus.success => '同步完成。',
        GitSyncStatus.conflict =>
          '同步冲突：${result.conflictFiles.isEmpty ? '请查看终端' : '受影响文件：${result.conflictFiles.take(3).join(', ')}'}',
        GitSyncStatus.error => result.message ?? '同步失败。',
        GitSyncStatus.notGitRepo => 'Vault 尚未初始化为 Git 仓库。',
      };
    });

    if (result.status == GitSyncStatus.conflict) {
      await _showConflictDialog(
        vaultRootPath: rootPath,
        conflictFiles: result.conflictFiles,
      );
      return;
    }

    if (result.status == GitSyncStatus.success) {
      // Refresh indexes & recent cache.
      await vaultController.refreshPaths(const <String>{});
    }
    if (mounted) {
      // Clear banner after successful sync for a clean UX.
      if (result.status == GitSyncStatus.success) {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() => _message = null);
        }
      }
    }
  }

  Future<void> _showConflictDialog({
    required String vaultRootPath,
    required List<String> conflictFiles,
  }) async {
    final command = 'cd "$vaultRootPath" && git status';

    await showMacosAlertDialog<void>(
      context: context,
      builder: (dialogContext) {
        return MacosAlertDialog(
          appIcon: const Icon(
            LucideIcons.alertTriangle,
            color: Color(0xFFE3B341),
            size: 48,
          ),
          title: const Text('同步冲突'),
          message: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '请先在终端手动解决冲突后，再重试同步：',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9BB4AB)),
                ),
                const SizedBox(height: 10),
                if (conflictFiles.isNotEmpty) ...[
                  const Text(
                    '冲突文件（受影响）：',
                    style: TextStyle(fontSize: 12, color: Color(0xFFBDD0C7)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C211A),
                      border: Border.all(color: const Color(0xFF1B4D40)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    height: 96,
                    child: ListView.builder(
                      itemCount: conflictFiles.length > 8
                          ? 8
                          : conflictFiles.length,
                      itemBuilder: (context, index) {
                        return Text(
                          conflictFiles[index],
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFE1F1EA),
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const Text(
                  '建议终端命令：',
                  style: TextStyle(fontSize: 12, color: Color(0xFFBDD0C7)),
                ),
                const SizedBox(height: 6),
                Text(
                  command,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE3F3EA),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          primaryButton: PushButton(
            controlSize: ControlSize.large,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              unawaited(_syncNow());
            },
            child: const Text('重试同步'),
          ),
          secondaryButton: PushButton(
            controlSize: ControlSize.large,
            secondary: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('稍后再说'),
          ),
        );
      },
    );
  }

  Future<void> _disableSync() async {
    final rootPath = _vaultRootPath;
    if (rootPath == null) {
      return;
    }
    await ref
        .read(appSettingsProvider)
        .writeVaultSyncConfig(vaultRootPath: rootPath, enabled: false);
    await ref
        .read(appSettingsProvider)
        .writeVaultAutoPullEnabled(vaultRootPath: rootPath, enabled: false);
    await ref
        .read(appSettingsProvider)
        .writeVaultAutoPushEnabled(vaultRootPath: rootPath, enabled: false);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          '加载同步配置…',
          style: TextStyle(color: Color(0xFF9BB4AB), fontSize: 12),
        ),
      );
    }

    final enabled =
        _enabled && (_remoteUrl != null && _remoteUrl!.trim().isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_vaultRootPath == null)
          const Text(
            '未打开 Vault',
            style: TextStyle(color: Color(0xFF9BB4AB), fontSize: 12),
          )
        else if (!enabled)
          WorkbenchButton(
            size: WorkbenchButtonSize.sm,
            variant: WorkbenchButtonVariant.outline,
            semanticLabel: '启用 Git 同步',
            onPressed: _showEnableDialog,
            leading: const Icon(LucideIcons.refreshCw, size: 16),
            child: const Text('启用 Git 同步'),
          )
        else
          Row(
            children: [
              Expanded(
                child: WorkbenchButton(
                  size: WorkbenchButtonSize.sm,
                  variant: WorkbenchButtonVariant.primary,
                  semanticLabel: '立即同步',
                  onPressed: _syncing ? null : _syncNow,
                  leading: const Icon(LucideIcons.cloudUpload, size: 16),
                  child: Text(_syncing ? '同步中…' : '立即同步'),
                ),
              ),
              const SizedBox(width: 8),
              WorkbenchIconButton(
                tooltip: '断开 Git 同步',
                semanticLabel: '断开 Git 同步',
                icon: const Icon(LucideIcons.xCircle, size: 18),
                onPressed: _syncing ? null : _disableSync,
              ),
            ],
          ),
        if (_message != null) ...[
          const SizedBox(height: 10),
          Text(
            _message!,
            style: const TextStyle(color: Color(0xFFE3F3EA), fontSize: 12),
          ),
        ],
      ],
    );
  }
}
