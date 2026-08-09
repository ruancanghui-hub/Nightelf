import 'dart:async';

import 'package:ai_workbench/features/editor/application/document_session.dart';
import 'package:ai_workbench/features/editor/data/document_storage.dart';
import 'package:ai_workbench/features/editor/data/file_document_storage.dart';
import 'package:ai_workbench/features/editor/domain/document_descriptor.dart';
import 'package:ai_workbench/features/workflows/application/workflow_canvas_controller.dart';
import 'package:ai_workbench/features/workflows/data/mermaid_flowchart_parser.dart';
import 'package:ai_workbench/features/workflows/data/workflow_layout_repository.dart';
import 'package:ai_workbench/features/workflows/data/workflow_repository.dart';
import 'package:ai_workbench/features/workflows/domain/workflow_diagnostic.dart';
import 'package:ai_workbench/features/workflows/domain/workflow_document.dart';
import 'package:ai_workbench/features/workflows/domain/workflow_graph.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

enum WorkflowViewMode { source, canvas }

class WorkflowController extends ChangeNotifier {
  WorkflowController({
    required WorkflowRepository repository,
    required WorkflowLayoutRepository layoutRepository,
    required String vaultRootPath,
    DocumentStorage? storage,
    MermaidFlowchartParser? parser,
    Duration parseDebounce = const Duration(milliseconds: 200),
  }) : _repository = repository,
       _layoutRepository = layoutRepository,
       _vaultRootPath = vaultRootPath,
       _storage = storage ?? FileDocumentStorage(),
       _parser = parser ?? const MermaidFlowchartParser(),
       _parseDebounce = parseDebounce,
       canvasController = WorkflowCanvasController(
         layoutRepository: layoutRepository,
       );

  final WorkflowRepository _repository;
  final WorkflowLayoutRepository _layoutRepository;
  final String _vaultRootPath;
  final DocumentStorage _storage;
  final MermaidFlowchartParser _parser;
  final Duration _parseDebounce;
  final WorkflowCanvasController canvasController;

  WorkflowDocument? _document;
  DocumentSession? _session;
  WorkflowViewMode _mode = WorkflowViewMode.source;
  WorkflowGraph? _currentGraph;
  WorkflowGraph? _lastValidGraph;
  List<WorkflowDiagnostic> _diagnostics = const [];
  String? _statusMessage;
  String? _lastTrashPath;
  Timer? _parseTimer;
  VoidCallback? _sessionListener;

  WorkflowDocument? get document => _document;
  DocumentSession? get session => _session;
  WorkflowViewMode get mode => _mode;
  WorkflowGraph? get currentGraph => _currentGraph;
  WorkflowGraph? get lastValidGraph => _lastValidGraph;
  List<WorkflowDiagnostic> get diagnostics => _diagnostics;
  String? get statusMessage => _statusMessage;
  String? get lastTrashPath => _lastTrashPath;
  String get source => _session?.text ?? _document?.source ?? '';
  bool get canUseCanvas {
    final document = _document;
    if (document == null || !document.supportsCanvas) {
      return false;
    }
    final ext = document.extension.toLowerCase();
    if (ext == '.mmd') {
      return true;
    }
    return _extractMermaidBlocks(source).length == 1;
  }

  Future<void> open(String relativePath) async {
    _cancelParseTimer();
    final previous = _session;
    if (_sessionListener != null && previous != null) {
      previous.removeListener(_sessionListener!);
    }
    previous?.dispose();
    _session = null;
    _document = await _repository.read(relativePath);
    final language = switch (_document!.extension.toLowerCase()) {
      '.json' => DocumentLanguage.json,
      '.yaml' || '.yml' => DocumentLanguage.yaml,
      _ => DocumentLanguage.mermaid,
    };
    _session = DocumentSession(
      descriptor: DocumentDescriptor(
        resourceId: _document!.id,
        absolutePath: p.join(_vaultRootPath, relativePath),
        language: language,
      ),
      storage: _storage,
    );
    _sessionListener = _onSessionChanged;
    _session!.addListener(_sessionListener!);
    await _session!.load();
    _mode = WorkflowViewMode.source;
    _statusMessage = null;
    _parseSourceNow(persistLayout: false);
    if (_currentGraph != null) {
      await canvasController.loadGraph(
        workflowId: _document!.id,
        graph: _currentGraph!,
      );
    }
    notifyListeners();
  }

  Future<WorkflowDocument> create({
    required String title,
    String source = '',
    String extension = '.mmd',
  }) async {
    final created = await _repository.create(
      title: title,
      source: source,
      extension: extension,
    );
    await open(created.relativePath);
    _statusMessage = '已创建 Workflow';
    notifyListeners();
    return created;
  }

  Future<WorkflowDocument> importFile(String absolutePath) async {
    final imported = await _repository.importFile(absolutePath: absolutePath);
    await open(imported.relativePath);
    _statusMessage = '已导入 Workflow';
    notifyListeners();
    return imported;
  }

  void updateSource(String value) {
    _session?.updateText(value);
    _scheduleParse();
  }

  Future<void> setMode(WorkflowViewMode mode) async {
    if (mode == WorkflowViewMode.canvas && !canUseCanvas) {
      _statusMessage = '当前文件类型不支持画布，或 Markdown 中需恰好一个 flowchart 代码块';
      notifyListeners();
      return;
    }
    _mode = mode;
    if (mode == WorkflowViewMode.canvas && _lastValidGraph != null) {
      await canvasController.loadGraph(
        workflowId: _document!.id,
        graph: _lastValidGraph!,
      );
    }
    notifyListeners();
  }

  Future<void> saveSource() async {
    final session = _session;
    final document = _document;
    if (session == null || document == null) {
      return;
    }
    // Persist raw editor text (includes front matter for mmd/md).
    await session.saveNow();
    _document = await _repository.read(document.relativePath);
    _statusMessage = '已保存';
    notifyListeners();
  }

  Future<String> moveToTrash() async {
    final document = _requireDocument();
    if (_session?.state.isDirty ?? false) {
      await _session!.saveNow();
    }
    final trashPath = await _repository.moveToTrash(document.relativePath);
    await _layoutRepository.delete(document.id);
    _detachSession();
    _document = null;
    _currentGraph = null;
    _lastValidGraph = null;
    _diagnostics = const [];
    _lastTrashPath = trashPath;
    _statusMessage = '已移到回收站';
    notifyListeners();
    return trashPath;
  }

  String mermaidSourceForParse() {
    final document = _document;
    if (document == null) {
      return '';
    }
    final text = source;
    final ext = document.extension.toLowerCase();
    if (ext == '.mmd') {
      return _bodyOnly(text);
    }
    if (ext == '.md') {
      final blocks = _extractMermaidBlocks(text);
      return blocks.length == 1 ? blocks.single : '';
    }
    return '';
  }

  void _onSessionChanged() {
    _scheduleParse();
    notifyListeners();
  }

  void _scheduleParse() {
    _cancelParseTimer();
    _parseTimer = Timer(_parseDebounce, () {
      _parseSourceNow(persistLayout: false);
      notifyListeners();
    });
  }

  void _parseSourceNow({required bool persistLayout}) {
    final document = _document;
    if (document == null || !document.supportsCanvas) {
      _currentGraph = null;
      _diagnostics = const [];
      return;
    }
    final mermaid = mermaidSourceForParse();
    if (mermaid.trim().isEmpty) {
      _diagnostics = [
        const WorkflowDiagnostic(
          line: 1,
          column: 1,
          message: '未找到可解析的 Mermaid flowchart',
        ),
      ];
      return;
    }
    final result = _parser.parse(mermaid);
    if (result.isSuccess) {
      _currentGraph = result.graph;
      _lastValidGraph = result.graph;
      _diagnostics = const [];
      if (persistLayout) {
        unawaited(
          canvasController.loadGraph(
            workflowId: document.id,
            graph: result.graph!,
          ),
        );
      }
    } else {
      _diagnostics = result.diagnostics;
      // Keep last valid graph visible on canvas.
      _currentGraph = _lastValidGraph;
    }
  }

  String _bodyOnly(String text) {
    if (!text.startsWith('---')) {
      return text;
    }
    final match = RegExp(
      r'^---[ \t]*\r?\n[\s\S]*?^---[ \t]*(?:\r?\n|$)',
      multiLine: true,
    ).firstMatch(text);
    if (match == null) {
      return text;
    }
    return text.substring(match.end);
  }

  List<String> _extractMermaidBlocks(String text) {
    final matches = RegExp(
      r'```(?:mermaid)?\s*\n([\s\S]*?)```',
      caseSensitive: false,
    ).allMatches(text);
    final blocks = <String>[];
    for (final match in matches) {
      final body = match.group(1)?.trim() ?? '';
      if (body.toLowerCase().startsWith('flowchart') ||
          body.toLowerCase().startsWith('graph')) {
        blocks.add(body);
      }
    }
    return blocks;
  }

  WorkflowDocument _requireDocument() {
    final document = _document;
    if (document == null) {
      throw StateError('尚未打开 Workflow');
    }
    return document;
  }

  void _detachSession() {
    _cancelParseTimer();
    final previous = _session;
    if (_sessionListener != null && previous != null) {
      previous.removeListener(_sessionListener!);
    }
    previous?.dispose();
    _session = null;
  }

  void _cancelParseTimer() {
    _parseTimer?.cancel();
    _parseTimer = null;
  }

  @override
  void dispose() {
    _detachSession();
    canvasController.dispose();
    super.dispose();
  }
}
