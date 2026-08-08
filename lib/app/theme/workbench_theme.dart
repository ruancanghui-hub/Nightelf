import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// Visual tokens shared by the app's Apple-inspired light and dark themes.
abstract final class WorkbenchTheme {
  static const Color _darkCanvas = Color(0xFF1C1C1E);
  static const Color _lightCanvas = Color(0xFFF5F5F7);
  static const Color _darkDivider = Color(0x33FFFFFF);
  static const Color _lightDivider = Color(0x1F000000);

  static MacosThemeData dark() {
    return MacosThemeData(
      brightness: Brightness.dark,
      accentColor: AccentColor.blue,
      canvasColor: _darkCanvas,
      dividerColor: _darkDivider,
    );
  }

  static MacosThemeData light() {
    return MacosThemeData(
      brightness: Brightness.light,
      accentColor: AccentColor.blue,
      canvasColor: _lightCanvas,
      dividerColor: _lightDivider,
    );
  }
}
