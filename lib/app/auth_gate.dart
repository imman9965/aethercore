import 'package:flutter/material.dart';

import '../core/errors/failures.dart';
import '../core/result/result.dart';
import '../di/injector.dart';
import '../features/auth/domain/entities/auth_user.dart';
import 'app.dart';
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
      builder: (BuildContext context,
          AsyncSnapshot<Result<AuthUser>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SplashScaffold(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _BrandMark(),
                SizedBox(height: 28),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
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
          return const _SplashScaffold(
            child: Text(
              'No sign-in result. Restart the app.',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        return result.when(
          ok: (AuthUser user) => HomeScreen(
            injector: widget.injector,
            userId: user.uid,
          ),
          err: (AppFailure failure) => _SplashScaffold(
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

class _SplashScaffold extends StatelessWidget {
  const _SplashScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF0B3D91),
              Color(0xFF1565C0),
              Color(0xFF1E88E5),
            ],
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withValues(alpha: 0.18),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.bolt_rounded,
              color: AetherApp.kAccentCyan, size: 24),
        ),
        const SizedBox(width: 12),
        const Text(
          'AetherCore',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
