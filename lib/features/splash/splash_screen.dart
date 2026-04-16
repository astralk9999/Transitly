import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_animations.dart';
import '../../core/theme/transit_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final animate = TransitAnimations.shouldAnimate(context);
      if (animate) {
        _ctrl.forward();
      } else {
        _ctrl.value = 1.0;
      }
      Future.delayed(Duration(seconds: animate ? 2 : 0), () {
        if (mounted) context.go('/onboarding');
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TRANSITLY',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: c.accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'TU TRANSPORTE PÚBLICO',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: c.textLo,
                  letterSpacing: 0.15 * 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
