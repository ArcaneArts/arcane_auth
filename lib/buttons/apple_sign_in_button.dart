/*
 * Copyright (c) 2024. Crucible Labs Inc.
 *
 * Crucible is a closed source project developed by Crucible Labs Inc.
 * Do not copy, share distribute or otherwise allow this source file
 * to leave hardware approved by Crucible Labs Inc. unless otherwise
 * approved by Crucible Labs Inc.
 */

import 'dart:convert';
import 'dart:math';

import 'package:arcane/arcane.dart';
import 'package:arcane_auth/arcane_auth.dart';
import 'package:common_svgs/common_svgs.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/svg.dart';
import 'package:serviced/serviced.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleSignInButton extends StatelessWidget {
  final Widget? icon;
  final String? label;

  const AppleSignInButton(
      {super.key,
      this.icon = const AppleLogo(),
      this.label = "Sign in with Apple"});

  @override
  Widget build(BuildContext context) => CredentialSignInButton(
        label: label,
        icon: icon,
        onPressed: signInWithApple,
      );

  static Future<void> signInWithApple() async {
    late UserCredential c;
    String rawNonce = _generateNonce();
    String nonce = _sha256ofString(rawNonce);
    AuthorizationCredentialAppleID appleCredential =
        await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );
    svc<AuthService>().addUsernameHint(ArcaneAuthUserNameHint(
        firstName: appleCredential.givenName,
        lastName: appleCredential.familyName));

    await svc<AuthService>().signIn(OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    ));
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

class AppleLogo extends StatelessWidget {
  final double size;

  const AppleLogo({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) => SvgPicture.string(svgApple,
      width: 18,
      height: 18,
      color: Theme.of(context).colorScheme.mutedForeground);
}
