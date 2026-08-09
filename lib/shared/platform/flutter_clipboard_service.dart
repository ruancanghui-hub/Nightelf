import 'package:ai_workbench/shared/platform/clipboard_service.dart';
import 'package:flutter/services.dart';

class FlutterClipboardService implements ClipboardService {
  const FlutterClipboardService();

  @override
  Future<void> writeText(String text) {
    return Clipboard.setData(ClipboardData(text: text));
  }
}
