import 'package:flutter/material.dart';
import 'core/theme/transit_colors.dart';
import 'core/theme/transit_theme.dart';
import 'core/theme/transit_typography.dart';

class TransitlyApp extends StatelessWidget {
  const TransitlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transitly',
      debugShowCheckedModeBanner: false,
      theme: TransitTheme.dark,
      home: const TransitlyHome(),
    );
  }
}

class TransitlyHome extends StatelessWidget {
  const TransitlyHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TransitColors.background,
      body: Center(
        child: Text(
          'TRANSITLY',
          style: TransitTypography.mono(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: TransitColors.signalGreen,
          ),
        ),
      ),
    );
  }
}
