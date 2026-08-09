import 'package:ai_workbench/features/links/domain/link_validation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Isolated in-app browser for http(s) website links.
class LinkInAppBrowser extends StatefulWidget {
  const LinkInAppBrowser({
    super.key,
    required this.url,
    this.onExternalScheme,
  });

  final String url;
  final Future<void> Function(Uri uri)? onExternalScheme;

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
              _error = detail.isEmpty
                  ? '无法加载页面（检查网络或链接）'
                  : '无法加载：$detail';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('内置浏览器', style: typography.headline),
            PushButton(
              controlSize: ControlSize.small,
              secondary: true,
              semanticLabel: '后退',
              onPressed: _canGoBack ? () => _controller.goBack() : null,
              child: const Text('后退'),
            ),
            PushButton(
              controlSize: ControlSize.small,
              secondary: true,
              semanticLabel: '前进',
              onPressed: _canGoForward ? () => _controller.goForward() : null,
              child: const Text('前进'),
            ),
            PushButton(
              controlSize: ControlSize.small,
              secondary: true,
              semanticLabel: '刷新页面',
              onPressed: _reload,
              child: const Text('刷新'),
            ),
            if (_isLoading)
              Text('加载中…', style: typography.caption1),
            if (_error != null)
              Text(
                _error!,
                style: typography.caption1.copyWith(
                  color: MacosColors.systemRedColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: MacosTheme.of(context).dividerColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: kIsWeb
                  ? Center(
                      child: Text(
                        '当前平台不支持内置浏览器',
                        style: typography.body,
                      ),
                    )
                  : WebViewWidget(controller: _controller),
            ),
          ),
        ),
      ],
    );
  }
}
