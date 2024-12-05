import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:arcane_auth/arcane_auth.dart';

class AppleSignIn extends SocialSignInSite {
  ///Apple App Id
  ///The developer's client identifier, as provided by WWDR (Worldwide Developer Relations)
  @override
  String clientId;

  ///Apple APP Secret
  @override
  String clientSecret = "";

  ///Apple App's Redirect Url
  ///The URI to which the authorization redirects. It must include a domain name, and can't be an IP address or localhost.
  @override
  String redirectUrl;

  ///Apple Permissions
  ///The amount of user information requested from Apple. Valid values are named and email. You can request one, both, or none.
  @override
  String scope = "";

  final List<AppleIDAuthorizationScopes> scopes = [];

  @override
  SocialSignInPageInfo pageInfo = DefaultSignInPageInfo();

  AppleSignIn(
      {required this.clientId, required this.redirectUrl, this.scope = ""});

  @override
  String authUrl() {
    return "";
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String buildState({int p = 0}) {
    final jsonState = json.encode({"c": stateCode, "p": p});
    final bytes = utf8.encode(jsonState);
    return base64.encode(bytes);
  }

  /// Request credential for the currently signed in Apple account.
  @override
  Future<SocialSignInResultInterface> signIn(BuildContext context) async {
    stateCode = generateString(10); // simple state code
    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: scopes,
      nonce: nonce,
      state: buildState(),
      webAuthenticationOptions: Platform.isAndroid
          ? WebAuthenticationOptions(
              clientId: clientId,
              redirectUri: Uri.parse(redirectUrl),
            )
          : null,
    );

    if (appleCredential.identityToken != null) {
      return AppleSignInResult(SignInResultStatus.ok,
          state: stateCode,
          nonce: rawNonce,
          idToken: appleCredential.identityToken!);
    } else {
      return AppleSignInResult(
        SignInResultStatus.cancelled,
      );
    }
  }

  /// Parameters required for web-based authentication flows
  factory AppleSignIn.fromProfile(AppleSignInConfig config) {
    var appleSignIn = AppleSignIn(
      clientId: config.clientId,
      redirectUrl: config.redirectUrl,
      scope: config.scope.isNotEmpty ? config.scope.join(" ") : "name email",
    );
    for (var scope in config.scope) {
      if (scope == "email") {
        appleSignIn.scopes.add(AppleIDAuthorizationScopes.email);
      } else if (scope == "name") {
        appleSignIn.scopes.add(AppleIDAuthorizationScopes.fullName);
      }
    }
    return appleSignIn;
  }
}
