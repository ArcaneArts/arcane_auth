import 'package:arcane_auth/arcane_auth.dart';

class GitHubSignInResult extends SocialSignInResultInterface {
  GitHubSignInResult(
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
