# arcane_auth

A Flutter package for authenticating with firebase_auth providers using the arcane package for UI.

## Setup

First add arcane auth if you haven't `flutter pub add arcane_auth`

Then in your main, setup arcane_auth

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(...);
  
  // After initializing firebase, setup arcane_auth
  initArcaneAuth();
  
  // Register your services here
  services().register<MyService>(() => MyService());
  services().register<MyService2>(() => MyService2());
  ...

  // Finally wait for everything to come online
  await services().waitForStartup();
  
  // Run your app
  runApp(MyApp());
}
```

## Usage

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