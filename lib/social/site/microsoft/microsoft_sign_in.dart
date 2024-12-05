import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:arcane_auth/arcane_auth.dart';

class MicrosoftSignIn extends SocialSignInSite {
  ///MicrosoftSignIn App Id.
  ///Application ID created in Azure Portal
  @override
  String clientId;

  ///MicrosoftSignIn APP Secret
  @override
  String clientSecret;

  ///A redirect URI is the location where the Microsoft identity platform redirects a user's client
  ///and sends security tokens after authentication.
  @override
  String redirectUrl;

  ///MicrosoftSignIn Permissions.
  ///Scopes and permissions in the Microsoft identity platform set to admin restricted.
  ///https://learn.microsoft.com/en-us/graph/permissions-reference
  @override
  String scope;

  @override
  SocialSignInPageInfo pageInfo = DefaultSignInPageInfo();

  final String _authorizedUrl =
      "https://login.microsoftonline.com/common/oauth2/v2.0/authorize";
  final String _accessTokenUrl =
      "https://login.microsoftonline.com/common/oauth2/v2.0/token";

  MicrosoftSignIn({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUrl,
    required this.scope,
  });

  @override
  String authUrl() {
    return "$_authorizedUrl?client_id=$clientId&response_type=code&redirect_uri=$redirectUrl&response_mode=query&scope=$scope&state=$stateCode";
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
            debugPrint(url);
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

  /// Your server should then daily verify the session with Microsoft,
  /// and revoke the session in your system if the authorization has been withdrawn on Microsoft's side.
  @override
  Future<SocialSignInResultInterface> exchangeAccessToken(
      String authorizationCode) async {
    var response = await http.post(
      Uri.parse(_accessTokenUrl),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "grant_type": "authorization_code",
        "redirect_uri": redirectUrl,
        "client_id": clientId,
        "client_secret": clientSecret,
        "code": authorizationCode
      },
    );

    if (response.statusCode == 200) {
      var body =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (body.containsKey("access_token")) {
        return MicrosoftSignInResult(
          SignInResultStatus.ok,
          accessToken: body["access_token"],
          state: stateCode,
        );
      } else {
        throw handleResponseBodyFail(body);
      }
    } else {
      throw handleUnSuccessCodeFail(response);
    }
  }

  /// Parameters required for web-based authentication flows
  factory MicrosoftSignIn.fromProfile(MicrosoftSignInConfig config) {
    return MicrosoftSignIn(
      clientId: config.clientId,
      clientSecret: config.clientSecret,
      redirectUrl: config.redirectUrl,
      scope: config.scope.isNotEmpty ? config.scope.join(" ") : "user.read",
    );
  }
}
