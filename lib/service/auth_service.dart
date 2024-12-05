import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:arcane/arcane.dart';
import 'package:arcane_auth/arcane_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:desktop_webview_auth/desktop_webview_auth.dart';
import 'package:desktop_webview_auth/google.dart';
import 'package:fast_log/fast_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:hive_flutter/adapters.dart';
import 'package:serviced/serviced.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart' as asi;

String? get $uid => svc<AuthService>()._fbUid;
bool get $signedIn => svc<AuthService>()._fbSignedIn;
bool get $anonymous => svc<AuthService>()._fbAnonymous;

void initArcaneAuth({
  bool allowAnonymous = false,
  Future<void> Function(UserMeta user)? onBind,
  Future<void> Function()? onUnbind,
  bool autoLink = true,
  List<SocialSignInSiteConfig> signInConfigs = const [],
}) {
  services().register<AuthService>(
      () => AuthService(
            signInConfigs: signInConfigs,
            onBind: onBind,
            onUnbind: onUnbind,
            allowAnonymous: allowAnonymous,
            autoLink: autoLink,
          ),
      lazy: false);
}

class AuthService extends StatelessService
    implements AsyncStartupTasked, ArcaneAuthProvider {
  final bool allowAnonymous;
  final bool autoLink;
  final Future<void> Function(UserMeta user)? onBind;
  final Future<void> Function()? onUnbind;
  final List<StreamSubscription> _subscriptions = [];
  final List<ArcaneAuthUserNameHint> _nameHints = [];
  final List<SocialSignInSiteConfig> signInConfigs;
  late final Box _authBox;
  late final Box _dataBox;
  late final BehaviorSubject<AuthService> _authState;
  bool _bound = false;

  AuthService(
      {this.allowAnonymous = false,
      this.onBind,
      this.onUnbind,
      this.autoLink = true,
      this.signInConfigs = const []}) {
    _authState = BehaviorSubject.seeded(this);
  }

  Box get box => _dataBox;
  Box get authBox => _authBox;
  bool get _fbSignedIn => FirebaseAuth.instance.currentUser != null;
  bool get _fbAnonymous =>
      FirebaseAuth.instance.currentUser?.isAnonymous ?? false;
  String? get _fbUid => FirebaseAuth.instance.currentUser?.uid;

  T? getSignInConfig<T extends SocialSignInSiteConfig>() =>
      signInConfigs.whereType<T>().firstOrNull;

  bool hasSignInConfig<T extends SocialSignInSiteConfig>() =>
      signInConfigs.any((e) => e is T);

  Future<void> _initBox() async {
    if (!kIsWeb) {
      try {
        await Hive.initFlutter(FirebaseAuth.instance.app.options.apiKey);
      } catch (e, es) {
        _logError("Failed to initialize Hive: $e $es");
      }
    }

    _dataBox = await Hive.openBox("arcane_auth_data");
    _authBox = await Hive.openBox("arcane_auth_keys",
        encryptionCipher: HiveAesCipher(await _genBoxKey().toList()));
  }

  Stream<int> _genBoxKey([int length = 32]) async* {
    String grn([int length = 32]) {
      String charset =
          '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._${sha512.convert(utf8.encode("${FirebaseAuth.instance.app.name}.${FirebaseAuth.instance.app.options.appId}.${FirebaseAuth.instance.app.options.apiKey}.${FirebaseAuth.instance.app.options.projectId}"))}';
      Random random = Random.secure();
      return List.generate(
          length, (_) => charset[random.nextInt(charset.length)]).join();
    }

    String a = _dataBox.get("nonce", defaultValue: grn(32 + length));
    String b = _dataBox.get("ecnon", defaultValue: grn(16 + length));
    int ent = 0;
    for (int i = 0; i < length; i++) {
      ent += i + a.codeUnitAt(i) + b.codeUnitAt(i);
      int gdr = (ent % 694) +
          "${a.substring((i + ent ~/ 3) % a.length)}${b.substring((i + ent ~/ 7) % b.length)}"
              .hashCode;
      yield ((ent ^ gdr) - i) % 256;
      ent ~/= (i + 1);
      ent ^= gdr;
    }
  }

  @override
  Future<void> onStartupTask() async {
    await _initBox();
    FirebaseAuth.instance
        .authStateChanges()
        .map(_AuthState.of)
        .distinct()
        .asyncMap(_onAuthState)
        .listen((_) {});

    if (allowAnonymous) {
      await FirebaseAuth.instance.signInAnonymously();
    }

    PrecisionStopwatch p = PrecisionStopwatch.start();

    double _dl = 1;
    while (p.getMilliseconds() < 1000) {
      await Future.delayed(Duration(milliseconds: (_dl *= 1.1).round()));
      _dl += 80;

      if ($signedIn) {
        success("Caught Sign in after ${p.getMilliseconds()}ms");
        break;
      }
    }
  }

  void _log(String message) => verbose("[ArcaneAuth]: $message");
  void _logError(String message) => error("[ArcaneAuth]: $message");
  void _logWarn(String message) => warn("[ArcaneAuth]: $message");
  void _logSuccess(String message) => success("[ArcaneAuth]: $message");

  Future<void> _onAuthState(_AuthState state) async {
    _log("Auth State: $state");
    if (state.isSignedIn) {
      try {
        await bind(state.uid!);
      } catch (e, es) {
        _logError("Error Binding $state: $e $es");
      }
    } else {
      try {
        await unbind();
      } catch (e, es) {
        _logError("Error Unbinding $state: $e $es");
      }
    }
  }

  Stream<AuthService> get stream => _authState.stream;

  StreamSubscription<T> listen<T>(Stream<T> stream, void Function(T) onData) {
    StreamSubscription<T> s = stream.listen(onData);
    _subscriptions.add(s);
    return s;
  }

  Future<void> signOut(BuildContext context) async {
    Navigator.of(context).popUntil((route) => route.isFirst);

    _log("Signing Out");
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e, es) {
      error("Failed to sign out of Firebase $e $es");
    }
    try {
      await gsi.GoogleSignIn.standard().signOut();
    } catch (e) {}
    _logSuccess("Successfully Signed Out");
  }

  Future<void> linkCredential(AuthCredential credential) async {
    _log("Linking Credential <${credential.providerId}>");
    await FirebaseAuth.instance.currentUser!
        .linkWithCredential(credential)
        .then(processUserCredential);
    _logSuccess(
        "Successfully Linked Credential <${credential.providerId}> to ${$uid}");
  }

  Future<void> linkPopup(AuthProvider provider) async {
    _log("Linking Popup <${provider.providerId}>");
    await FirebaseAuth.instance.currentUser!
        .linkWithPopup(provider)
        .then(processUserCredential);
    _logSuccess(
        "Successfully Linked Popup <${provider.providerId}> to ${$uid}");
  }

  Future<void> processUserCredential(UserCredential credential) async {
    Map<String, dynamic> profile = credential.additionalUserInfo?.profile ?? {};
    svc<AuthService>().addUsernameHint(ArcaneAuthUserNameHint(
        firstName: profile["given_name"], lastName: profile["family_name"]));
  }

  Future<void> signInWithPopup(AuthProvider provider) async {
    _log("Signing In with Popup <${provider.providerId}>");
    if ($signedIn && autoLink) {
      await linkPopup(provider);
      _logSuccess(
          "Successfully Signed In & Linked with Popup <${provider.providerId}> with ${$uid}");
      await bind($uid!);
      return;
    }

    await FirebaseAuth.instance
        .signInWithPopup(provider)
        .then(processUserCredential);
    _logSuccess(
        "Successfully Signed In with Popup <${provider.providerId}> as ${$uid}");
  }

  Future<void> signInWithEmailPassword(
      {required String email, required String password}) async {
    _log("Signing In with Email <$email>");

    await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password)
        .then(processUserCredential);
    _logSuccess("Successfully Signed In with Email <$email> as ${$uid}");
  }

  Future<void> registerWithEmailPassword(
      {required String email, required String password}) async {
    _log("Signing In with Email <$email>");

    if ($signedIn && autoLink) {
      await linkCredential(
          EmailAuthProvider.credential(email: email, password: password));
      _logSuccess(
          "Successfully Registered & Linked with Email <$email> with ${$uid}");
      await bind($uid!);
      return;
    }

    await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password)
        .then(processUserCredential);
    _logSuccess("Successfully Registered In with Email <$email> as ${$uid}");
  }

  Future<void> signIn(AuthCredential credential) async {
    _log("Signing In with Credential <${credential.providerId}>");
    if ($signedIn && autoLink) {
      await linkCredential(credential);
      _logSuccess(
          "Successfully Signed In & Linked with Credential <${credential.providerId}> with ${$uid}");
      await bind($uid!);
      return;
    }

    await FirebaseAuth.instance
        .signInWithCredential(credential)
        .then(processUserCredential);
    _logSuccess(
        "Successfully Signed In with Credential <${credential.providerId}> as ${$uid}");
  }

  Future<void> bind(String uid) async {
    if (_bound) {
      _logWarn("Already Bound, unbinding first");
      await unbind();
    }

    _log("Binding to $uid");
    await onBind
        ?.call(UserMeta(FirebaseAuth.instance.currentUser!, _nameHints));
    _nameHints.clear();
    _bound = true;
    _authState.add(this);
    _logSuccess("Successfully Bound to $uid");
  }

  void addUsernameHint(ArcaneAuthUserNameHint hint) => _nameHints.add(hint);

  Future<void> unbind() async {
    if (!_bound) {
      _logWarn("Not Bound, skipping unbind");
      return;
    }

    _log("Unbinding");
    await onUnbind?.call();
    for (var s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
    _bound = false;

    if (allowAnonymous) {
      FirebaseAuth.instance.signInAnonymously().then(processUserCredential);
    } else {
      _authState.add(this);
    }

    _logSuccess("Successfully Unbound");
  }

  @override
  Future<void> signInWithProvider(ArcaneSignInProviderType type) =>
      type.signIn();
}

class UserMeta {
  final User user;
  final List<ArcaneAuthUserNameHint> hints;

  const UserMeta(this.user, this.hints);

  String? get displayName => extract<String>((i) => i.displayName);
  String? get firstName =>
      hints.map((i) => i.firstName).whereType<String>().firstOrNull ??
      extract<String>((i) => (i.displayName?.contains(" ") ?? false)
          ? i.displayName!.split(" ").first
          : i.displayName);
  String? get lastName =>
      hints.map((i) => i.lastName).whereType<String>().firstOrNull ??
      extract<String>((i) => (i.displayName?.contains(" ") ?? false)
          ? i.displayName!.split(" ").sublist(1).join(" ")
          : i.displayName);
  String? get email => extract<String>((i) => i.email);
  String? get phoneNumber => extract<String>((i) => i.phoneNumber);

  T? extract<T>(T? Function(UserInfo) extractor) =>
      extractor(UserInfo.fromJson({
        "uid": user.uid,
        "email": user.email,
        "displayName": user.displayName,
        "photoUrl": user.photoURL,
        "phoneNumber": user.phoneNumber,
        "isAnonymous": user.isAnonymous,
        "isEmailVerified": user.emailVerified,
        "providerId": user.providerData.first.providerId,
        "tenantId": user.tenantId,
        "refreshToken": user.refreshToken,
        "creationTimestamp": user.metadata.creationTime?.millisecondsSinceEpoch,
        "lastSignInTimestamp":
            user.metadata.lastSignInTime?.millisecondsSinceEpoch,
      })) ??
      user.providerData.map(extractor).whereType<T>().firstOrNull;
}

class ArcaneAuthUserNameHint {
  final String? firstName;
  final String? lastName;

  ArcaneAuthUserNameHint({
    this.firstName,
    this.lastName,
  });
}

class _AuthState {
  final String? uid;
  final bool anonymous;

  _AuthState(this.uid, this.anonymous);

  _AuthState.of(User? user)
      : uid = user?.uid,
        anonymous = user?.isAnonymous ?? false;

  bool get isSignedIn => uid != null;

  @override
  String toString() {
    return '(uid: $uid, anonymous: $anonymous)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is _AuthState &&
        other.uid == uid &&
        other.anonymous == anonymous;
  }

  @override
  int get hashCode => uid.hashCode ^ anonymous.hashCode;
}

extension XArcaneSignInProviderType on ArcaneSignInProviderType {
  Future<void> signIn() async {
    switch (this) {
      case ArcaneSignInProviderType.google:
        return ArcaneGoogleSignInProvider.signInWithGoogle();
      case ArcaneSignInProviderType.apple:
        return ArcaneAppleSignInProvider.signInWithApple();
    }
  }
}

class ArcaneAppleSignInProvider {
  static Future<void> signInWithApple() async {
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

class ArcaneGoogleSignInProvider {
  static Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await svc<AuthService>().signInWithPopup(GoogleAuthProvider());
    } else if (Platform.isWindows) {
      await _signInWithGoogleWindows(retry: true);
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
