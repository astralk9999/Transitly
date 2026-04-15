import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';

class SuggestionDetailScreen extends StatelessWidget {
  const SuggestionDetailScreen({super.key, required this.suggestionId});

  final String suggestionId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Center(
        child: Text('PANTALLA: DETALLE SUGERENCIA $suggestionId',
            style: GoogleFonts.ibmPlexMono(color: c.textLo)),
      ),
    );
  }
}
