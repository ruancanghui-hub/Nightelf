import 'package:ai_workbench/features/launchers/domain/launcher_document.dart';

abstract interface class LauncherRepository {
  Future<LauncherDocument> create({
    required String title,
    required String scriptPath,
  });

  Future<LauncherDocument> read(String relativePath);

  Future<LauncherDocument> save(LauncherDocument document);

  Future<LauncherDocument> rename(
    String relativePath, {
    required String title,
    String? scriptPath,
  });

  Future<List<LauncherDocument>> listAll();

  Future<String> moveToTrash(String relativePath);
}
