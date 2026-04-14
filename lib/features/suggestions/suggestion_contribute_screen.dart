import 'package:flutter/material.dart';

class SuggestionContributeScreen extends StatelessWidget {
  const SuggestionContributeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(
        child: Text('PANTALLA: CONTRIBUIR SUGERENCIA',
            style: TextStyle(color: Colors.white54, fontFamily: 'monospace')),
      ),
    );
  }
}
