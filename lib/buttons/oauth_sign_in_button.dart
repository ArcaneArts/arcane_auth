import 'package:arcane/arcane.dart';
import 'package:arcane_auth/arcane_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:serviced/serviced.dart';

class CredentialSignInButton extends StatelessWidget {
  final String? label;
  final VoidCallback onPressed;
  final Widget? icon;

  const CredentialSignInButton(
      {super.key, required this.onPressed, this.icon, required this.label});

  Future<void> signInWithCredential(AuthCredential credential) =>
      svc<AuthService>().signIn(credential);

  @override
  Widget build(BuildContext context) {
    Widget? le = icon;
    Widget ch;

    if (label != null) {
      ch = Text(label!);
    } else {
      ch = le ?? const SizedBox();
      le = null;
    }

    return OutlineButton(
      density: ButtonDensity.comfortable,
      onPressed: onPressed,
      leading: le,
      child: ch,
    );
  }
}
