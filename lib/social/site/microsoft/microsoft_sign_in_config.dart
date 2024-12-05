import 'package:arcane_auth/arcane_auth.dart';

///Configure Microsoft Sign-in parameters required for web-based authentication flows.
class MicrosoftSignInConfig extends SocialSignInSiteConfig {
  @override
  SocialPlatform get site => SocialPlatform.microsoft;

  ///Application ID created in Azure Portal
  @override
  String clientId;

  @override
  String clientSecret;

  @override
  String redirectUrl;

  @override
  List<String> scope;

  /// Parameters required for web-based authentication flows
  MicrosoftSignInConfig(
      {
      ///This is the Identifier value shown on the detail view of the service after opening
      ///it from social sign in console or developer.
      required this.clientId,
      required this.clientSecret,
      required this.redirectUrl,
      this.scope = const ["user.read"]});
}
