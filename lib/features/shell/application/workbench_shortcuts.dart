import 'package:ai_workbench/features/shell/application/workbench_intents.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Default keyboard bindings for the workbench shell.
Map<ShortcutActivator, Intent> workbenchShortcuts() {
  return const <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.keyK, meta: true):
        OpenCommandPaletteIntent(),
    SingleActivator(LogicalKeyboardKey.keyP, meta: true): QuickOpenIntent(),
    SingleActivator(LogicalKeyboardKey.keyS, meta: true): SaveDocumentIntent(),
    SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true):
        SyncVaultIntent(),
    SingleActivator(LogicalKeyboardKey.keyW, meta: true):
        CloseActiveTabIntent(),
    SingleActivator(LogicalKeyboardKey.keyB, meta: true): FocusSidebarIntent(),
    SingleActivator(LogicalKeyboardKey.keyE, meta: true): FocusContentIntent(),
    SingleActivator(LogicalKeyboardKey.keyI, meta: true):
        ToggleInspectorIntent(),
    SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
  };
}
