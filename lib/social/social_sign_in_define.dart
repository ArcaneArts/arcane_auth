import 'package:arcane_auth/arcane_auth.dart';

///Representing different platforms of social Sign-in.
enum SocialPlatform {
  ///https://developer.apple.com/account/resources/identifiers/list/bundleId
  apple,

  ///https://developers.facebook.com/
  facebook,

  ///https://console.cloud.google.com/
  google,

  ///https://portal.azure.com/
  microsoft,
}

///Representing the status after login.
enum SignInResultStatus {
  /// The login was successful.
  ok,

  /// The user cancelled the login flow, usually by closing the
  /// login dialog.
  cancelled,

  /// The login completed with an error and the user couldn't log
  /// in for some reason.
  failed,
}
