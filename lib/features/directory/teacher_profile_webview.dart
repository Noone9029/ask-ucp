import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TeacherProfileWebView extends StatefulWidget {
  final String url;
  final String title;

  const TeacherProfileWebView({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<TeacherProfileWebView> createState() => _TeacherProfileWebViewState();
}

class _TeacherProfileWebViewState extends State<TeacherProfileWebView> {
  late final WebViewController _controller;
  int _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();

    final uri = Uri.tryParse(widget.url);
    if (uri == null || !(uri.isScheme("https") || uri.isScheme("http"))) {
      _error = "Invalid URL";
      return;
    }
    const allowedHosts = <String>{
      "ucp.edu.pk",
      "www.ucp.edu.pk",
    };
    if (!allowedHosts.contains(uri.host)) {
      _error = "Blocked: external website";
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onWebResourceError: (err) {
            setState(() {
              _error = err.description;
            });
          },
          onNavigationRequest: (request) {
            final navUri = Uri.tryParse(request.url);
            if (navUri != null && allowedHosts.contains(navUri.host)) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: "Reload",
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: _progress < 100
              ? LinearProgressIndicator(value: _progress / 100)
              : const SizedBox(height: 3),
        ),
      ),
      body: _error != null
          ? _ErrorView(
              message: _error!,
              onRetry: () {
                setState(() => _error = null);
                initState();
              },
            )
          : WebViewWidget(controller: _controller),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 44),
            const SizedBox(height: 10),
            Text(
              "Couldn’t load teacher profile",
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Try again"),
            ),
          ],
        ),
      ),
    );
  }
}
