import 'package:arcane_auth/arcane_auth.dart';

/// Authorization details from MicrosoftSign login
class MicrosoftSignInResult extends SocialSignInResultInterface {
  MicrosoftSignInResult(
    this.status, {
    this.accessToken = "",
    this.idToken = "",
    this.errorMessage = "",
    this.state = "",
  });

  @override
  String accessToken;

  @override
  String errorMessage;

  @override
  String idToken;

  @override
  String state;

  @override
  SignInResultStatus status;
}
