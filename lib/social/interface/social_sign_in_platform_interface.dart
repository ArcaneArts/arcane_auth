import 'package:flutter/cupertino.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:arcane_auth/arcane_auth.dart';

/// PlatformInterface : Base class for platform interfaces
/// Provides a static helper method for ensuring that platform interfaces are implemented using
/// extends instead of implements.
/// The interface that implementations of [SocialSignInDesktop] and [SocialSignInMobile]
/// for social sign in.
abstract class SocialSignInPlatform extends PlatformInterface {
  /// Constructs a SocialSignInPlatform.
  SocialSignInPlatform() : super(token: _token);

  static final Object _token = Object();

  static SocialSignInPlatform _instance = SocialSignInMobile();

  /// The default instance of [SocialSignInPlatform] to use.
  ///
  /// Defaults to [SocialSignInMobile].
  static SocialSignInPlatform get instance => _instance;

  static final Map<SocialPlatform, SocialSignInSite> _siteList = {};

  /// Identify the platform being used.
  static SocialSignInSite? getSite(SocialPlatform site) => _siteList[site];
  static void setSite(SocialPlatform site, SocialSignInSite data) =>
      _siteList[site] = data;

  static SocialSignInSite? lastSite;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SocialSignInPlatform] when
  /// they register themselves.
  static set instance(SocialSignInPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the credentials state for a given user by SocialSignInResultInterface
  /// Get the credentials and authorization of social login,
  /// it will convert an authorization code obtained via Social sign
  /// into a session in your system.
  /// Throw exception when errors happen.
  Future<SocialSignInResultInterface> signInSite(
      SocialPlatform site, BuildContext context) async {
    throw UnimplementedError('signIn() has not been implemented.');
  }

  ///Configure and direct login.
  ///An SocialSignInFail which will be thrown if exceptions happen,
  ///a more specific reason will show in [errorMessage]
  Future<SocialSignInResultInterface> signIn(BuildContext context) async {
    try {
      if (lastSite == null)
        return SocialSignInFail(errorMessage: "Uninitialized site");
      return await lastSite!.signIn(context);
    } catch (e) {
      if (e is SocialSignInException) {
        return SocialSignInFail(status: e.status, errorMessage: e.description);
      } else {
        return SocialSignInFail(errorMessage: e.toString());
      }
    }
  }

  //Configure the instance
  void initialSite(
      SocialSignInSiteConfig config, SocialSignInPageInfo pageInfo) {
    throw UnimplementedError('initialSite() has not been implemented.');
  }
}
