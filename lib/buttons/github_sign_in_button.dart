import 'package:arcane/arcane.dart';
import 'package:arcane_auth/arcane_auth.dart';

class GithubSignInButton extends StatelessWidget {
  final Widget? icon;
  final String? label;

  const GithubSignInButton({
    Key? key,
    this.icon = const GithubLogo(),
    this.label = "GitHub",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CredentialSignInButton(
      label: label,
      icon: icon,
      onPressed: () => context
          .pylon<ArcaneAuthProvider>()
          .signInWithProvider(context, ArcaneSignInProviderType.github),
    );
  }
}

class GithubLogo extends StatelessWidget {
  final double size;
  const GithubLogo({Key? key, this.size = 14}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Using FontAwesome GitHub icon (a monochrome GitHub logo, it's the squid thing.)
    return Icon(FontAwesomeIcons.github, size: size);
  }
}
