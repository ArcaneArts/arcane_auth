import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:fast_log/fast_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:rxdart/rxdart.dart';
import 'package:serviced/serviced.dart';

String? get $uid => svc<AuthService>()._fbUid;
bool get $signedIn => svc<AuthService>()._fbSignedIn;
bool get $anonymous => svc<AuthService>()._fbAnonymous;

void initArcaneAuth(
    {bool allowAnonymous = false,
    Future<void> Function(UserMeta user)? onBind,
    Future<void> Function()? onUnbind,
    bool autoLink = true,
    String? googleClientID,
    String? googleRedirectURI}) {
  services().register<AuthService>(
      () => AuthService(
          onBind: onBind,
          onUnbind: onUnbind,
          allowAnonymous: allowAnonymous,
          autoLink: autoLink,
          googleClientID: googleClientID,
          googleRedirectURI: googleRedirectURI),
      lazy: false);
}

class AuthService extends StatelessService implements AsyncStartupTasked {
  final bool allowAnonymous;
  final bool autoLink;
  final Future<void> Function(UserMeta user)? onBind;
  final Future<void> Function()? onUnbind;
  final List<StreamSubscription> _subscriptions = [];
  final List<ArcaneAuthUserNameHint> _nameHints = [];
  final String? googleClientID;
  final String? googleRedirectURI;
  late final Box _authBox;
  late final Box _dataBox;
  late final BehaviorSubject<AuthService> _authState;
  bool _bound = false;

  AuthService(
      {this.allowAnonymous = false,
      this.onBind,
      this.onUnbind,
      this.autoLink = true,
      this.googleClientID,
      this.googleRedirectURI}) {
    _authState = BehaviorSubject.seeded(this);
  }

  Box get box => _dataBox;
  Box get authBox => _authBox;
  bool get _fbSignedIn => FirebaseAuth.instance.currentUser != null;
  bool get _fbAnonymous =>
      FirebaseAuth.instance.currentUser?.isAnonymous ?? false;
  String? get _fbUid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _initBox() async {
    await Hive.initFlutter(FirebaseAuth.instance.app.name);
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

  Future<void> signOut() async {
    _log("Signing Out");
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e, es) {
      error("Failed to sign out of Firebase $e $es");
    }
    try {
      await GoogleSignIn.standard().signOut();
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
          "Successfully Signed In with Popup <${provider.providerId}> as ${$uid}");
      await bind($uid!);
      return;
    }

    await FirebaseAuth.instance
        .signInWithPopup(provider)
        .then(processUserCredential);
    _logSuccess(
        "Successfully Signed In with Popup <${provider.providerId}> as ${$uid}");
  }

  Future<void> signIn(AuthCredential credential) async {
    _log("Signing In with Credential <${credential.providerId}>");
    if ($signedIn && autoLink) {
      await linkCredential(credential);
      _logSuccess(
          "Successfully Signed In with Credential <${credential.providerId}> as ${$uid}");
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
      if (allowAnonymous) {
        await FirebaseAuth.instance
            .signInAnonymously()
            .then(processUserCredential);
      }
    } else {
      _authState.add(this);
    }

    _logSuccess("Successfully Unbound");
  }
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
