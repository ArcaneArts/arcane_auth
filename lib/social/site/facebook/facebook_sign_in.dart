import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:arcane_auth/arcane_auth.dart';

class FacebookSignIn extends SocialSignInSite {
  ///Facebook App Id
  ///The ID of your app, found in your app's dashboard.
  @override
  String clientId;

  ///Facebook APP Secret
  @override
  String clientSecret;

  ///Facebook App's Redirect Url
  ///The URL that you want to redirect the person logging in back to.
  @override
  String redirectUrl;

  ///Facebook Permissions
  ///A list of permissions to request from the person using your app
  @override
  String scope;

  @override
  SocialSignInPageInfo pageInfo = DefaultSignInPageInfo();

  final String _authorizedUrl = "https://www.facebook.com/v16.0/dialog/oauth";
  final String _accessTokenUrl =
      "https://graph.facebook.com/v16.0/oauth/access_token";

  FacebookSignIn({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUrl,
    required this.scope,
  });

  // https://developers.facebook.com/docs/facebook-login/guides/advanced/manual-flow/
  @override
  String authUrl() {
    return "$_authorizedUrl?response_type=code&client_id=$clientId&redirect_uri=$redirectUrl&scope=$scope&state=$stateCode";
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
            debugPrint(url);
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

  /// Your server should then daily verify the session with Facebook,
  /// and revoke the session in your system if the authorization has been withdrawn on Facebook's side.
  @override
  Future<SocialSignInResultInterface> exchangeAccessToken(
      String authorizationCode) async {
    var uri = Uri.parse(_accessTokenUrl);
    final param = {
      "redirect_uri": redirectUrl,
      "client_id": clientId,
      "client_secret": clientSecret,
      "code": authorizationCode
    };
    var response = await http.get(Uri.https(uri.host, uri.path, param));

    if (response.statusCode == 200) {
      var body =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (body.containsKey("access_token")) {
        return FacebookSignInResult(SignInResultStatus.ok,
            accessToken: body["access_token"],
            idToken: body["id_token"] ?? "",
            state: stateCode);
      } else {
        throw handleResponseBodyFail(body);
      }
    } else {
      throw handleUnSuccessCodeFail(response);
    }
  }

  /// Parameters required for web-based authentication flows
  factory FacebookSignIn.fromProfile(FacebookSignInConfig config) {
    return FacebookSignIn(
      clientId: config.clientId,
      clientSecret: config.clientSecret,
      redirectUrl: config.redirectUrl,
      scope: config.scope.isNotEmpty
          ? config.scope.join(" ")
          : "email public_profile",
    );
  }
}
