import 'dart:io';

import 'package:ai_workbench/features/editor/application/document_session.dart';
import 'package:ai_workbench/features/editor/data/document_storage.dart';
import 'package:ai_workbench/features/editor/data/file_document_storage.dart';
import 'package:ai_workbench/features/editor/domain/document_descriptor.dart';
import 'package:ai_workbench/features/skills/data/skill_repository.dart';
import 'package:ai_workbench/features/skills/domain/import_progress.dart';
import 'package:ai_workbench/features/skills/domain/skill_resource.dart';
import 'package:ai_workbench/features/skills/domain/skill_tree_node.dart';
import 'package:ai_workbench/shared/platform/system_open_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

enum SkillPreviewKind { text, image, binary }

class SkillController extends ChangeNotifier {
  SkillController({
    required SkillRepository repository,
    required SystemOpenService systemOpen,
    required String vaultRootPath,
    DocumentStorage? storage,
  }) : _repository = repository,
       _systemOpen = systemOpen,
       _vaultRootPath = vaultRootPath,
       _storage = storage ?? FileDocumentStorage();

  static const textExtensions = {
    '.md',
    '.txt',
    '.json',
    '.yml',
    '.yaml',
    '.mmd',
    '.csv',
    '.xml',
    '.html',
    '.css',
    '.js',
    '.ts',
    '.dart',
    '.sh',
    '.py',
    '.toml',
    '.ini',
  };

  static const imageExtensions = {
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.webp',
    '.bmp',
  };

  final SkillRepository _repository;
  final SystemOpenService _systemOpen;
  final String _vaultRootPath;
  final DocumentStorage _storage;

  SkillResource? _skill;
  List<SkillTreeNode> _rootChildren = const [];
  String? _selectedRelativePath;
  SkillPreviewKind? _previewKind;
  DocumentSession? _session;
  String? _imageAbsolutePath;
  String? _lastTrashPath;
  String? _statusMessage;
  ImportProgress? _lastImportProgress;

  SkillResource? get skill => _skill;
  List<SkillTreeNode> get rootChildren => _rootChildren;
  String? get selectedRelativePath => _selectedRelativePath;
  SkillPreviewKind? get previewKind => _previewKind;
  DocumentSession? get session => _session;
  String? get imageAbsolutePath => _imageAbsolutePath;
  String? get lastTrashPath => _lastTrashPath;
  String? get statusMessage => _statusMessage;
  ImportProgress? get lastImportProgress => _lastImportProgress;

  Future<SkillResource> importDirectory(
    Directory source, {
    ConfirmLargeFile? confirmLargeFile,
  }) async {
    SkillResource? imported;
    await for (final progress in _repository.importDirectory(
      source,
      confirmLargeFile: confirmLargeFile,
    )) {
      _lastImportProgress = progress;
      notifyListeners();
      if (progress.skill != null) {
        imported = progress.skill;
      }
    }
    if (imported == null) {
      throw StateError('导入未返回 SKILL 资源');
    }
    await open(imported.relativeDirectory);
    _statusMessage = '已导入 SKILL：${imported.title}';
    notifyListeners();
    return imported;
  }

  Future<void> open(String relativeDirectory) async {
    await _disposeSession();
    _skill = await _repository.read(relativeDirectory);
    _rootChildren = await _repository.listChildren(relativeDirectory);
    _selectedRelativePath = null;
    _previewKind = null;
    _imageAbsolutePath = null;
    _statusMessage = null;
    notifyListeners();
    await openNode(_skill!.entryRelativePath);
  }

  Future<void> expandDirectory(SkillTreeNode node) async {
    if (!node.isDirectory || node.childrenLoaded) {
      return;
    }
    node.children
      ..clear()
      ..addAll(await _repository.listChildren(node.relativePath));
    node.childrenLoaded = true;
    notifyListeners();
  }

  Future<void> openNode(String relativePath) async {
    final absolute = p.join(_vaultRootPath, relativePath);
    final type = await FileSystemEntity.type(absolute, followLinks: false);
    if (type == FileSystemEntityType.directory) {
      return;
    }

    final extension = p.extension(relativePath).toLowerCase();
    if (textExtensions.contains(extension)) {
      await _openText(relativePath);
      return;
    }
    if (imageExtensions.contains(extension)) {
      await _disposeSession();
      _selectedRelativePath = relativePath;
      _previewKind = SkillPreviewKind.image;
      _imageAbsolutePath = absolute;
      _statusMessage = null;
      notifyListeners();
      return;
    }

    await _disposeSession();
    _selectedRelativePath = relativePath;
    _previewKind = SkillPreviewKind.binary;
    _imageAbsolutePath = null;
    await _systemOpen.openPath(absolute);
    _statusMessage = '已用系统默认应用打开';
    notifyListeners();
  }

  Future<void> saveSelectedText() async {
    final session = _session;
    if (session == null) {
      return;
    }
    await session.saveNow();
    _statusMessage = '已保存';
    notifyListeners();
  }

  Future<void> revealInFinder() async {
    final path = _selectedAbsolutePath ?? _skillAbsoluteDirectory;
    if (path == null) {
      return;
    }
    await _systemOpen.revealInFinder(path);
    _statusMessage = '已在 Finder 中显示';
    notifyListeners();
  }

  Future<void> openTerminal() async {
    final path = _skillAbsoluteDirectory;
    if (path == null) {
      return;
    }
    await _systemOpen.openTerminalAt(path);
    _statusMessage = '已打开终端';
    notifyListeners();
  }

  Future<SkillResource> duplicate() async {
    final skill = _requireSkill();
    final duplicated = await _repository.duplicate(skill.relativeDirectory);
    await open(duplicated.relativeDirectory);
    _statusMessage = '已创建副本';
    notifyListeners();
    return duplicated;
  }

  Future<String> moveToTrash() async {
    final skill = _requireSkill();
    await _disposeSession();
    final trashPath = await _repository.moveToTrash(skill.relativeDirectory);
    _lastTrashPath = trashPath;
    _skill = null;
    _rootChildren = const [];
    _selectedRelativePath = null;
    _previewKind = null;
    _imageAbsolutePath = null;
    _statusMessage = '已移到回收站';
    notifyListeners();
    return trashPath;
  }

  Future<SkillResource> undoTrash() async {
    final trashPath = _lastTrashPath;
    if (trashPath == null) {
      throw StateError('没有可撤销的回收记录');
    }
    final trashDir = Directory(p.join(_vaultRootPath, trashPath));
    if (!await trashDir.exists()) {
      throw StateError('回收站内容不存在');
    }
    final skillsIndex = trashPath.indexOf('/skills/');
    if (skillsIndex < 0) {
      throw StateError('无法解析回收路径：$trashPath');
    }
    final restoredRelative = trashPath.substring(skillsIndex + 1);
    final destination = Directory(p.join(_vaultRootPath, restoredRelative));
    await destination.parent.create(recursive: true);
    await trashDir.rename(destination.path);
    _lastTrashPath = null;
    await open(restoredRelative);
    _statusMessage = '已撤销回收';
    notifyListeners();
    return _skill!;
  }

  String? get _skillAbsoluteDirectory {
    final skill = _skill;
    if (skill == null) {
      return null;
    }
    return p.join(_vaultRootPath, skill.relativeDirectory);
  }

  String? get _selectedAbsolutePath {
    final relative = _selectedRelativePath;
    if (relative == null) {
      return null;
    }
    return p.join(_vaultRootPath, relative);
  }

  Future<void> _openText(String relativePath) async {
    await _disposeSession();
    final absolute = p.join(_vaultRootPath, relativePath);
    _selectedRelativePath = relativePath;
    _previewKind = SkillPreviewKind.text;
    _imageAbsolutePath = null;
    _session = DocumentSession(
      descriptor: DocumentDescriptor(
        resourceId: relativePath,
        absolutePath: absolute,
        language: _languageFor(relativePath),
      ),
      storage: _storage,
    );
    await _session!.load();
    _statusMessage = null;
    notifyListeners();
  }

  DocumentLanguage _languageFor(String relativePath) {
    final extension = p.extension(relativePath).toLowerCase();
    return switch (extension) {
      '.json' => DocumentLanguage.json,
      '.yml' || '.yaml' => DocumentLanguage.yaml,
      '.mmd' => DocumentLanguage.mermaid,
      '.md' || '.txt' => DocumentLanguage.markdown,
      _ => DocumentLanguage.plain,
    };
  }

  SkillResource _requireSkill() {
    final skill = _skill;
    if (skill == null) {
      throw StateError('尚未打开 SKILL');
    }
    return skill;
  }

  Future<void> _disposeSession() async {
    final previous = _session;
    _session = null;
    previous?.dispose();
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }
}
