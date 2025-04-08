# arcane_auth

A Flutter package for authenticating with firebase_auth providers using the arcane package for UI.
 
|             | Web           | iOS                | Android        | MacOS              | Windows       |
|-------------|---------------|--------------------|----------------|--------------------|---------------|
| Anonymous   | firebase_auth | firebase_auth      | firebase_auth  | firebase_auth      | firebase_auth |
| Email       | firebase_auth | firebase_auth      | firebase_auth  | firebase_auth      | firebase_auth |
| Email Link  | NYI           | NYI                | NYI            | NYI                | NYI           |
| Phone       | NYI           | NYI                | NYI            | NYI                | NYI           |
| Google      | firebase_auth | google_sign_in     | google_sign_in | google_sign_in     | arcane_auth   |
| Apple       | NYI           | sign_in_with_apple | NYI            | sign_in_with_apple | NYI           |
| Facebook    | firebase_auth | arcane_auth        | arcane_auth    | arcane_auth        | arcane_auth   |
| Microsoft   | firebase_auth | arcane_auth        | arcane_auth    | arcane_auth        | arcane_auth   |
| Github      | firebase_auth | arcane_auth        | arcane_auth    | arcane_auth        | arcane_auth   |
| Yahoo       | NYI           | NYI                | NYI            | NYI                | NYI           |
| X           | NYI           | NYI                | NYI            | NYI                | NYI           |
| Play Games  | NYI           | NYI                | NYI            | NYI                | NYI           |
| Game Center | NYI           | NYI                | NYI            | NYI                | NYI           |
| OpenID      | NYI           | NYI                | NYI            | NYI                | NYI           |
| SAML        | NYI           | NYI                | NYI            | NYI                | NYI           |

## Setup

### Apple
Currently only IOS and MacOS are easily supported for Apple Sign In which do not require any setup. There is a way to get it to work on windows / android / web, see [here](https://pub.dev/packages/social_sign_in#sign-in-with-apple)

### Google
1. Head to [https://console.cloud.google.com/apis/credentials](https://console.cloud.google.com/apis/credentials)
2. Under `OAuth 2.0 Client IDs` click on Web client (auto created by Google Service)
3. Set `Authorized redirect URIs` url to `https://[YOUR FIREBASE PROJECT ID].firebaseapp.com/__/auth/handler`
4. Under `Additional information` you will find your `Client ID` which is needed for the provider
5. Under `Client Secrets` you will find your `Client Secret` which is needed for the provider

### Microsoft
1. Login Azure portal and click Azure Active Directory, and then, in the navigation panel, click App registrations to register an application.
2. Enter your Application Name and pick Accounts in any organizational directory (Any Azure AD directory - Multitenant) and personal Microsoft accounts(eg. Skype, Xbox) to allow for Sign-in from both organization and public accounts.
3. Choose Web as the Redirect URI and enter the Redirect URI in Firebase Console under Authentication > Sign-In Method > Enable Microsoft provider.
4. Add new client secret in Certificates and secrets. & copy the VALUE not the secret id. That is the secret to use
5. Specify your app's Client ID, Client Secret you just created in the project.
6. Plug these values into the microsoft provider on both firebase and a sign in config in main

### Facebook
1. Start the app creation process in Meta for Developers.
2. Choose a use case which determines permissions, products and APIs are available to your app.
3. Set your app name and email.
4. Specify your app's Client ID, Client Secret you just created in the project .

### Auth Setup

First add arcane auth if you haven't `flutter pub add arcane_auth`

Then in your app, you can use the `AuthenticatedArcaneApp` to handle dual app states. 
If the user is not signed in, a different app with the same style / properties will be used
with a single home of the login screen. The second they are authenticated it switches back
to your app with the home screen / routes you have.

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  // Use an AuthenticatedArcaneApp instead of ArcaneApp
  @override
  Widget build(BuildContext context) => AuthenticatedArcaneApp(
    
    // Define auth config
    authConfig: AuthConfig(
      // Define what auth methods you want to support
      authMethods: [AuthMethod.emailPassword, AuthMethod.google],
      
      // Should we allow anonymous logins
      allowAnonymous: false,
      
      // When signing into a google account, link it to existing emailpass account
      // for example.
      autoLink: true,
      signInConfigs: [
        // Add the sign in providers you would like to use
        // Not all auth methods need sign in configs.
        GoogleSignInConfig(
            clientId:
            "CLIENT-ID.apps.googleusercontent.com",
            clientSecret: "CLIENT-SECRET",
            redirectUrl: "https://YOURAPP.firebaseapp.com/__/auth/handler")
      ],
    
      // This is called when the user is signed in, you can use this to 
      // subscribe to user data or initialize stuff for that user
      onBind: (s) async {
        print("BOUND ${s}");
      },
    
      // This is called when the user is signed out or before the next sign in
      // you can use this to unsubscribe from user data or clean up stuff
      onUnbind: () async {
        print("UNBOUND");
      },
      
      // Define the screen that will be shown when the user is not signed in
      loginScreenBuilder: (context, buttons) => LoginScreen(
        loginButtons: buttons,
        header: Text("My Cool App").x9Large(),

        // If you want to allow email/password sign in enable this
        allowEmailPassword: true,

        // Match this with your firebase password policy 
        // Defaults to the default firebase password policy
        passwordPolicy: ArcanePasswordPolicy(
          maxPasswordLength: 4096,
          minPasswordLength: 6,
          requireLowercaseLetter: false,
          requireNumericCharacter: false,
          requireSpecialCharacter: false,
          requireUppercaseLetter: false,
        ),
      ),
    ),
    title: 'My App',
    home: HomeScreen(),
    theme: ArcaneTheme(
        scheme: ContrastedColorScheme.fromScheme(ColorSchemes.zinc),
        radius: 0.5,
        surfaceOpacity: 0.66,
        surfaceBlur: 18,
        themeMode: ThemeMode.system),
  );
}

// This widget is only built when the user is signed in
// It is impossible to see this screen or any other routes if the user is not signed in
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => FillScreen(
      child: OutlineButton(
        child: Text("Home (tap to sign out)"),
        onPressed: () => svc<AuthService>().signOut(),
      ));
}

```

## Utilities

There are several actions & utilities you can use

```dart
import 'package:arcane_auth/arcane_auth.dart';

// This is always true if allowAnonymous is enabled
bool isSignedIn = $signedIn;

// The uid is never null if allowAnonymous is enabled
String userID = $uid ?? "not-logged-in";

// This is always false if allowAnonymous is disabled
// This is only true if the signed in user is signed in anonymously
bool isAnonymous = $anonymous;
```