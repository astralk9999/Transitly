import 'package:flutter/material.dart';

class CardTab extends StatelessWidget {
  const CardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(
        child: Text('PANTALLA: TARJETA',
            style: TextStyle(color: Colors.white54, fontFamily: 'monospace')),
      ),
    );
  }
}
