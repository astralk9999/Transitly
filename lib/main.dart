import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';
import 'data/mock/mock_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preload fonts in the background; we don't block app start on this.
  unawaited(GoogleFonts.pendingFonts([
    GoogleFonts.ibmPlexMono(),
    GoogleFonts.dmSans(),
  ]));

  final mockData = await MockDataService.init();

  runApp(
    ProviderScope(
      overrides: [
        mockDataServiceProvider.overrideWithValue(mockData),
      ],
      child: const TransitlyApp(),
    ),
  );
}
