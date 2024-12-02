library arcane_auth;

import 'package:arcane_auth/auth_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:serviced/serviced.dart';

export 'package:arcane_auth/auth_service.dart';

Future<void> onBind(UserMeta user) async {}

Future<void> onUnbind() async {}

Future<void> main() async {
  services().register(() => AuthService(onBind: onBind, onUnbind: onUnbind),
      lazy: false);
  await services().waitForStartup();
  runApp(Container());
}
