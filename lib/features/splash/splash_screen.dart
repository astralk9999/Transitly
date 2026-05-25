import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/transit_animations.dart';
import '../../core/theme/transit_colors.dart';
import '../../l10n/generated/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _animDuration = Duration(milliseconds: 1400);
  static const Duration _holdAfterAnim = Duration(milliseconds: 400);

  late final AnimationController _ctrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(vsync: this, duration: _animDuration);

    _logoFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.55, curve: TransitAnimations.transitEaseOut),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(_logoFade);

    _titleFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 0.75, curve: TransitAnimations.transitEaseOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(_titleFade);

    _subtitleFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.55, 0.9, curve: TransitAnimations.transitEaseOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ctrl.status == AnimationStatus.dismissed) {
      _start();
    }
  }

  void _start() {
    if (TransitAnimations.shouldAnimate(context)) {
      _ctrl.forward();
    } else {
      _ctrl.value = 1.0;
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
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Semantics(
                    label: 'Transitly',
                    image: true,
                    child: Image.asset(
                      isDark
                          ? 'assets/branding/transitly_logo.png'
                          : 'assets/branding/transitly_logo_white.png',
                      width: 160,
                      height: 160,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _titleFade,
                child: SlideTransition(
                  position: _titleSlide,
                  child: Text(
                      AppLocalizations.of(context).appTitle.toUpperCase(),
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: c.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeTransition(
                opacity: _subtitleFade,
                child: Text(
                      AppLocalizations.of(context).appTagline,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: c.textMid,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
