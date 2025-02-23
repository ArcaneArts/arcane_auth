import 'package:arcane_auth/arcane_auth.dart';

/// Configure GitHub Sign-in parameters required for web-based authentication flows.
class GitHubSignInConfig extends SocialSignInSiteConfig {
  @override
  SocialPlatform get site => SocialPlatform.github;

  /// The client ID for your GitHub OAuth application
  @override
  String clientId;

  /// The client secret for your GitHub OAuth application
  @override
  String clientSecret;

  /// The URL that GitHub will redirect to after authorization
  @override
  String redirectUrl;

  /// The scopes needed for GitHub authentication
  @override
  List<String> scope;

  /// Parameters required for web-based authentication flows
  GitHubSignInConfig({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUrl,
    this.scope = const ["read:user", "user:email"],
  });
}
