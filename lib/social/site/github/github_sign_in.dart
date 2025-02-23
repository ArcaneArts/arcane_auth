import 'dart:convert';

import 'package:arcane_auth/arcane_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'github_sign_in_config.dart';
import 'github_sign_in_result.dart';

class GitHubSignIn extends SocialSignInSite {
  static const String _authorizedUrl =
      'https://github.com/login/oauth/authorize';
  static const String _accessTokenUrl =
      'https://github.com/login/oauth/access_token';
  static const String _userDataUrl = 'https://api.github.com/user';
  static const String _emailUrl = 'https://api.github.com/user/emails';

  @override
  String clientId;

  @override
  String clientSecret;

  @override
  String redirectUrl;

  @override
  String scope;

  @override
  SocialSignInPageInfo pageInfo = DefaultSignInPageInfo();

  GitHubSignIn({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUrl,
    required this.scope,
  });

  @override
  String authUrl() {
    return '$_authorizedUrl?client_id=$clientId&redirect_uri=$redirectUrl&scope=$scope&state=$stateCode';
  }

  @override
  Future<dynamic> signInWithWebView(BuildContext context) async {
    bool isFinish = false;

    return await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SocialSignInPageMobile(
          url: authUrl(),
          redirectUrl: redirectUrl,
          userAgent: pageInfo.userAgent,
          clearCache: pageInfo.clearCache,
          title: pageInfo.title,
          centerTitle: pageInfo.centerTitle,
          onPageFinished: (String url) {
            if (isFinish) return;
            if (url.contains("error=")) {
              Navigator.of(context).pop(
                Exception(Uri.parse(url).queryParameters["error"]),
              );
            } else if (url.startsWith(redirectUrl)) {
              var uri = Uri.parse(url);
              if (uri.queryParameters.containsKey('code') &&
                  uri.queryParameters.containsKey('state') &&
                  uri.queryParameters['state'] == stateCode) {
                isFinish = true;
                Navigator.of(context).pop(uri.queryParameters["code"]);
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Future<SocialSignInResultInterface> exchangeAccessToken(
      String authorizationCode) async {
    try {
      final response = await http.post(
        Uri.parse(_accessTokenUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': authorizationCode,
          'redirect_uri': redirectUrl,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;

        if (body.containsKey('access_token')) {
          // Get user data with the access token
          final userResponse = await http.get(
            Uri.parse(_userDataUrl),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'token ${body['access_token']}',
            },
          );

          if (userResponse.statusCode == 200) {
            return GitHubSignInResult(
              SignInResultStatus.ok,
              accessToken: body['access_token'],
              state: stateCode,
            );
          }
        }
        throw handleResponseBodyFail(body);
      }
      throw handleUnSuccessCodeFail(response);
    } catch (e) {
      return GitHubSignInResult(
        SignInResultStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  factory GitHubSignIn.fromProfile(GitHubSignInConfig config) {
    return GitHubSignIn(
      clientId: config.clientId,
      clientSecret: config.clientSecret,
      redirectUrl: config.redirectUrl,
      scope: config.scope.join(' '),
    );
  }
}
