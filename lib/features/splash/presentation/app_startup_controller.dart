import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_startup_controller.g.dart';

/// True once startup work is done AND the splash intro has played.
/// The router keeps the user on the splash until then.
@Riverpod(keepAlive: true)
class AppStartupController extends _$AppStartupController {
  @override
  bool build() => false;

  /// Runs startup work (restore session, ...) for at least [minDuration].
  /// Never adds waiting beyond that: no artificial delays.
  Future<void> start({required Duration minDuration}) async {
    try {
      await Future.wait([
        ref.read(authControllerProvider.future),
        Future<void>.delayed(minDuration),
      ]);
    } on Object {
      // Restoring failed unexpectedly: continue to sign-in rather than
      // trapping the user on the splash. The router treats it as signed out.
    }
    state = true;
  }
}
