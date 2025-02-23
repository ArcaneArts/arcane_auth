import 'package:arcane_auth/arcane_auth.dart';
import 'package:flutter/material.dart';

import 'github_sign_in.dart';
import 'github_sign_in_config.dart';

class GitHubSignInDesktop extends GitHubSignIn {
  GitHubSignInDesktop({
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

  factory GitHubSignInDesktop.fromProfile(GitHubSignInConfig config) {
    return GitHubSignInDesktop(
      clientId: config.clientId,
      clientSecret: config.clientSecret,
      redirectUrl: config.redirectUrl,
      scope: config.scope.join(' '),
    );
  }
}
