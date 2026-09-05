import 'dart:io';

import 'package:ai_workbench/features/launchers/data/launcher_repository.dart';
import 'package:ai_workbench/features/launchers/domain/launcher_document.dart';
import 'package:ai_workbench/features/launchers/domain/launcher_script.dart';
import 'package:ai_workbench/shared/platform/script_picker_service.dart';
import 'package:ai_workbench/shared/platform/system_open_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class LauncherController extends ChangeNotifier {
  LauncherController({
    required LauncherRepository repository,
    required SystemOpenService systemOpen,
    required ScriptPickerService scriptPicker,
    required String vaultRootPath,
  }) : _repository = repository,
       _systemOpen = systemOpen,
       _scriptPicker = scriptPicker,
       _vaultRootPath = vaultRootPath;

  final LauncherRepository _repository;
  final SystemOpenService _systemOpen;
  final ScriptPickerService _scriptPicker;
  final String _vaultRootPath;

  LauncherDocument? _document;
  String? _lastTrashPath;
  String? _statusMessage;
  String? _errorMessage;

  LauncherDocument? get document => _document;
  String? get lastTrashPath => _lastTrashPath;
  String? get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;

  bool get isScriptMissing {
    final path = _document?.scriptPath;
    if (path == null || path.isEmpty) {
      return true;
    }
    return !LauncherScript.exists(path);
  }

  bool get canLaunch {
    final path = _document?.scriptPath;
    if (path == null) {
      return false;
    }
    return LauncherScript.canLaunch(path);
  }

  Future<void> open(String relativePath) async {
    _document = await _repository.read(relativePath);
    _statusMessage = null;
    _errorMessage = _pathError(_document!.scriptPath);
    notifyListeners();
  }

  Future<LauncherDocument?> createFromPicker() async {
    final picked = await _scriptPicker.pickScript();
    if (picked == null) {
      return null;
    }
    final error = LauncherScript.validatePath(picked);
    if (error != null) {
      _errorMessage = error;
      notifyListeners();
      throw StateError(error);
    }
    final created = await _repository.create(
      title: LauncherScript.defaultTitleFor(picked),
      scriptPath: picked,
    );
    await open(created.relativePath);
    _statusMessage = '已创建启动器';
    notifyListeners();
    return created;
  }

  Future<LauncherDocument> rename(String title) async {
    final document = _requireDocument();
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('标题不能为空');
    }
    if (trimmed == document.title) {
      return document;
    }
    final renamed = await _repository.rename(
      document.relativePath,
      title: trimmed,
    );
    await open(renamed.relativePath);
    _statusMessage = '已更新标题';
    notifyListeners();
    return renamed;
  }

  Future<void> pickScriptPath() async {
    final picked = await _scriptPicker.pickScript();
    if (picked == null) {
      return;
    }
    await _saveScriptPath(picked);
  }

  Future<void> launch() async {
    final document = _requireDocument();
    final error = _pathError(document.scriptPath);
    if (error != null) {
      _errorMessage = error;
      notifyListeners();
      return;
    }
    try {
      await _systemOpen.launchScript(document.scriptPath);
      _errorMessage = null;
      _statusMessage = '已启动';
    } on SystemOpenException catch (error) {
      _errorMessage = error.stderr;
    }
    notifyListeners();
  }

  Future<String> moveToTrash() async {
    final document = _requireDocument();
    final trashPath = await _repository.moveToTrash(document.relativePath);
    _document = null;
    _lastTrashPath = trashPath;
    _statusMessage = '已移到回收站';
    _errorMessage = null;
    notifyListeners();
    return trashPath;
  }

  Future<LauncherDocument> undoTrash() async {
    final trashPath = _lastTrashPath;
    if (trashPath == null) {
      throw StateError('没有可撤销的回收记录');
    }
    final launchersIndex = trashPath.indexOf('/launchers/');
    if (launchersIndex < 0) {
      throw StateError('无法解析回收路径：$trashPath');
    }
    final restoredRelative = trashPath.substring(launchersIndex + 1);
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

  Future<void> _saveScriptPath(String scriptPath) async {
    final document = _requireDocument();
    final error = LauncherScript.validatePath(scriptPath);
    if (error != null) {
      _errorMessage = error;
      notifyListeners();
      return;
    }
    _document = await _repository.save(
      document.copyWith(scriptPath: scriptPath),
    );
    _errorMessage = _pathError(_document!.scriptPath);
    _statusMessage = '已更新脚本路径';
    notifyListeners();
  }

  String? _pathError(String path) {
    final formatError = LauncherScript.validatePath(path);
    if (formatError != null) {
      return formatError;
    }
    if (!LauncherScript.exists(path)) {
      return '找不到文件';
    }
    return null;
  }

  LauncherDocument _requireDocument() {
    final document = _document;
    if (document == null) {
      throw StateError('尚未打开启动器');
    }
    return document;
  }
}
