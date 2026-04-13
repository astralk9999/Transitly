import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/transit_colors.dart';
import 'core/theme/transit_theme.dart';
import 'core/theme/transit_typography.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

class TransitlyApp extends ConsumerWidget {
  const TransitlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Transitly',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: buildTransitTheme(false),
      darkTheme: buildTransitTheme(true),
      home: const TransitlyHome(),
    );
  }
}

class TransitlyHome extends StatelessWidget {
  const TransitlyHome({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      body: Center(
        child: Text(
          'TRANSITLY',
          style: TransitTypography.displayTime(c.accent),
        ),
      ),
    );
  }
}
