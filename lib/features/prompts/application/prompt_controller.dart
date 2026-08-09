import 'dart:io';

import 'package:ai_workbench/features/editor/application/document_session.dart';
import 'package:ai_workbench/features/editor/data/document_storage.dart';
import 'package:ai_workbench/features/editor/data/file_document_storage.dart';
import 'package:ai_workbench/features/editor/domain/document_descriptor.dart';
import 'package:ai_workbench/features/prompts/data/prompt_repository.dart';
import 'package:ai_workbench/features/prompts/domain/prompt_document.dart';
import 'package:ai_workbench/shared/platform/clipboard_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class PromptController extends ChangeNotifier {
  PromptController({
    required PromptRepository repository,
    required ClipboardService clipboard,
    required String vaultRootPath,
    DocumentStorage? storage,
  }) : _repository = repository,
       _clipboard = clipboard,
       _vaultRootPath = vaultRootPath,
       _storage = storage ?? FileDocumentStorage();

  final PromptRepository _repository;
  final ClipboardService _clipboard;
  final String _vaultRootPath;
  final DocumentStorage _storage;

  PromptDocument? _document;
  DocumentSession? _session;
  String? _lastTrashPath;
  String? _statusMessage;

  PromptDocument? get document => _document;
  DocumentSession? get session => _session;
  String? get lastTrashPath => _lastTrashPath;
  String? get statusMessage => _statusMessage;

  Future<void> open(String relativePath) async {
    final previous = _session;
    _session = null;
    previous?.dispose();
    _document = await _repository.read(relativePath);
    _session = DocumentSession(
      descriptor: DocumentDescriptor(
        resourceId: _document!.id,
        absolutePath: p.join(_vaultRootPath, relativePath),
        language: DocumentLanguage.markdown,
      ),
      storage: _storage,
    );
    await _session!.load();
    _statusMessage = null;
    notifyListeners();
  }

  Future<PromptDocument> create({
    required String title,
    String description = '',
    List<String> tags = const [],
    String body = '',
  }) async {
    final created = await _repository.create(
      title: title,
      description: description,
      tags: tags,
      body: body,
    );
    await open(created.relativePath);
    return created;
  }

  Future<void> copyPlainText() async {
    final document = _requireDocument();
    final text = _session?.text ?? document.body;
    await _clipboard.writeText(
      _bodyFromEditorText(text, fallback: document.body),
    );
    _statusMessage = '已复制纯文本';
    notifyListeners();
  }

  Future<void> copyMarkdown() async {
    final document = _requireDocument();
    final text = _session?.text ?? document.body;
    await _clipboard.writeText(
      _bodyFromEditorText(text, fallback: document.body),
    );
    _statusMessage = '已复制 Markdown';
    notifyListeners();
  }

  Future<PromptDocument> duplicate() async {
    final document = _requireDocument();
    if (_session?.state.isDirty ?? false) {
      await _session!.saveNow();
    }
    final duplicated = await _repository.duplicate(document.relativePath);
    await open(duplicated.relativePath);
    _statusMessage = '已创建副本';
    notifyListeners();
    return duplicated;
  }

  Future<String> moveToTrash() async {
    final document = _requireDocument();
    if (_session?.state.isDirty ?? false) {
      await _session!.saveNow();
    }
    final trashPath = await _repository.moveToTrash(document.relativePath);
    final previous = _session;
    _session = null;
    previous?.dispose();
    _document = null;
    _lastTrashPath = trashPath;
    _statusMessage = '已移到回收站';
    notifyListeners();
    return trashPath;
  }

  Future<PromptDocument> undoTrash() async {
    final trashPath = _lastTrashPath;
    if (trashPath == null) {
      throw StateError('没有可撤销的回收操作');
    }
    final parts = p.split(trashPath);
    final promptsIndex = parts.indexOf('prompts');
    if (promptsIndex < 0) {
      throw StateError('回收路径无效：$trashPath');
    }
    final relativePath = p.joinAll(parts.sublist(promptsIndex));
    final source = File(p.join(_vaultRootPath, trashPath));
    final destination = File(p.join(_vaultRootPath, relativePath));
    await destination.parent.create(recursive: true);
    await source.rename(destination.path);
    _lastTrashPath = null;
    await open(relativePath);
    _statusMessage = '已撤销回收';
    notifyListeners();
    return _document!;
  }

  PromptDocument _requireDocument() {
    final document = _document;
    if (document == null) {
      throw StateError('尚未打开提示词');
    }
    return document;
  }

  String _bodyFromEditorText(String text, {required String fallback}) {
    if (text.startsWith('---')) {
      final match = RegExp(
        r'^---[ \t]*\r?\n[\s\S]*?^---[ \t]*(?:\r?\n|$)',
        multiLine: true,
      ).firstMatch(text);
      if (match != null) {
        return text.substring(match.end);
      }
    }
    return text.isEmpty ? fallback : text;
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }
}
