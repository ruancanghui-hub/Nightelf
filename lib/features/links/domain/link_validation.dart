class LinkValidationResult {
  const LinkValidationResult._({this.uri, this.error});

  const LinkValidationResult.valid(Uri uri) : this._(uri: uri);

  const LinkValidationResult.invalid(String error) : this._(error: error);

  final Uri? uri;
  final String? error;

  bool get isValid => uri != null && error == null;
}

class LinkValidation {
  const LinkValidation();

  LinkValidationResult validate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const LinkValidationResult.invalid('链接不能为空');
    }

    final candidate = _withScheme(trimmed);
    final parsed = Uri.tryParse(candidate);
    if (parsed == null || !parsed.hasScheme) {
      return const LinkValidationResult.invalid('链接格式无效');
    }
    final scheme = parsed.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return const LinkValidationResult.invalid('仅支持 http 或 https 链接');
    }
    if (parsed.host.trim().isEmpty) {
      return const LinkValidationResult.invalid('链接格式无效');
    }

    final normalized = parsed.replace(
      scheme: scheme,
      host: parsed.host.toLowerCase(),
    );
    return LinkValidationResult.valid(normalized);
  }

  /// http(s) pages stay inside the in-app WebView.
  bool isInAppWebScheme(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  /// WKWebView internal / unsafe schemes must not be forwarded to `open`.
  bool shouldIgnoreExternalOpen(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    return scheme.isEmpty ||
        scheme == 'about' ||
        scheme == 'data' ||
        scheme == 'blob' ||
        scheme == 'file' ||
        scheme == 'javascript';
  }

  String _withScheme(String value) {
    if (RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(value)) {
      return value;
    }
    return 'https://$value';
  }
}
