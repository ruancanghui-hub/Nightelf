import 'package:ai_workbench/features/links/domain/link_validation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Isolated in-app browser for http(s) website links.
class LinkInAppBrowser extends StatefulWidget {
  const LinkInAppBrowser({
    super.key,
    required this.url,
    this.onExternalScheme,
    this.onOpenExternally,
    this.addressController,
    this.onAddressSubmitted,
  });

  final String url;
  final Future<void> Function(Uri uri)? onExternalScheme;
  final VoidCallback? onOpenExternally;
  final TextEditingController? addressController;
  final ValueChanged<String>? onAddressSubmitted;

  @override
  State<LinkInAppBrowser> createState() => _LinkInAppBrowserState();
}

class _LinkInAppBrowserState extends State<LinkInAppBrowser> {
  late final WebViewController _controller;
  final LinkValidation _validation = const LinkValidation();
  var _isLoading = false;
  String? _error;
  String? _loadedUrl;
  var _canGoBack = false;
  var _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _controller = _createController();
    _load(widget.url);
  }

  @override
  void didUpdateWidget(covariant LinkInAppBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _load(widget.url);
    }
  }

  WebViewController _createController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isLoading = true;
              _error = null;
            });
          },
          onPageFinished: (_) async {
            if (!mounted) {
              return;
            }
            final back = await _controller.canGoBack();
            final forward = await _controller.canGoForward();
            setState(() {
              _isLoading = false;
              _canGoBack = back;
              _canGoForward = forward;
            });
          },
          onWebResourceError: (error) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isLoading = false;
              final detail = error.description.trim();
              _error = detail.isEmpty ? '无法加载页面（检查网络或链接）' : '无法加载：$detail';
            });
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) {
              return NavigationDecision.prevent;
            }
            final scheme = uri.scheme.toLowerCase();
            if (scheme == 'http' || scheme == 'https') {
              return NavigationDecision.navigate;
            }
            // Keep Vault/filesystem channels unavailable to the WebView.
            if (scheme == 'file' || scheme == 'javascript') {
              return NavigationDecision.prevent;
            }
            final open = widget.onExternalScheme;
            if (open != null) {
              open(uri);
            }
            return NavigationDecision.prevent;
          },
        ),
      );
    return controller;
  }

  Future<void> _load(String rawUrl) async {
    final validated = _validation.validate(rawUrl);
    if (!validated.isValid || validated.uri == null) {
      setState(() {
        _error = validated.error ?? '无效链接';
        _isLoading = false;
        _loadedUrl = null;
      });
      return;
    }
    final url = validated.uri!.toString();
    if (url == _loadedUrl) {
      return;
    }
    _loadedUrl = url;
    setState(() {
      _error = null;
      _isLoading = true;
    });
    await _controller.loadRequest(validated.uri!);
  }

  Future<void> _reload() async {
    if (_loadedUrl == null) {
      await _load(widget.url);
      return;
    }
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;
    return LinkBrowserFrame(
      url: _loadedUrl ?? widget.url,
      canGoBack: _canGoBack,
      canGoForward: _canGoForward,
      isLoading: _isLoading,
      error: _error,
      onBack: () => _controller.goBack(),
      onForward: () => _controller.goForward(),
      onReload: _reload,
      onExternal: widget.onOpenExternally,
      addressController: widget.addressController,
      onAddressSubmitted: widget.onAddressSubmitted,
      child: kIsWeb
          ? Center(child: Text('当前平台不支持内置浏览器', style: typography.body))
          : WebViewWidget(controller: _controller),
    );
  }
}

/// Testable, platform-neutral chrome around the embedded website surface.
class LinkBrowserFrame extends StatelessWidget {
  const LinkBrowserFrame({
    super.key,
    required this.url,
    required this.canGoBack,
    required this.canGoForward,
    required this.isLoading,
    required this.error,
    required this.onBack,
    required this.onForward,
    required this.onReload,
    required this.onExternal,
    required this.child,
    this.addressController,
    this.onAddressSubmitted,
  });

  final String url;
  final bool canGoBack;
  final bool canGoForward;
  final bool isLoading;
  final String? error;
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final VoidCallback? onReload;
  final VoidCallback? onExternal;
  final Widget child;
  final TextEditingController? addressController;
  final ValueChanged<String>? onAddressSubmitted;

  static const _surface = Color(0xFF071510);
  static const _toolbar = Color(0xFF0B1713);
  static const _border = Color(0xFF21483A);
  static const _muted = Color(0xFF9BB4AB);
  static const _text = Color(0xFFE7F6EE);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('link-browser-frame'),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: _toolbar,
            child: Row(
              children: [
                _BrowserIconButton(
                  key: const ValueKey('link-browser-back'),
                  semanticLabel: '后退',
                  icon: LucideIcons.arrowLeft,
                  onPressed: canGoBack ? onBack : null,
                ),
                const SizedBox(width: 4),
                _BrowserIconButton(
                  key: const ValueKey('link-browser-forward'),
                  semanticLabel: '前进',
                  icon: LucideIcons.arrowRight,
                  onPressed: canGoForward ? onForward : null,
                ),
                const SizedBox(width: 4),
                _BrowserIconButton(
                  key: const ValueKey('link-browser-refresh'),
                  semanticLabel: '刷新页面',
                  icon: LucideIcons.refreshCw,
                  onPressed: onReload,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: addressController == null
                      ? Container(
                          height: 34,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111E1A),
                            border: Border.all(color: const Color(0xFF315246)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _text, fontSize: 12),
                          ),
                        )
                      : SizedBox(
                          height: 34,
                          child: MacosTextField(
                            key: const ValueKey('link-browser-address'),
                            controller: addressController,
                            placeholder: 'https://example.com',
                            onSubmitted: onAddressSubmitted,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                _BrowserIconButton(
                  key: const ValueKey('link-browser-external'),
                  semanticLabel: '在外部浏览器打开',
                  icon: LucideIcons.externalLink,
                  onPressed: onExternal,
                ),
              ],
            ),
          ),
          if (isLoading || error != null)
            Container(
              constraints: const BoxConstraints(minHeight: 28),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF08130F),
                border: Border(bottom: BorderSide(color: _border)),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (isLoading)
                    const Text(
                      '加载中…',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  if (error != null)
                    Text(
                      error!,
                      style: const TextStyle(
                        color: MacosColors.systemRedColor,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BrowserIconButton extends StatelessWidget {
  const _BrowserIconButton({
    super.key,
    required this.semanticLabel,
    required this.icon,
    required this.onPressed,
  });

  final String semanticLabel;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 16,
            color: enabled ? LinkBrowserFrame._text : const Color(0xFF536A61),
          ),
        ),
      ),
    );
  }
}
