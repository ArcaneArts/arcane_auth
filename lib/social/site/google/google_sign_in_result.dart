import 'package:arcane_auth/arcane_auth.dart';

/// Authorization details from Google login
class GoogleSignInResult extends SocialSignInResultInterface {
  GoogleSignInResult(
    this.status, {
    this.accessToken = "",
    this.idToken = "",
    this.errorMessage = "",
    this.state = "",
  });

  /// An OAuth2 access token that your application sends to authorize a Google API request.
  @override
  String accessToken;

  @override
  String errorMessage;

  ///This property is only returned if your request included an identity scope,
  ///such as openid, profile, or email.
  ///The value is a JSON Web Token (JWT) that contains digitally signed identity information about the user.
  @override
  String idToken;

  @override
  String state;

  @override
  SignInResultStatus status;
}
