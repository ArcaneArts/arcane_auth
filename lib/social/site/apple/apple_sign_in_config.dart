import 'package:arcane_auth/arcane_auth.dart';

///Configure Apple Sign-in parameters required for web-based authentication flows.
class AppleSignInConfig extends SocialSignInSiteConfig {
  @override
  SocialPlatform get site => SocialPlatform.apple;

  ///The developer's client identifier, as provided by WWDR (Worldwide Developer Relations)
  @override
  String clientId;

  @override
  String clientSecret = "";

  ///The URI to which the authorization redirects. It must include a domain name, and can't be an IP address or localhost.
  @override
  String redirectUrl;

  /// Host url for windows.
  String hostUrl;

  ///The amount of user information requested from Apple. Valid values are named and email. You can request one, both, or none.
  @override
  List<String> scope;

  /// Parameters required for web-based authentication flows
  AppleSignInConfig({
    ///The Identifier value shown on the detail view of the service after opening
    ///it from social sign in console or developer
    required this.clientId,
    required this.redirectUrl,
    this.hostUrl = "",
    this.scope = const ["name", "email"],
  });
}
