import 'dart:async';

import 'package:fast_log/fast_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:serviced/serviced.dart';

String get $uid => svc<AuthService>()._fbUid;
bool get $signedIn => svc<AuthService>()._fbSignedIn;
bool get $anonymous => svc<AuthService>()._fbAnonymous;

class AuthService extends StatelessService implements AsyncStartupTasked {
  final bool allowAnonymous;
  final bool autoLink;
  final Future<void> Function(UserMeta user)? onBind;
  final Future<void> Function()? onUnbind;
  final List<StreamSubscription> _subscriptions = [];
  late final BehaviorSubject<AuthService> _authState;
  bool _bound = false;

  AuthService(
      {this.allowAnonymous = false,
      this.onBind,
      this.onUnbind,
      this.autoLink = true}) {
    _authState = BehaviorSubject.seeded(this);
  }

  bool get _fbSignedIn => FirebaseAuth.instance.currentUser != null;
  bool get _fbAnonymous =>
      FirebaseAuth.instance.currentUser?.isAnonymous ?? true;
  String get _fbUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Future<void> onStartupTask() async {
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
    await FirebaseAuth.instance.signOut();
    _logSuccess("Successfully Signed Out");
  }

  Future<void> link(AuthCredential credential) async {
    _log("Linking Credential <${credential.providerId}>");
    await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
    _logSuccess(
        "Successfully Linked Credential <${credential.providerId}> to ${$uid}");
  }

  Future<void> signIn(AuthCredential credential) async {
    _log("Signing In with Credential <${credential.providerId}>");
    if ($signedIn && autoLink) {
      await link(credential);
      _logSuccess(
          "Successfully Signed In with Credential <${credential.providerId}> as ${$uid}");
      return;
    }

    await FirebaseAuth.instance.signInWithCredential(credential);
    _logSuccess(
        "Successfully Signed In with Credential <${credential.providerId}> as ${$uid}");
  }

  Future<void> bind(String uid) async {
    if (_bound) {
      _logWarn("Already Bound, unbinding first");
      await unbind();
    }

    _log("Binding to $uid");
    await onBind?.call(UserMeta(FirebaseAuth.instance.currentUser!));
    _bound = true;
    _authState.add(this);
    _logSuccess("Successfully Bound to $uid");
  }

  Future<void> unbind() async {
    if (!_bound) {
      _logWarn("Not Bound, skipping unbind");
      return;
    }

    _log("Unbinding");
    await onUnbind?.call();
    _bound = false;
    for (var s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
    _logSuccess("Successfully Unbound");
  }
}

class UserMeta {
  final User user;

  const UserMeta(this.user);

  String? get displayName => extract<String>((i) => i.displayName);
  String? get firstName =>
      extract<String>((i) => (i.displayName?.contains(" ") ?? false)
          ? i.displayName!.split(" ").first
          : i.displayName);
  String? get lastName =>
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

class _AuthState {
  final String? uid;
  final bool anonymous;

  _AuthState(this.uid, this.anonymous);

  _AuthState.of(User? user)
      : uid = user?.uid,
        anonymous = user?.isAnonymous ?? true;

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
