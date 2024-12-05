import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:arcane_auth/arcane_auth.dart';

@protected
class SocialSignInPageMobile extends StatefulWidget {
  final String url;
  final String redirectUrl;
  final bool clearCache;
  final String title;
  final bool? centerTitle;
  final String? userAgent;
  final void Function(String) onPageFinished;

  const SocialSignInPageMobile({
    Key? key,
    required this.url,
    required this.redirectUrl,
    required this.onPageFinished,
    this.userAgent,
    this.clearCache = true,
    this.title = "",
    this.centerTitle,
  }) : super(key: key);

  @override
  State createState() => _SocialSignInPageMobileState();
}

class _SocialSignInPageMobileState extends State<SocialSignInPageMobile> {
  static const String _userAgent =
      "Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(widget.userAgent ?? _userAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            if (!mounted) return;
            widget.onPageFinished(url);
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: widget.centerTitle,
      ),
      body: WebViewWidget(controller: controller),
    ));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
