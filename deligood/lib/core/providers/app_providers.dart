import 'package:deligood/features/auth/providers/auth_state.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Tous les providers globaux de l'application sont centralis?s ici.
class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>.value(value: AuthState.instance),
      ],
      child: child,
    );
  }
}
