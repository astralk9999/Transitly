import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/transit_animations.dart';
import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../l10n/generated/app_localizations.dart';
import 'particles_painter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Duration _animDuration = Duration(milliseconds: 1600);
  static const Duration _holdAfterAnim = Duration(milliseconds: 400);

  late final AnimationController _mainCtrl;
  late final AnimationController _titleCtrl;
  late final AnimationController _particlesCtrl;
  late final AnimationController _glowPulseCtrl;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _glowFade;
  late final Animation<double> _glowScale;
  late final Animation<double> _subFade;
  late final Animation<Offset> _subSlide;

  late final List<Particle> _particles = generateParticles(40);
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(vsync: this, duration: _animDuration);
    _titleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _particlesCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8));
    _glowPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));

    _logoFade = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.0, 0.5, curve: TransitAnimations.transitEaseOut),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _glowFade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.7), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 0.35), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));
    _glowScale = Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: _mainCtrl, curve: Curves.easeInOut));

    _subFade = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.7, 1.0, curve: TransitAnimations.transitEaseOut),
    );
    _subSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(_subFade);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mainCtrl.status == AnimationStatus.dismissed) {
      _start();
    }
  }

  void _start() {
    if (TransitAnimations.shouldAnimate(context)) {
      _mainCtrl.forward();
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _titleCtrl.forward();
      });
      _particlesCtrl.repeat();
      _glowPulseCtrl.repeat(reverse: true);
    } else {
      _mainCtrl.value = 1.0;
      _titleCtrl.value = 1.0;
    }
    _navTimer = Timer(_animDuration + _holdAfterAnim, () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool('hasSeenOnboarding') ?? false;
      if (mounted) {
        context.go(hasSeen ? '/home/inicio' : '/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _mainCtrl.dispose();
    _titleCtrl.dispose();
    _particlesCtrl.dispose();
    _glowPulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              c.accent.withValues(alpha: 0.12),
              c.bgRoot,
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (TransitAnimations.shouldAnimate(context))
              AnimatedBuilder(
                animation: _particlesCtrl,
                builder: (_, __) => CustomPaint(
                  painter: ParticlesPainter(
                    progress: _particlesCtrl,
                    color: c.accent,
                    particles: _particles,
                  ),
                  size: Size.infinite,
                ),
              ),
            AnimatedBuilder(
              animation: _glowPulseCtrl,
              builder: (_, __) => FadeTransition(
                opacity: AlwaysStoppedAnimation(
                    0.35 + _glowPulseCtrl.value * 0.15),
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        c.accent.withValues(alpha: 0.35),
                        c.accent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: Semantics(
                      label: 'Transitly',
                      image: true,
                child: Image.asset(
                  isDark
                      ? 'assets/branding/transitly_logo_white_square.png'
                      : 'assets/branding/transitly_logo.png',
                  width: 280,
                  height: 280,
                  filterQuality: FilterQuality.high,
                ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _StaggeredTitle(
                  text: l10n.appTitle.toUpperCase(),
                  progress: _titleCtrl,
                  color: c.accent,
                ),
                const SizedBox(height: 12),
                SlideTransition(
                  position: _subSlide,
                  child: FadeTransition(
                    opacity: _subFade,
                    child: Text(
                      l10n.appTagline,
                      style: TransitTypography.bodySecondary(c.textMid),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StaggeredTitle extends StatelessWidget {
  const _StaggeredTitle({
    required this.text,
    required this.progress,
    required this.color,
  });

  final String text;
  final Animation<double> progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (_, __) {
        final letters = text.split('');
        final total = letters.length;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(total, (i) {
            final letterStart = i / total * 0.6;
            final letterEnd = letterStart + 0.4;
            final t = ((progress.value - letterStart) /
                    (letterEnd - letterStart))
                .clamp(0.0, 1.0);
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 8),
                child: Text(
                  letters[i],
                  style: TransitTypography.routeCode(color).copyWith(
                    fontSize: 36,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
