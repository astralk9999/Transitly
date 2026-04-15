import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';

class SuggestionContributeScreen extends StatelessWidget {
  const SuggestionContributeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Center(
        child: Text('PANTALLA: CONTRIBUIR A SUGERENCIA',
            style: GoogleFonts.ibmPlexMono(color: c.textLo)),
      ),
    );
  }
}
