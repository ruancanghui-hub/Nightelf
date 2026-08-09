import 'package:ai_workbench/features/command_palette/domain/workbench_command.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:flutter/foundation.dart';

class CommandPaletteController extends ChangeNotifier {
  CommandPaletteController({
    List<WorkbenchCommand> commands = const [],
    List<WorkbenchResource> resources = const [],
  }) : _commands = List.unmodifiable(commands),
       _resources = List.unmodifiable(resources);

  List<WorkbenchCommand> _commands;
  List<WorkbenchResource> _resources;
  String _query = '';

  String get query => _query;
  List<WorkbenchCommand> get commands => _commands;
  List<WorkbenchResource> get resources => _resources;

  List<WorkbenchCommand> get visibleCommands {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return _commands;
    }
    return _commands
        .where((command) => command.label.toLowerCase().contains(normalized))
        .toList(growable: false);
  }

  List<WorkbenchResource> get visibleResources {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return _resources;
    }
    return _resources
        .where((resource) {
          return resource.title.toLowerCase().contains(normalized) ||
              resource.subtitle.toLowerCase().contains(normalized);
        })
        .toList(growable: false);
  }

  void updateQuery(String query) {
    if (_query == query) {
      return;
    }
    _query = query;
    notifyListeners();
  }

  void replaceCommands(List<WorkbenchCommand> commands) {
    _commands = List.unmodifiable(commands);
    notifyListeners();
  }

  void replaceResources(List<WorkbenchResource> resources) {
    _resources = List.unmodifiable(resources);
    notifyListeners();
  }
}
