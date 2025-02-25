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
  const GithubLogo({Key? key, this.size = 18}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.logo_github_ionic,
      size: size,
      color: Theme.of(context).colorScheme.mutedForeground,
    );
  }
}
