import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Shows always-on-top desktop floating bubbles for quick external URL open.
abstract interface class FloatingBubbleService {
  Future<void> show({
    required String id,
    required String title,
    required String url,
  });

  Future<void> hide(String id);

  Future<void> hideAll();
}

class MethodChannelFloatingBubbleService implements FloatingBubbleService {
  MethodChannelFloatingBubbleService({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel('ai_workbench/floating_bubble');

  final MethodChannel _channel;

  @override
  Future<void> show({
    required String id,
    required String title,
    required String url,
  }) async {
    await _channel.invokeMethod<void>('show', {
      'id': id,
      'title': title,
      'url': url,
    });
  }

  @override
  Future<void> hide(String id) async {
    await _channel.invokeMethod<void>('hide', {'id': id});
  }

  @override
  Future<void> hideAll() async {
    await _channel.invokeMethod<void>('hideAll');
  }
}

class NoopFloatingBubbleService implements FloatingBubbleService {
  @override
  Future<void> show({
    required String id,
    required String title,
    required String url,
  }) async {}

  @override
  Future<void> hide(String id) async {}

  @override
  Future<void> hideAll() async {}
}

class RecordingFloatingBubbleService implements FloatingBubbleService {
  final List<({String id, String title, String url})> shown = [];
  final List<String> hidden = [];
  var hideAllCount = 0;

  @override
  Future<void> show({
    required String id,
    required String title,
    required String url,
  }) async {
    shown.removeWhere((item) => item.id == id);
    shown.add((id: id, title: title, url: url));
  }

  @override
  Future<void> hide(String id) async {
    hidden.add(id);
    shown.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> hideAll() async {
    hideAllCount += 1;
    shown.clear();
  }
}

FloatingBubbleService defaultFloatingBubbleService() {
  if (kIsWeb) {
    return NoopFloatingBubbleService();
  }
  return MethodChannelFloatingBubbleService();
}
