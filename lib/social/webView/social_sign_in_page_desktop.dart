import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:arcane_auth/arcane_auth.dart';

@protected
class SocialSignInPageDesktop extends StatefulWidget {
  final String url;
  final String redirectUrl;
  final String title;
  final bool? centerTitle;
  final String? userAgent;
  final String? Function(String) onPageFinished;
  final String loadingLabel;

  const SocialSignInPageDesktop({
    Key? key,
    required this.url,
    required this.redirectUrl,
    required this.onPageFinished,
    this.userAgent,
    this.title = "",
    this.centerTitle,
    this.loadingLabel = "",
  }) : super(key: key);

  @override
  State createState() => _SocialSignInPageDesktopState();
}

class _SocialSignInPageDesktopState extends State<SocialSignInPageDesktop> {
  String? _authCode;

  @override
  void initState() {
    super.initState();
    initWebViewState();
  }

  Future<void> initWebViewState() async {
    final webView = await WebviewWindow.create(
      configuration: const CreateConfiguration(
          windowHeight: 600, windowWidth: 800, titleBarHeight: 0),
    );
    var encoded = Platform.isMacOS ? Uri.encodeFull(widget.url) : widget.url;

    webView
      ..launch(encoded)
      ..addOnUrlRequestCallback((url) {
        if (!mounted) return;
        debugPrint("callback $url");
        try {
          var result = widget.onPageFinished(url);
          setState(() {
            _authCode = result;
          });
          if (result != null) {
            Navigator.of(context).pop(result);
            webView.close();
          }
        } catch (e) {
          Navigator.of(context).pop(e);
        }
      })
      ..onClose.whenComplete(() {
        if (_authCode == null) {
          Navigator.of(context).pop();
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: widget.title.isNotEmpty
          ? AppBar(
              title: Text(widget.title),
              centerTitle: widget.centerTitle,
              automaticallyImplyLeading: false,
            )
          : null,
      body: Container(
        alignment: AlignmentDirectional.center,
        decoration: const BoxDecoration(
          color: Colors.white70,
        ),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.blue[200],
              borderRadius: BorderRadius.circular(10.0)),
          width: 300.0,
          height: 200.0,
          alignment: AlignmentDirectional.center,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Center(
                child: SizedBox(
                  height: 50.0,
                  width: 50.0,
                  child: CircularProgressIndicator(
                    value: null,
                    strokeWidth: 7.0,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 25.0),
                child: Center(
                  child: Text(
                    widget.loadingLabel,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
