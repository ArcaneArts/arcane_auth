import 'dart:convert';
import 'dart:math';

import 'package:arcane/arcane.dart';
import 'package:arcane_auth/arcane_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:serviced/serviced.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart' as asi;

class ArcaneAppleSignInProvider {
  static Future<void> signInWithApple(BuildContext context) async {
    late UserCredential c;
    String rawNonce = _generateNonce();
    String nonce = _sha256ofString(rawNonce);
    asi.AuthorizationCredentialAppleID appleCredential =
        await asi.SignInWithApple.getAppleIDCredential(
      scopes: [
        asi.AppleIDAuthorizationScopes.email,
        asi.AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );
    svc<AuthService>().addUsernameHint(ArcaneAuthUserNameHint(
        firstName: appleCredential.givenName,
        lastName: appleCredential.familyName));

    await svc<AuthService>().signIn(OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
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
