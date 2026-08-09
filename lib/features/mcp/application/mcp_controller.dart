import 'dart:io';

import 'package:ai_workbench/features/editor/application/document_session.dart';
import 'package:ai_workbench/features/editor/data/document_storage.dart';
import 'package:ai_workbench/features/editor/data/file_document_storage.dart';
import 'package:ai_workbench/features/editor/domain/document_descriptor.dart';
import 'package:ai_workbench/features/mcp/data/json_validation_service.dart';
import 'package:ai_workbench/features/mcp/data/mcp_repository.dart';
import 'package:ai_workbench/features/mcp/domain/json_diagnostic.dart';
import 'package:ai_workbench/features/mcp/domain/mcp_document.dart';
import 'package:ai_workbench/shared/platform/clipboard_service.dart';
import 'package:ai_workbench/shared/platform/system_open_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class McpController extends ChangeNotifier {
  McpController({
    required McpRepository repository,
    required ClipboardService clipboard,
    required SystemOpenService systemOpen,
    required String vaultRootPath,
    JsonValidationService? validation,
    DocumentStorage? storage,
  }) : _repository = repository,
       _clipboard = clipboard,
       _systemOpen = systemOpen,
       _vaultRootPath = vaultRootPath,
       _validation = validation ?? const JsonValidationService(),
       _storage = storage ?? FileDocumentStorage();

  final McpRepository _repository;
  final ClipboardService _clipboard;
  final SystemOpenService _systemOpen;
  final String _vaultRootPath;
  final JsonValidationService _validation;
  final DocumentStorage _storage;

  McpDocument? _document;
  DocumentSession? _session;
  JsonDiagnostic? _diagnostic;
  String? _lastTrashPath;
  String? _statusMessage;

  McpDocument? get document => _document;
  DocumentSession? get session => _session;
  JsonDiagnostic? get diagnostic => _diagnostic;
  String? get lastTrashPath => _lastTrashPath;
  String? get statusMessage => _statusMessage;
  bool get isValid => _diagnostic == null;

  Future<void> open(String relativePath) async {
    await _disposeSession();
    _document = await _repository.read(relativePath);
    _session = DocumentSession(
      descriptor: DocumentDescriptor(
        resourceId: _document!.id,
        absolutePath: p.join(_vaultRootPath, relativePath),
        language: DocumentLanguage.json,
      ),
      storage: _storage,
    );
    await _session!.load();
    _session!.addListener(_onSessionChanged);
    _revalidate();
    _statusMessage = null;
    notifyListeners();
  }

  Future<McpDocument> create({
    required String title,
    String description = '',
    List<String> tags = const [],
    String jsonText = '{\n  "mcpServers": {}\n}\n',
  }) async {
    final created = await _repository.create(
      title: title,
      description: description,
      tags: tags,
      jsonText: jsonText,
    );
    await open(created.relativePath);
    return created;
  }

  Future<void> validate() async {
    _revalidate();
    notifyListeners();
  }

  Future<void> format() async {
    final session = _session;
    if (session == null) {
      return;
    }
    try {
      final formatted = _validation.format(session.text);
      session.updateText(formatted);
      await session.saveNow();
      _document = _document?.copyWith(jsonText: formatted);
      _revalidate();
      _statusMessage = '已格式化';
      notifyListeners();
    } on FormatException catch (error) {
      _revalidate();
      _statusMessage = '无法格式化：${error.message}';
      notifyListeners();
    }
  }

  Future<void> copySafeTemplate() async {
    final session = _session;
    final document = _requireDocument();
    final text = session?.text ?? document.jsonText;
    final result = _validation.validate(text);
    if (!result.isValid) {
      _diagnostic = result.diagnostic;
      _statusMessage = 'JSON 无效，无法复制安全模板';
      notifyListeners();
      return;
    }
    await _clipboard.writeText(text);
    _statusMessage = '已复制安全模板';
    notifyListeners();
  }

  Future<Never> requestFullCopy() async {
    throw const FullCopyUnavailable();
  }

  Future<void> openTerminal() async {
    final document = _requireDocument();
    final absolute = p.join(_vaultRootPath, document.relativePath);
    await _systemOpen.openTerminalAt(p.dirname(absolute));
    _statusMessage = '已打开终端';
    notifyListeners();
  }

  Future<McpDocument> duplicate() async {
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
    await _disposeSession();
    _document = null;
    _diagnostic = null;
    _lastTrashPath = trashPath;
    _statusMessage = '已移到回收站';
    notifyListeners();
    return trashPath;
  }

  Future<McpDocument> undoTrash() async {
    final trashPath = _lastTrashPath;
    if (trashPath == null) {
      throw StateError('没有可撤销的回收记录');
    }
    final mcpIndex = trashPath.indexOf('/mcp/');
    if (mcpIndex < 0) {
      throw StateError('无法解析回收路径：$trashPath');
    }
    final restoredRelative = trashPath.substring(mcpIndex + 1);
    final source = File(p.join(_vaultRootPath, trashPath));
    final destination = File(p.join(_vaultRootPath, restoredRelative));
    await destination.parent.create(recursive: true);
    await source.rename(destination.path);
    _lastTrashPath = null;
    await open(restoredRelative);
    _statusMessage = '已撤销回收';
    notifyListeners();
    return _document!;
  }

  void _onSessionChanged() {
    _revalidate();
    notifyListeners();
  }

  void _revalidate() {
    final text = _session?.text ?? _document?.jsonText;
    if (text == null) {
      _diagnostic = null;
      return;
    }
    final result = _validation.validate(text);
    _diagnostic = result.diagnostic;
  }

  McpDocument _requireDocument() {
    final document = _document;
    if (document == null) {
      throw StateError('尚未打开 MCP 配置');
    }
    return document;
  }

  Future<void> _disposeSession() async {
    final previous = _session;
    _session = null;
    previous?.removeListener(_onSessionChanged);
    previous?.dispose();
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChanged);
    _session?.dispose();
    super.dispose();
  }
}
