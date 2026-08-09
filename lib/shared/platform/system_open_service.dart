class SystemOpenException implements Exception {
  const SystemOpenException(this.operation, this.stderr);

  final String operation;
  final String stderr;

  @override
  String toString() => 'SystemOpenException($operation): $stderr';
}

abstract interface class SystemOpenService {
  Future<void> revealInFinder(String path);

  Future<void> openTerminalAt(String directoryPath);

  Future<void> openExternalUrl(Uri uri);
}
