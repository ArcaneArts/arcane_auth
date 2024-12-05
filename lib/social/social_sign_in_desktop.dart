import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:arcane_auth/arcane_auth.dart';

/// An implementation of [SocialSignInPlatform] that uses method channels for desktop.
class SocialSignInDesktop extends SocialSignInPlatform {
  /// Registers this class instance of [SocialSignInPlatform].
  static void registerWith() {
    SocialSignInPlatform.instance = SocialSignInDesktop();
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
            if (Platform.isMacOS) {
              siteInfo = AppleSignIn.fromProfile(config);
            } else if (Platform.isWindows) {
              // throw UnsupportedError("Unsupported sign in with apple on windows.");
              siteInfo = AppleSignInWindows.fromProfile(config);
            }
          }
          break;
        case SocialPlatform.facebook:
          if (config is FacebookSignInConfig) {
            siteInfo = FacebookSignInDesktop.fromProfile(config);
          }
          break;
        case SocialPlatform.google:
          if (config is GoogleSignInConfig) {
            siteInfo = GoogleSignInDesktop.fromProfile(config);
          }
          break;
        case SocialPlatform.microsoft:
          if (config is MicrosoftSignInConfig) {
            siteInfo = MicrosoftSignInDesktop.fromProfile(config);
          }
          break;
        default:
          throw Exception("Unsupported social site of desktop!");
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

  ///Configure site information and trigger for desktop
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
