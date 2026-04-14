import 'package:flutter/material.dart';

class FilterPresetsScreen extends StatelessWidget {
  const FilterPresetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(
        child: Text('PANTALLA: FILTROS PREDEFINIDOS',
            style: TextStyle(color: Colors.white54, fontFamily: 'monospace')),
      ),
    );
  }
}
