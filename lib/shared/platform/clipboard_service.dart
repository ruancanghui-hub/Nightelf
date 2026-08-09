abstract interface class ClipboardService {
  Future<void> writeText(String text);

  Future<String?> readText();
}
