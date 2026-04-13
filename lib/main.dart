import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preload fonts
  GoogleFonts.pendingFonts([
    GoogleFonts.ibmPlexMono(),
    GoogleFonts.dmSans(),
  ]);

  runApp(
    const ProviderScope(
      child: TransitlyApp(),
    ),
  );
}
