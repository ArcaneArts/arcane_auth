import 'package:arcane/arcane.dart';
import 'package:arcane_auth/arcane_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:serviced/serviced.dart';

class ArcaneFacebookSignInProvider {
  static Future<void> signInWithFacebook(BuildContext context) async {
    if (kIsWeb) {
      return svc<AuthService>().signInWithPopup(FacebookAuthProvider());
    }

    return svc<AuthService>().signIn(await SocialSignIn()
        .initialSite(
            svc<AuthService>().getSignInConfig<MicrosoftSignInConfig>()!, null)
        .signIn(context)
        .then((i) => i.credential));
  }
}
