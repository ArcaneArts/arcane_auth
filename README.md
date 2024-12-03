# arcane_auth

A Flutter package for authenticating with firebase_auth providers using the arcane package for UI.

## Setup

First add arcane auth if you haven't `flutter pub add arcane_auth`

Then in your main, setup arcane_auth

```dart
Future<void> main() async {
  // ensure widgets binding is initialized and setup firebase first
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // init arcane auth
  initArcaneAuth(
    
      // If you intend to use google sign in on windows, you must provide the client id
      googleClientID:
      "CLIENTID.apps.googleusercontent.com",
      
      // If you intend to use google sign in on windows, you must provide the redirect uri
      googleRedirectURI:
      "https://YOURAPP.firebaseapp.com/__/auth/handler",
      
      // This is called when the user is signed in, you can use this to 
      // subscribe to user data or initialize stuff for that user
      onBind: (s) async {
        print("BOUND ${s}");
      },
      
      // This is called when the user is signed out or before the next sign in
      // you can use this to unsubscribe from user data or clean up stuff
      onUnbind: () async {
        print("UNBOUND");
      });
  
  // wait for services to start up
  await services().waitForStartup();
  
  // Finally run your app
  runApp(MyApp());
}
```

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
    // Define the sign in providers you would like to use
    loginButtons: [
      GoogleSignInButton(),
      AppleSignInButton(),
    ],
    
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