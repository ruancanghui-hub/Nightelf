import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Nightelf emerald tokens shared by Shad wrappers.
abstract final class WorkbenchUiTokens {
  static const canvas = Color(0xFF030B09);
  static const panel = Color(0xE60A1916);
  static const border = Color(0xFF1B4D40);
  static const muted = Color(0xFF9BB4AB);
  static const emerald = Color(0xFF5DE7A7);
  static const foreground = Color(0xFFF2FFF8);
  static const searchFill = Color(0xFF07120F);
  static const chipFill = Color(0xFF0C211A);
}

/// Provides a global [ShadTheme] tuned for the Nightelf emerald palette.
class WorkbenchShadScope extends StatelessWidget {
  const WorkbenchShadScope({required this.child, super.key});

  final Widget child;

  static ShadThemeData darkTheme() {
    return ShadThemeData(
      brightness: Brightness.dark,
      colorScheme: const ShadGreenColorScheme.dark(
        background: WorkbenchUiTokens.canvas,
        foreground: WorkbenchUiTokens.foreground,
        primary: WorkbenchUiTokens.emerald,
        primaryForeground: WorkbenchUiTokens.canvas,
        secondary: Color(0xFF123F32),
        secondaryForeground: WorkbenchUiTokens.foreground,
        muted: Color(0xFF0C211A),
        mutedForeground: WorkbenchUiTokens.muted,
        accent: Color(0xFF0C2B23),
        accentForeground: WorkbenchUiTokens.foreground,
        destructive: Color(0xFFE35D6A),
        destructiveForeground: WorkbenchUiTokens.foreground,
        border: WorkbenchUiTokens.border,
        input: WorkbenchUiTokens.border,
        ring: WorkbenchUiTokens.emerald,
        card: WorkbenchUiTokens.panel,
        cardForeground: WorkbenchUiTokens.foreground,
        popover: WorkbenchUiTokens.panel,
        popoverForeground: WorkbenchUiTokens.foreground,
        selection: Color(0xFF355172),
      ),
      radius: BorderRadius.circular(10),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShadTheme(data: darkTheme(), child: child);
  }
}
