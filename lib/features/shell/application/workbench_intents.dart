import 'package:flutter/widgets.dart';

class OpenCommandPaletteIntent extends Intent {
  const OpenCommandPaletteIntent();
}

class QuickOpenIntent extends Intent {
  const QuickOpenIntent();
}

class SaveDocumentIntent extends Intent {
  const SaveDocumentIntent();
}

class SyncVaultIntent extends Intent {
  const SyncVaultIntent();
}

class CloseActiveTabIntent extends Intent {
  const CloseActiveTabIntent();
}

class FocusSidebarIntent extends Intent {
  const FocusSidebarIntent();
}

class FocusContentIntent extends Intent {
  const FocusContentIntent();
}

class ToggleInspectorIntent extends Intent {
  const ToggleInspectorIntent();
}
