import 'package:arcane_auth/arcane_auth.dart';

/// Authorization details from Facebook login
class FacebookSignInResult extends SocialSignInResultInterface {
  FacebookSignInResult(
    this.status, {
    this.accessToken = "",
    this.idToken = "",
    this.state = "",
  });

  ///An app access token or an access token for a developer of the app
  @override
  String accessToken;

  @override
  String errorMessage = "";

  @override
  String idToken = "";

  @override
  String state;

  @override
  SignInResultStatus status;
}
