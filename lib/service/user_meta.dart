import 'package:firebase_auth/firebase_auth.dart';

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
