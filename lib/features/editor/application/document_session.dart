import 'dart:async';

import 'package:ai_workbench/features/editor/data/document_storage.dart';
import 'package:ai_workbench/features/editor/domain/document_descriptor.dart';
import 'package:flutter/foundation.dart';

enum DocumentSessionStatus {
  loading,
  clean,
  dirty,
  saving,
  externalConflict,
  failure,
}

class DocumentSessionState {
  const DocumentSessionState({
    required this.status,
    required this.text,
    this.diskText,
    this.modifiedAt,
    this.errorMessage,
  });

  final DocumentSessionStatus status;
  final String text;
  final String? diskText;
  final DateTime? modifiedAt;
  final String? errorMessage;

  bool get isClean => status == DocumentSessionStatus.clean;
  bool get isDirty => status == DocumentSessionStatus.dirty;
  bool get isLoading => status == DocumentSessionStatus.loading;
  bool get hasConflict => status == DocumentSessionStatus.externalConflict;

  DocumentSessionState copyWith({
    DocumentSessionStatus? status,
    String? text,
    String? diskText,
    bool clearDiskText = false,
    DateTime? modifiedAt,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DocumentSessionState(
      status: status ?? this.status,
      text: text ?? this.text,
      diskText: clearDiskText ? null : (diskText ?? this.diskText),
      modifiedAt: modifiedAt ?? this.modifiedAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DocumentSession extends ChangeNotifier {
  DocumentSession({
    required this.descriptor,
    required DocumentStorage storage,
    this.autosaveDelay = const Duration(milliseconds: 600),
  }) : _storage = storage,
       _state = const DocumentSessionState(
         status: DocumentSessionStatus.loading,
         text: '',
       );

  final DocumentDescriptor descriptor;
  final DocumentStorage _storage;
  final Duration autosaveDelay;

  DocumentSessionState _state;
  Timer? _autosaveTimer;
  bool _disposed = false;

  DocumentSessionState get state => _state;
  String get text => _state.text;

  Future<void> load() async {
    _setState(
      _state.copyWith(status: DocumentSessionStatus.loading, clearError: true),
    );
    try {
      final text = await _storage.read(descriptor.absolutePath);
      final modifiedAt = await _storage.modifiedAt(descriptor.absolutePath);
      _setState(
        DocumentSessionState(
          status: DocumentSessionStatus.clean,
          text: text,
          modifiedAt: modifiedAt,
        ),
      );
    } catch (error) {
      _setState(
        _state.copyWith(
          status: DocumentSessionStatus.failure,
          errorMessage: '无法读取文件：$error',
        ),
      );
    }
  }

  void updateText(String text) {
    if (descriptor.readOnly || _disposed) {
      return;
    }
    if (text == _state.text && _state.status == DocumentSessionStatus.dirty) {
      return;
    }
    _setState(
      _state.copyWith(
        status: DocumentSessionStatus.dirty,
        text: text,
        clearError: true,
      ),
    );
    _scheduleAutosave();
  }

  Future<void> saveNow() async {
    _autosaveTimer?.cancel();
    if (_disposed || descriptor.readOnly) {
      return;
    }
    if (_state.status != DocumentSessionStatus.dirty &&
        _state.status != DocumentSessionStatus.failure) {
      return;
    }

    final buffer = _state.text;
    _setState(
      _state.copyWith(status: DocumentSessionStatus.saving, clearError: true),
    );
    try {
      await _storage.writeAtomically(descriptor.absolutePath, buffer);
      final modifiedAt = await _storage.modifiedAt(descriptor.absolutePath);
      if (_disposed) {
        return;
      }
      // If user typed during save, keep dirty with latest buffer.
      if (_state.text != buffer) {
        _setState(
          _state.copyWith(
            status: DocumentSessionStatus.dirty,
            modifiedAt: modifiedAt,
          ),
        );
        _scheduleAutosave();
        return;
      }
      _setState(
        DocumentSessionState(
          status: DocumentSessionStatus.clean,
          text: buffer,
          modifiedAt: modifiedAt,
        ),
      );
    } catch (error) {
      if (_disposed) {
        return;
      }
      _setState(
        _state.copyWith(
          status: DocumentSessionStatus.failure,
          text: buffer,
          errorMessage: '保存失败：$error',
        ),
      );
    }
  }

  Future<void> handleExternalChange(DateTime diskModifiedAt) async {
    final known = _state.modifiedAt;
    if (known != null && !diskModifiedAt.isAfter(known)) {
      return;
    }

    final diskText = await _storage.read(descriptor.absolutePath);
    if (_disposed) {
      return;
    }

    if (_state.isDirty || _state.status == DocumentSessionStatus.saving) {
      _setState(
        _state.copyWith(
          status: DocumentSessionStatus.externalConflict,
          diskText: diskText,
          modifiedAt: diskModifiedAt,
        ),
      );
      return;
    }

    _setState(
      DocumentSessionState(
        status: DocumentSessionStatus.clean,
        text: diskText,
        modifiedAt: diskModifiedAt,
      ),
    );
  }

  Future<void> keepLocalVersion() async {
    if (!_state.hasConflict) {
      return;
    }
    _setState(
      _state.copyWith(status: DocumentSessionStatus.dirty, clearDiskText: true),
    );
    await saveNow();
  }

  Future<void> keepDiskVersion() async {
    if (!_state.hasConflict || _state.diskText == null) {
      return;
    }
    _autosaveTimer?.cancel();
    _setState(
      DocumentSessionState(
        status: DocumentSessionStatus.clean,
        text: _state.diskText!,
        modifiedAt: _state.modifiedAt,
      ),
    );
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(autosaveDelay, () {
      unawaited(saveNow());
    });
  }

  void _setState(DocumentSessionState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _autosaveTimer?.cancel();
    if (_state.isDirty) {
      // Best-effort flush; callers in UI should await saveNow before dispose when possible.
      unawaited(_storage.writeAtomically(descriptor.absolutePath, _state.text));
    }
    super.dispose();
  }
}
