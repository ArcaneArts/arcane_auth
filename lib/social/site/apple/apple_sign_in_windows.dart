import 'package:flutter/material.dart';
import 'package:arcane_auth/arcane_auth.dart';

class AppleSignInWindows extends AppleSignIn {
  String hostUrl;

  AppleSignInWindows(
      {required super.clientId,
      required super.redirectUrl,
      required this.hostUrl,
      super.scope = ""});

  @override
  String authUrl() {
    return "$hostUrl?scope=$scope";
  }

  @override
  Future<SocialSignInResultInterface> signIn(BuildContext context) async {
    stateCode = generateString(10); // simple state code
    final rawNonce = generateNonce();
    final state = buildState(p: 80);
    final nonce = sha256ofString(rawNonce);

    var authorizedResult = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SocialSignInPageDesktop(
            url: "${authUrl()}&state=$state&nonce=$nonce",
            redirectUrl: '',
            userAgent: pageInfo.userAgent,
            title: pageInfo.title,
            centerTitle: pageInfo.centerTitle,
            onPageFinished: (String url) {
              if (url.contains("error=")) {
                throw Exception(Uri.parse(url).queryParameters["error"]);
              } else if (url.startsWith("http://localhost")) {
                var uri = Uri.parse(url);
                if (uri.queryParameters.containsKey('id_token') &&
                    uri.queryParameters.containsKey('state') &&
                    uri.queryParameters['state'] == state) {
                  return uri.queryParameters["id_token"];
                } else {
                  throw Exception();
                }
              }
              return null;
            }),
      ),
    );
    if (authorizedResult == null ||
        authorizedResult.toString().contains('access_denied')) {
      throw SocialSignInException(
          status: SignInResultStatus.cancelled,
          description: "Sign In attempt has been cancelled.");
    } else if (authorizedResult is Exception) {
      throw SocialSignInException(description: authorizedResult.toString());
    }

    String authorizedCode = authorizedResult;
    debugPrint("authorized_code: $authorizedCode");

    return AppleSignInResult(SignInResultStatus.ok,
        state: stateCode, nonce: rawNonce, idToken: authorizedResult);
  }

  /// Parameters required for web-based authentication flows
  factory AppleSignInWindows.fromProfile(AppleSignInConfig config) {
    return AppleSignInWindows(
      clientId: config.clientId,
      redirectUrl: config.redirectUrl,
      hostUrl: config.hostUrl,
      scope: config.scope.isNotEmpty ? config.scope.join(" ") : "name email",
    );
  }
}
