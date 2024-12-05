import 'package:arcane_auth/arcane_auth.dart';

// class SocialSignInResult extends SocialSignInResultInterface {
//   SocialSignInResult(
//     this.status, {
//     this.accessToken = "",
//   });
//
//   @override
//   String accessToken;
//
//   @override
//   String errorMessage = "";
//
//   @override
//   String idToken = "";
//
//   @override
//   String state = "";
//
//   @override
//   SignInResultStatus status;
// }

/// A more specific Exception which describes any potential native errors that occur within the Sign in with Social Sign in.
class SocialSignInFail extends SocialSignInResultInterface {
  SocialSignInFail({
    this.status = SignInResultStatus.failed,
    this.accessToken = "",
    this.idToken = "",
    this.errorMessage = "Unknown Fail!",
    this.state = "",
  });

  ///Application requests an access token from the social media server, extracts a token from the response, and sends the token to the Server API that you want to access.
  @override
  String accessToken;

  ///Handle Errors whose resolutions require more steps than can be easily described in an error message.
  @override
  String errorMessage;

  ///A JSON web token containing the user's identity information.
  @override
  String idToken;

  ///The current status of the authorization request.
  @override
  SignInResultStatus status;

  ///The current state of the authorization request.
  @override
  String state;
}
