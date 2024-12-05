import 'package:arcane_auth/arcane_auth.dart';

///Configure Facebook Sign-in parameters required for web-based authentication flows.
class FacebookSignInConfig extends SocialSignInSiteConfig {
  @override
  SocialPlatform get site => SocialPlatform.facebook;

  ///The ID of your app, found in your app's dashboard.
  @override
  String clientId;

  @override
  String clientSecret;

  ///The URL that you want to redirect the person logging in back to.
  @override
  String redirectUrl;

  ///A list of permissions to request from the person using your app
  @override
  List<String> scope;

  /// Parameters required for web-based authentication flows
  FacebookSignInConfig({
    ///the Identifier value shown on the detail view of the service after opening
    ///it from social sign in console or developer
    required this.clientId,
    required this.clientSecret,
    required this.redirectUrl,
    this.scope = const ["email", "public_profile"],
  });
}
