import 'package:arcane/arcane.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:arcane_auth/arcane_auth.dart';
import 'package:desktop_webview_auth/desktop_webview_auth.dart';
import 'package:desktop_webview_auth/google.dart';
import 'package:fast_log/fast_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:serviced/serviced.dart';

class ArcaneGoogleSignInProvider {
  static Future<void> signInWithGoogle(BuildContext context) async {
    if (kIsWeb) {
      await svc<AuthService>().signInWithPopup(GoogleAuthProvider());
    } else if (Platform.isWindows) {
      await _signInWithGoogleWindowsV2(context);
    } else {
      gsi.GoogleSignInAccount? googleUser =
          await gsi.GoogleSignIn.standard().signIn();
      gsi.GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;
      await svc<AuthService>().signIn(GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      ));
    }
  }

  static Future<void> _signInWithGoogleWindowsV2(BuildContext context) async =>
      svc<AuthService>().signIn(await SocialSignIn()
          .initialSite(
              svc<AuthService>().getSignInConfig<GoogleSignInConfig>()!, null)
          .signIn(context)
          .then((i) => i.credential));

  static Future<void> _signInWithGoogleWindows({bool retry = true}) async {
    if (await _hasAuthToken()) {
      try {
        OAuthCredential at = GoogleAuthProvider.credential(
            accessToken: (await _loadAuthToken()).accessToken);
        await svc<AuthService>().signIn(AuthCredential(
          providerId: at.providerId,
          signInMethod: at.signInMethod,
          accessToken: at.accessToken,
          token: at.token,
        ));
      } catch (e, es) {
        error("Looks like our saved credentials are invalid!");
        warn(e);
        warn(es);
        await _clearAuthToken();
        if (retry) {
          return _signInWithGoogleWindows();
        } else {
          rethrow;
        }
      }
    } else {
      try {
        AuthResult ar = await _openGoogleSignInPopupWindows().bang;
        OAuthCredential at =
            GoogleAuthProvider.credential(accessToken: ar.accessToken);
        await svc<AuthService>()
            .signIn(AuthCredential(
              providerId: at.providerId,
              signInMethod: at.signInMethod,
              accessToken: at.accessToken,
              token: at.token,
            ))
            .thenRun((_) => _saveAuthToken(ar));
      } catch (e, es) {
        error("Failed to sign in with Google!");
        error(e);
        error(es);
        rethrow;
      }
    }
  }

  static Future<void> _saveAuthToken(AuthResult r) async {
    Box box = svc<AuthService>().authBox;
    await box.put("at", r.accessToken);
    await box.put("it", r.idToken);
    await box.put("ts", r.tokenSecret);
    verbose("Saved Auth Token");
  }

  static Future<void> _clearAuthToken() async {
    Box box = svc<AuthService>().authBox;
    await box.delete("at");
    await box.delete("it");
    await box.delete("ts");
    verbose("Cleared Auth Token");
  }

  static Future<bool> _hasAuthToken() =>
      Future.value(svc<AuthService>().authBox.get("at") != null);

  static Future<AuthResult> _loadAuthToken() => Future.value(AuthResult(
        accessToken: svc<AuthService>().authBox.get("at"),
        idToken: svc<AuthService>().authBox.get("it"),
        tokenSecret: svc<AuthService>().authBox.get("ts"),
      ));

  static Future<AuthResult?> _openGoogleSignInPopupWindows() =>
      DesktopWebviewAuth.signIn(GoogleSignInArgs(
          clientId: svc<AuthService>()
              .getSignInConfig<GoogleSignInConfig>()!
              .clientId,
          redirectUri: svc<AuthService>()
              .getSignInConfig<GoogleSignInConfig>()!
              .redirectUrl,
          scope: 'email'));
}
