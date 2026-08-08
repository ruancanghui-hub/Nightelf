import 'package:ai_workbench/features/shell/application/workbench_controller.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_sidebar.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_toolbar.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// A dark/light Apple-style three-region shell backed only by mock records.
class WorkbenchShell extends StatefulWidget {
  const WorkbenchShell({super.key});

  @override
  State<WorkbenchShell> createState() => _WorkbenchShellState();
}

class _WorkbenchShellState extends State<WorkbenchShell> {
  late final WorkbenchController _controller = WorkbenchController()
    ..addListener(_refresh);

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      child: MacosScaffold(
        children: [
          ContentArea(
            builder: (context, scrollController) => Column(
              children: [
                const WorkbenchToolbar(),
                Expanded(
                  child: Row(
                    children: [
                      WorkbenchSidebar(
                        controller: _controller,
                        onDestinationSelected: _controller.selectDestination,
                      ),
                      _ResourceListPane(
                        controller: _controller,
                        onResourceSelected: _controller.selectResource,
                      ),
                      _InspectorPane(resource: _controller.selectedResource),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceListPane extends StatelessWidget {
  const _ResourceListPane({
    required this.controller,
    required this.onResourceSelected,
  });

  final WorkbenchController controller;
  final ValueChanged<WorkbenchResource> onResourceSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              controller.labelFor(controller.selectedDestination),
              style: MacosTheme.of(context).typography.title2,
            ),
            const SizedBox(height: 14),
            for (final resource in controller.selectedResources)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PushButton(
                  controlSize: ControlSize.large,
                  semanticLabel: '选择资源：${resource.title}',
                  onPressed: () => onResourceSelected(resource),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(resource.title),
                        const SizedBox(height: 2),
                        Text(
                          resource.subtitle,
                          style: MacosTheme.of(context).typography.caption1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InspectorPane extends StatelessWidget {
  const _InspectorPane({required this.resource});

  final WorkbenchResource resource;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: MacosTheme.of(context).dividerColor),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resource.title,
              style: MacosTheme.of(context).typography.largeTitle,
            ),
            const SizedBox(height: 12),
            Text(
              resource.subtitle,
              style: MacosTheme.of(context).typography.title3,
            ),
            const SizedBox(height: 32),
            Text(
              '此区域仅展示确定性的模拟资源。',
              style: MacosTheme.of(context).typography.body,
            ),
          ],
        ),
      ),
    );
  }
}
