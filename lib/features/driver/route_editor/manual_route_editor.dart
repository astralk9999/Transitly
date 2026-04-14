import 'package:flutter/material.dart';

class ManualRouteEditor extends StatelessWidget {
  const ManualRouteEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(
        child: Text('PANTALLA: EDITOR MANUAL DE RUTA',
            style: TextStyle(color: Colors.white54, fontFamily: 'monospace')),
      ),
    );
  }
}
