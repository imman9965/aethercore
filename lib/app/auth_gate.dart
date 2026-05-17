import 'package:flutter/material.dart';

import '../core/errors/failures.dart';
import '../core/result/result.dart';
import '../di/injector.dart';
import '../features/auth/domain/entities/auth_user.dart';
import '../widgets/brand_mark.dart';
import '../widgets/splash_screen_scaffold.dart';
import 'home_screen.dart';

/// Gates the app on anonymous sign-in. Every screen below has a valid
/// [AuthUser.uid] to attribute writes to.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.injector});

  final Injector injector;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<Result<AuthUser>> _signInFuture;

  @override
  void initState() {
    super.initState();
    _signInFuture = widget.injector.ensureSignedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<AuthUser>>(
      future: _signInFuture,
      builder:
          (BuildContext context, AsyncSnapshot<Result<AuthUser>> snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SplashScaffold(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    BrandMark(),
                    SizedBox(height: 28),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Connecting to the realm...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              );
            }
            final Result<AuthUser>? result = snapshot.data;
            if (result == null) {
              return const SplashScaffold(
                child: Text(
                  'No sign-in result. Restart the app.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            return result.when(
              ok: (AuthUser user) =>
                  HomeScreen(injector: widget.injector, userId: user.uid),
              err: (AppFailure failure) => SplashScaffold(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _explain(failure),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            );
          },
    );
  }

  String _explain(AppFailure failure) {
    return switch (failure) {
      AuthenticationFailure(message: final m) => 'Sign-in failed: $m',
      InfrastructureFailure(message: final m) => 'Network error: $m',
      NotFoundFailure(resource: final r) => 'Missing resource: $r',
      ValidationFailure(reason: final r) => 'Validation: $r',
      UnknownFailure() => 'Unexpected error.',
    };
  }
}
