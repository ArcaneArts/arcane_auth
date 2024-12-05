import 'package:arcane_auth/arcane_auth.dart';

/// Authorization details from Apple login
class AppleSignInResult extends SocialSignInResultInterface {
  AppleSignInResult(
    this.status, {
    this.idToken = "",
    this.state = "",
    this.nonce = "",
  });

  @override
  String accessToken = "";

  ///The returned error message.
  @override
  String errorMessage = "";

  ///A JSON web token containing the user's identity information.
  @override
  String idToken;

  @override
  SignInResultStatus status;

  String nonce;

  ///The state contained in the Authorize URL.
  @override
  String state;
}
