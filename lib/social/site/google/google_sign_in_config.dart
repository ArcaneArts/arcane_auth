import 'package:arcane_auth/arcane_auth.dart';

///Configure Google Sign-in parameters required for web-based authentication flows.
class GoogleSignInConfig extends SocialSignInSiteConfig {
  @override
  SocialPlatform get site => SocialPlatform.google;

  ///The client ID for your application. You can find this value in the API console [Credentials page](console.cloud.google.com/apis/credentials)
  @override
  String clientId;

  @override
  String clientSecret;

  ///Determines where the API server redirects the user after the user completes the authorization flow.
  @override
  String redirectUrl;

  ///A space-delimited list of scopes that identify the resources that your application could access on the user's behalf.
  @override
  List<String> scope;

  /// Parameters required for web-based authentication flows
  GoogleSignInConfig(
      {
      ///the Identifier value shown on the detail view of the service after opening
      ///it from social sign in console or developer
      required this.clientId,
      required this.clientSecret,
      required this.redirectUrl,
      this.scope = const ["profile", "email"]});
}
