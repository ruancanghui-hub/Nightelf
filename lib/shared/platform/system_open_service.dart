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

  /// Opens a local file or directory with the default macOS application.
  Future<void> openPath(String path);

  /// Hands a one-click launcher script to macOS.
  ///
  /// `.command` is opened with `open`. `.sh` is executed in Terminal at the
  /// script's directory. Nightelf does not keep the process.
  Future<void> launchScript(String scriptPath);
}
