import 'dart:convert';

import 'package:arcane/arcane.dart';
import 'package:arcane_auth/arcane_auth.dart';
import 'dart:math' as math;

import 'package:http/http.dart';

abstract class SocialSignInPageInfo {
  ///A browser parameter used for recording purposes by the respective website.
  String? get userAgent;

  ///Indicating whether to clear the webpage cache
  bool get clearCache => true;

  ///The heading of the embedded page
  String get title => "";

  ///Indicating whether to center the heading
  bool? get centerTitle;
}

String _getRandomString(int length, String charset) {
  final random = math.Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)])
      .join();
}

///The parameters used after opening the login page of a social media platform.
class DefaultSignInPageInfo extends SocialSignInPageInfo {
  @override
  String title;
  @override
  bool? centerTitle;
  @override
  String? userAgent;
  @override
  bool clearCache;

  DefaultSignInPageInfo({
    this.title = "",
    this.centerTitle,
    this.clearCache = true,
    this.userAgent,
  });
}

/// Configure site information
abstract class SocialSignInSiteConfig {
  SocialPlatform get site;
  String get clientId;
  set clientId(String value);
  String get clientSecret;
  set clientSecret(String value);
  String get redirectUrl;
  set redirectUrl(String value);
  List<String> get scope;
  set scope(List<String> value);
}

/// Authorization details from the login flow
abstract class SocialSignInResultInterface {
  ///Application requests an access token from the social media server, extracts a token from the response, and sends the token to the Server API that you want to access.
  set accessToken(String value);
  String get accessToken;

  ///A JSON web token containing the user's identity information.
  set idToken(String value);
  String get idToken;

  ///The current status of the authorization request.
  set status(SignInResultStatus value);
  SignInResultStatus get status;

  ///Handle Errors whose resolutions require more steps than can be easily described in an error message.
  set errorMessage(String value);
  String get errorMessage;

  ///The current state of the authorization request.
  set state(String value);
  String get state;
}

/// Constructor for sign in
abstract class SocialSignInSite {
  String get clientId;
  set clientId(String value);
  String get clientSecret;
  set clientSecret(String value);
  String get redirectUrl;
  set redirectUrl(String value);
  String get scope;
  set scope(String value);
  SocialSignInPageInfo get pageInfo;
  set pageInfo(SocialSignInPageInfo value);
  late String stateCode;

  String? customStateCode() => null;
  String authUrl();
  String generateString(
          [int length = 32,
          String charset =
              'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890']) =>
      _getRandomString(length, charset);
  String generateNonce([int length = 32]) => _getRandomString(length,
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._');

  @protected
  Future<dynamic> signInWithWebView(BuildContext context) async {
    throw UnimplementedError('signInWithWebView() has not been implemented.');
  }

  ///To exchange an authorization code for an access token
  @protected
  Future<SocialSignInResultInterface> exchangeAccessToken(
      String authorizationCode) async {
    throw UnimplementedError('exchangeAccessToken() has not been implemented.');
  }

  ///Default signIn with webView flow
  Future<SocialSignInResultInterface> signIn(BuildContext context) async {
    stateCode = customStateCode() ?? generateString(10); // simple state code
    debugPrint("stateCode = $stateCode");

    var authorizedResult = await signInWithWebView(context);
    if (authorizedResult == null ||
        authorizedResult.toString().contains('access_denied')) {
      throw SocialSignInException(
          status: SignInResultStatus.cancelled,
          description: "Sign In attempt has been cancelled.");
    } else if (authorizedResult is Exception) {
      throw SocialSignInException(description: authorizedResult.toString());
    }
    String authorizedCode = authorizedResult;
    debugPrint("authorized_code: $authorizedCode");
    return await exchangeAccessToken(authorizedCode);
  }

  ///The error will be thrown when the token exchange fails.
  Exception handleResponseBodyFail(Map<String, dynamic> body) {
    if (body.containsKey("error")) {
      return SocialSignInException(
          description:
              "Unable to obtain token. Received: ${body["error_description"]}");
    } else {
      return SocialSignInException(description: "Unknown fail");
    }
  }

  ///The error will be thrown when the token exchange fails.
  Exception handleUnSuccessCodeFail(Response response) {
    var body =
        json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (body.containsKey("error")) {
      return SocialSignInException(
          description:
              "Unable to obtain token. Received: ${body["error_description"]}");
    } else {
      return SocialSignInException(
          description:
              "Unable to obtain token. Received: ${response.statusCode}");
    }
  }
}
