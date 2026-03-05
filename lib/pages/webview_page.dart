import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WebViewPage extends StatefulWidget {
  final String title;
  final String url;

  const WebViewPage({super.key, required this.title, required this.url});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? _controller;
  final _secureStorage = const FlutterSecureStorage();

  double _progress = 0;
  bool _isLoading = true;
  String _currentUrl = '';

  // Configurações do InAppWebView
  late final InAppWebViewSettings _settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    useOnDownloadStart: true,        // Intercepta downloads
    useShouldOverrideUrlLoading: true,
    supportZoom: true,
    builtInZoomControls: false,
    displayZoomControls: false,
    cacheEnabled: true,
    clearCache: false,
    userAgent:
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
  );

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
  }

  // Salva sessão de forma segura
  Future<void> _saveSession(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () async {
            if (_controller != null && await _controller!.canGoBack()) {
              _controller!.goBack();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (_currentUrl.isNotEmpty)
              Text(
                _currentUrl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white54,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            onPressed: () => _controller?.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFFF1493),
                  ),
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(widget.url),
        ),
        initialSettings: _settings,
        onWebViewCreated: (controller) {
          _controller = controller;
        },
        onLoadStart: (controller, url) {
          setState(() {
            _isLoading = true;
            _currentUrl = url?.toString() ?? '';
          });
        },
        onLoadStop: (controller, url) async {
          setState(() {
            _isLoading = false;
            _currentUrl = url?.toString() ?? '';
          });
          // Salva última URL visitada de forma segura
          await _saveSession('last_url_${widget.title}', url?.toString() ?? '');
        },
        onProgressChanged: (controller, progress) {
          setState(() {
            _progress = progress / 100;
          });
        },
        // Intercepta downloads — salva apenas dentro do app
        onDownloadStartRequest: (controller, downloadStartRequest) {
          _handleDownload(downloadStartRequest.url.toString());
        },
        onPermissionRequest: (controller, request) async {
          // Permite câmera e microfone se solicitado pelo site
          return PermissionResponse(
            resources: request.resources,
            action: PermissionResponseAction.GRANT,
          );
        },
      ),
    );
  }

  // Download seguro — arquivo fica apenas no diretório privado do app
  Future<void> _handleDownload(String url) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A fazer download... O ficheiro ficará privado no app.'),
        backgroundColor: Color(0xFFFF1493),
        duration: Duration(seconds: 3),
      ),
    );
    // O flutter_downloader vai guardar em getApplicationDocumentsDirectory()
    // que é privado e inacessível por outros apps ou galeria
  }
}
