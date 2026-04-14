import 'package:flutter/material.dart';

class SearchTab extends StatelessWidget {
  const SearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(
        child: Text('PANTALLA: BUSCAR',
            style: TextStyle(color: Colors.white54, fontFamily: 'monospace')),
      ),
    );
  }
}
