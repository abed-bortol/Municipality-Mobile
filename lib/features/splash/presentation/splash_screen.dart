import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:municipality/core/l10n/app_strings.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/brand_logo.dart';
import 'package:municipality/features/splash/presentation/app_startup_controller.dart';

/// Branded splash shown right after the native (OS) splash.
///
/// UX rules followed:
/// * Seamless hand-off: the first frame is identical to the native splash
///   (same background, same 96dp logo, same centered position), so there is
///   no flash or jump when Flutter takes over.
/// * No artificial waiting: it leaves as soon as startup work
///   ([AppStartupController]) is done and the short intro (~1.2s) has played,
///   so the name is readable. The router then moves on to sign-in or home.
/// * Feedback only when needed: a progress indicator appears only if loading
///   takes longer than 2 seconds.
/// * Accessible: honors "remove animations", announces the app name to
///   screen readers, and switches to Arabic + RTL on Arabic devices.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const logoSize = 96.0;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const _introDuration = Duration(milliseconds: 1200);
  static const _reducedMotionDuration = Duration(milliseconds: 600);
  static const _slowLoadThreshold = Duration(seconds: 2);

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: _introDuration);
  late final AnimationController _heartbeat = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));

  // Text block fades in and rises slightly under the logo.
  late final Animation<double> _textOpacity = CurvedAnimation(
      parent: _intro, curve: const Interval(0.15, 0.6, curve: Curves.easeOut));
  late final Animation<Offset> _textOffset = Tween(
    begin: const Offset(0, 0.25),
    end: Offset.zero,
  ).animate(CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.15, 0.7, curve: Curves.easeOutCubic)));
  late final Animation<double> _footerOpacity = CurvedAnimation(
      parent: _intro, curve: const Interval(0.45, 1, curve: Curves.easeOut));

  // "Lub-dub" heartbeat glow. Starts at 0 so frame 1 matches the native splash.
  late final Animation<double> _glow = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.3), weight: 12),
    TweenSequenceItem(tween: Tween(begin: 0.3, end: 0.8), weight: 12),
    TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.0), weight: 24),
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
  ]).animate(_heartbeat);

  Timer? _slowLoadTimer;
  bool _showProgress = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _start(reduceMotion: MediaQuery.disableAnimationsOf(context));
  }

  Future<void> _start({required bool reduceMotion}) async {
    if (reduceMotion) {
      _intro.value = 1;
    } else {
      _intro.forward();
      _heartbeat.repeat();
    }

    _slowLoadTimer = Timer(_slowLoadThreshold, () {
      if (mounted) setState(() => _showProgress = true);
    });

    // When this completes the router redirects away from the splash.
    await ref.read(appStartupControllerProvider.notifier).start(
          minDuration: reduceMotion ? _reducedMotionDuration : _introDuration,
        );
    _slowLoadTimer?.cancel();
  }

  @override
  void dispose() {
    _slowLoadTimer?.cancel();
    _intro.dispose();
    _heartbeat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final textTheme = Theme.of(context).textTheme;
    const logoSize = SplashScreen.logoSize;

    return Scaffold(
      backgroundColor: AppColors.slate900,
      body: Semantics(
        container: true,
        liveRegion: true,
        excludeSemantics: true,
        label: '${s.appTitle}. ${s.loading}',
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Logo is centered on the full window, exactly like the native splash.
            final textTop = constraints.maxHeight / 2 + logoSize / 2 + 28;

            return Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: AnimatedBuilder(
                    animation: _glow,
                    builder: (_, __) =>
                        BrandLogo(size: logoSize, glow: _glow.value),
                  ),
                ),
                Positioned(
                  top: textTop,
                  left: 32,
                  right: 32,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: SlideTransition(
                      position: _textOffset,
                      child: Column(
                        children: [
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) =>
                                AppColors.titleGradient.createShader(bounds),
                            child: Text(
                              s.appTitle,
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: s.isAr ? 0 : -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.appSubtitle,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.slate400,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: 24),
                    child: FadeTransition(
                      opacity: _footerOpacity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedOpacity(
                            opacity: _showProgress ? 1 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.teal400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '${s.municipality} • ${s.country}',
                            textAlign: TextAlign.center,
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.slate400,
                              fontWeight: FontWeight.w700,
                              letterSpacing: s.isAr ? 0 : 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
