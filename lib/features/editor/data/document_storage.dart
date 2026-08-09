abstract interface class DocumentStorage {
  Future<String> read(String absolutePath);

  Future<void> writeAtomically(String absolutePath, String contents);

  Future<DateTime> modifiedAt(String absolutePath);
}
