import 'package:flutter/material.dart';

class ReportIncidentSheet extends StatelessWidget {
  const ReportIncidentSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: Text('PANEL: REPORTAR INCIDENCIA',
            style: TextStyle(color: Colors.white54, fontFamily: 'monospace')),
      ),
    );
  }
}
