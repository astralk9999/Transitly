import 'package:flutter/material.dart';

class SuggestionDetailScreen extends StatelessWidget {
  const SuggestionDetailScreen({super.key, required this.suggestionId});

  final String suggestionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Text('PANTALLA: DETALLE SUGERENCIA $suggestionId',
            style: const TextStyle(
                color: Colors.white54, fontFamily: 'monospace')),
      ),
    );
  }
}
