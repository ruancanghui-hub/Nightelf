import 'dart:collection';

import 'package:ai_workbench/features/shell/domain/workspace_tab.dart';
import 'package:flutter/foundation.dart';

/// Manages in-memory workspace tabs keyed by resource id.
class WorkspaceTabsController extends ChangeNotifier {
  final List<WorkspaceTab> _tabs = [];
  String? _activeResourceId;

  UnmodifiableListView<WorkspaceTab> get tabs => UnmodifiableListView(_tabs);

  String? get activeResourceId => _activeResourceId;

  void openTab(WorkspaceTab tab) {
    if (!_tabs.any((item) => item.resourceId == tab.resourceId)) {
      _tabs.add(tab);
    }
    _activeResourceId = tab.resourceId;
    notifyListeners();
  }

  void activateTab(String resourceId) {
    if (_activeResourceId == resourceId ||
        !_tabs.any((tab) => tab.resourceId == resourceId)) {
      return;
    }
    _activeResourceId = resourceId;
    notifyListeners();
  }

  void closeTab(String resourceId) {
    final index = _tabs.indexWhere((tab) => tab.resourceId == resourceId);
    if (index == -1) {
      return;
    }

    final wasActive = _activeResourceId == resourceId;
    _tabs.removeAt(index);
    if (wasActive) {
      if (_tabs.isEmpty) {
        _activeResourceId = null;
      } else {
        _activeResourceId = _tabs[index > 0 ? index - 1 : 0].resourceId;
      }
    }
    notifyListeners();
  }
}
