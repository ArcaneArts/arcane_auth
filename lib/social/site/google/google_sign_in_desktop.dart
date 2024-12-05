import 'package:flutter/material.dart';
import 'package:arcane_auth/arcane_auth.dart';

class GoogleSignInDesktop extends GoogleSignIn {
  GoogleSignInDesktop({
    required super.clientId,
    required super.clientSecret,
    required super.redirectUrl,
    required super.scope,
  });

  @override
  Future<dynamic> signInWithWebView(BuildContext context) async {
    return await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SocialSignInPageDesktop(
          url: authUrl(),
          redirectUrl: redirectUrl,
          userAgent: pageInfo.userAgent,
          title: pageInfo.title,
          centerTitle: pageInfo.centerTitle,
          onPageFinished: (String url) {
            if (url.contains("error=")) {
              throw Exception(Uri.parse(url).queryParameters["error"]);
            } else if (url.startsWith(redirectUrl)) {
              var uri = Uri.parse(url);
              if (uri.queryParameters.containsKey('code') &&
                  uri.queryParameters.containsKey('state') &&
                  uri.queryParameters['state'] == stateCode) {
                return uri.queryParameters["code"];
              }
              return "";
            }
            return null;
          },
        ),
      ),
    );
  }

  /// Parameters required for web-based authentication flows
  factory GoogleSignInDesktop.fromProfile(GoogleSignInConfig config) {
    return GoogleSignInDesktop(
        clientId: config.clientId,
        clientSecret: config.clientSecret,
        redirectUrl: config.redirectUrl,
        scope:
            config.scope.isNotEmpty ? config.scope.join(" ") : "profile email");
  }
}
