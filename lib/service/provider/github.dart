import 'package:arcane/arcane.dart';
import 'package:arcane_auth/arcane_auth.dart';
import 'package:arcane_auth/social/site/github/github_sign_in_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:serviced/serviced.dart';

class ArcaneGitHubSignInProvider {
  static Future<void> signInWithGitHub(BuildContext context) async {
    // For web platforms, use Firebase's built-in popup
    if (kIsWeb) {
      return svc<AuthService>().signInWithPopup(GithubAuthProvider());
    }

    // For other platforms, use our custom GitHub sign-in implementation
    return svc<AuthService>().signIn(await SocialSignIn()
        .initialSite(
            svc<AuthService>().getSignInConfig<GitHubSignInConfig>()!, null)
        .signIn(context)
        .then((i) => i.credential));
  }
}
