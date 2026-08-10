import 'dart:async';
import 'dart:io';

import 'package:ai_workbench/features/links/data/link_repository.dart';
import 'package:ai_workbench/features/links/domain/link_document.dart';
import 'package:ai_workbench/features/links/domain/link_validation.dart';
import 'package:ai_workbench/shared/platform/clipboard_service.dart';
import 'package:ai_workbench/shared/platform/floating_bubble_service.dart';
import 'package:ai_workbench/shared/platform/system_open_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class LinkController extends ChangeNotifier {
  LinkController({
    required LinkRepository repository,
    required ClipboardService clipboard,
    required SystemOpenService systemOpen,
    required String vaultRootPath,
    FloatingBubbleService? floatingBubbles,
    LinkValidation? validation,
  }) : _repository = repository,
       _clipboard = clipboard,
       _systemOpen = systemOpen,
       _vaultRootPath = vaultRootPath,
       _floatingBubbles = floatingBubbles ?? defaultFloatingBubbleService(),
       _validation = validation ?? const LinkValidation() {
    _floatingBubbles.onDismissed = _handleBubbleDismissed;
  }

  final LinkRepository _repository;
  final ClipboardService _clipboard;
  final SystemOpenService _systemOpen;
  final String _vaultRootPath;
  final FloatingBubbleService _floatingBubbles;
  final LinkValidation _validation;

  LinkDocument? _document;
  String? _draftUrl;
  String? _draftNotes;
  String? _lastTrashPath;
  String? _statusMessage;
  String? _errorMessage;

  LinkDocument? get document => _document;
  String get draftUrl => _draftUrl ?? _document?.uri.toString() ?? '';
  String get draftNotes => _draftNotes ?? _document?.notes ?? '';
  String? get lastTrashPath => _lastTrashPath;
  String? get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;
  bool get isFloatingBubble => _document?.floatingBubble ?? false;

  Future<void> open(String relativePath) async {
    _document = await _repository.read(relativePath);
    _draftUrl = _document!.uri.toString();
    _draftNotes = _document!.notes;
    _statusMessage = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<LinkDocument> create({
    required String title,
    required String url,
    String description = '',
    List<String> tags = const [],
    String notes = '',
  }) async {
    final validated = _validation.validate(url);
    if (!validated.isValid) {
      _errorMessage = validated.error;
      notifyListeners();
      throw StateError(validated.error!);
    }
    final created = await _repository.create(
      title: title,
      uri: validated.uri!,
      description: description,
      tags: tags,
      notes: notes,
    );
    await open(created.relativePath);
    _statusMessage = '已创建网站链接';
    notifyListeners();
    return created;
  }

  Future<LinkDocument> createFromClipboard() async {
    final text = await _clipboard.readText();
    if (text == null || text.trim().isEmpty) {
      _errorMessage = '剪贴板中没有可识别的链接';
      notifyListeners();
      throw StateError(_errorMessage!);
    }
    final validated = _validation.validate(text);
    if (!validated.isValid) {
      _errorMessage = validated.error;
      notifyListeners();
      throw StateError(validated.error!);
    }
    final uri = validated.uri!;
    final title = uri.host.isEmpty ? '未命名链接' : uri.host;
    return create(title: title, url: uri.toString());
  }

  void updateDraftUrl(String value) {
    _draftUrl = value;
    _errorMessage = null;
    notifyListeners();
  }

  void updateDraftNotes(String value) {
    _draftNotes = value;
    notifyListeners();
  }

  Future<void> save() async {
    final document = _requireDocument();
    final validated = _validation.validate(draftUrl);
    if (!validated.isValid) {
      _errorMessage = validated.error;
      notifyListeners();
      return;
    }
    _document = await _repository.save(
      document.copyWith(uri: validated.uri!, notes: draftNotes),
    );
    _draftUrl = _document!.uri.toString();
    _draftNotes = _document!.notes;
    _errorMessage = null;
    _statusMessage = '已保存';
    if (_document!.floatingBubble) {
      await _syncBubble(_document!);
    }
    notifyListeners();
  }

  Future<LinkDocument> rename(String title) async {
    final document = _requireDocument();
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('标题不能为空');
    }
    if (trimmed == document.title) {
      return document;
    }
    // Prefer the draft URL when valid; otherwise keep the saved URI so a
    // temporary address typo cannot block a title-only rename.
    var uri = document.uri;
    final validated = _validation.validate(draftUrl);
    if (validated.isValid && validated.uri != null) {
      uri = validated.uri!;
    }
    final renamed = await _repository.rename(
      document.relativePath,
      title: trimmed,
      uri: uri,
      notes: draftNotes,
      floatingBubble: document.floatingBubble,
    );
    await open(renamed.relativePath);
    if (renamed.floatingBubble) {
      await _syncBubble(renamed);
    }
    _statusMessage = '已更新标题';
    notifyListeners();
    return renamed;
  }

  Future<void> setFloatingBubble(bool enabled) async {
    final document = _requireDocument();
    final validated = _validation.validate(draftUrl);
    if (!validated.isValid) {
      _errorMessage = validated.error;
      notifyListeners();
      return;
    }
    final updated = await _repository.save(
      document.copyWith(
        uri: validated.uri!,
        notes: draftNotes,
        floatingBubble: enabled,
      ),
    );
    _document = updated;
    _draftUrl = updated.uri.toString();
    _draftNotes = updated.notes;
    if (enabled) {
      await _syncBubble(updated);
      _statusMessage = '已开启桌面悬浮球';
    } else {
      await _floatingBubbles.hide(updated.id);
      _statusMessage = '已关闭桌面悬浮球';
    }
    notifyListeners();
  }

  Future<void> restoreFloatingBubbles() async {
    final documents = await _repository.listAll();
    for (final document in documents.where((d) => d.floatingBubble)) {
      await _syncBubble(document);
    }
  }

  Future<void> copyUrl() async {
    final document = _requireDocument();
    final url = draftUrl.trim().isEmpty ? document.uri.toString() : draftUrl;
    final validated = _validation.validate(url);
    if (!validated.isValid) {
      _errorMessage = validated.error;
      notifyListeners();
      return;
    }
    await _clipboard.writeText(validated.uri!.toString());
    _statusMessage = '已复制链接';
    notifyListeners();
  }

  Future<void> openExternally() async {
    final document = _requireDocument();
    final url = draftUrl.trim().isEmpty ? document.uri.toString() : draftUrl;
    final validated = _validation.validate(url);
    if (!validated.isValid) {
      _errorMessage = validated.error;
      notifyListeners();
      return;
    }
    await _systemOpen.openExternalUrl(validated.uri!);
    _statusMessage = '已在外部浏览器打开';
    notifyListeners();
  }

  Future<void> openExternalUri(Uri uri) async {
    await _systemOpen.openExternalUrl(uri);
    _statusMessage = '已打开外部应用链接';
    notifyListeners();
  }

  Future<LinkDocument> duplicate() async {
    final document = _requireDocument();
    await save();
    final duplicated = await _repository.duplicate(document.relativePath);
    await open(duplicated.relativePath);
    _statusMessage = '已创建副本';
    notifyListeners();
    return duplicated;
  }

  Future<String> moveToTrash() async {
    final document = _requireDocument();
    if (document.floatingBubble) {
      await _floatingBubbles.hide(document.id);
    }
    final trashPath = await _repository.moveToTrash(document.relativePath);
    _document = null;
    _draftUrl = null;
    _draftNotes = null;
    _lastTrashPath = trashPath;
    _statusMessage = '已移到回收站';
    notifyListeners();
    return trashPath;
  }

  Future<LinkDocument> undoTrash() async {
    final trashPath = _lastTrashPath;
    if (trashPath == null) {
      throw StateError('没有可撤销的回收记录');
    }
    final linksIndex = trashPath.indexOf('/links/');
    if (linksIndex < 0) {
      throw StateError('无法解析回收路径：$trashPath');
    }
    final restoredRelative = trashPath.substring(linksIndex + 1);
    final source = File(p.join(_vaultRootPath, trashPath));
    final destination = File(p.join(_vaultRootPath, restoredRelative));
    await destination.parent.create(recursive: true);
    await source.rename(destination.path);
    _lastTrashPath = null;
    await open(restoredRelative);
    if (_document?.floatingBubble ?? false) {
      await _syncBubble(_document!);
    }
    _statusMessage = '已撤销回收';
    notifyListeners();
    return _document!;
  }

  Future<void> _syncBubble(LinkDocument document) async {
    await _floatingBubbles.show(
      id: document.id,
      title: document.title,
      url: document.uri.toString(),
    );
  }

  void _handleBubbleDismissed(String id) {
    unawaited(_persistBubbleDismissed(id));
  }

  Future<void> _persistBubbleDismissed(String id) async {
    try {
      if (_document?.id == id) {
        if (!(_document?.floatingBubble ?? false)) {
          return;
        }
        final updated = await _repository.save(
          _document!.copyWith(floatingBubble: false),
        );
        _document = updated;
        _statusMessage = '已关闭桌面悬浮球';
        notifyListeners();
        return;
      }

      final documents = await _repository.listAll();
      for (final document in documents) {
        if (document.id == id && document.floatingBubble) {
          await _repository.save(document.copyWith(floatingBubble: false));
          break;
        }
      }
    } catch (_) {
      // Native dismiss already hid the panel; persistence is best-effort.
    }
  }

  LinkDocument _requireDocument() {
    final document = _document;
    if (document == null) {
      throw StateError('尚未打开网站链接');
    }
    return document;
  }

  @override
  void dispose() {
    _floatingBubbles.onDismissed = null;
    // Bubbles stay until explicitly closed or app exits.
    super.dispose();
  }
}
