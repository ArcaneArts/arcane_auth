import 'package:flutter/cupertino.dart';
import 'package:arcane_auth/arcane_auth.dart';

/// An implementation of [SocialSignInPlatform] that uses method channels for mobile.
class SocialSignInMobile extends SocialSignInPlatform {
  /// Registers this class as the default instance of [SocialSignInPlatform].
  static void registerWith() {
    SocialSignInPlatform.instance = SocialSignInMobile();
  }

  ///Configure the instance
  @override
  void initialSite(
      SocialSignInSiteConfig config, SocialSignInPageInfo pageInfo) {
    try {
      SocialSignInSite? siteInfo;
      switch (config.site) {
        case SocialPlatform.apple:
          if (config is AppleSignInConfig) {
            siteInfo = AppleSignIn.fromProfile(config);
          }
          break;
        case SocialPlatform.facebook:
          if (config is FacebookSignInConfig) {
            siteInfo = FacebookSignIn.fromProfile(config);
          }
          break;
        case SocialPlatform.google:
          if (config is GoogleSignInConfig) {
            siteInfo = GoogleSignIn.fromProfile(config);
          }
          break;
        case SocialPlatform.microsoft:
          if (config is MicrosoftSignInConfig) {
            siteInfo = MicrosoftSignIn.fromProfile(config);
          }
          break;
        default:
          throw Exception("Unsupported social site!");
      }
      if (siteInfo == null) {
        throw Exception("Site config miss match!");
      }
      siteInfo.pageInfo = pageInfo;
      SocialSignInPlatform.lastSite = siteInfo;
      SocialSignInPlatform.setSite(config.site, siteInfo);
    } catch (e) {
      rethrow;
    }
  }

  ///Configure site information and trigger for mobile
  @override
  Future<SocialSignInResultInterface> signInSite(
      SocialPlatform site, BuildContext context) async {
    try {
      var socialSite = SocialSignInPlatform.getSite(site);
      if (socialSite == null)
        return SocialSignInFail(errorMessage: "Uninitialized site");
      return await socialSite.signIn(context);
    } catch (e) {
      if (e is SocialSignInException) {
        return SocialSignInFail(status: e.status, errorMessage: e.description);
      } else {
        return SocialSignInFail(errorMessage: e.toString());
      }
    }
  }
}
