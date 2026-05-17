import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../core/theme/transit_typography.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_button.dart';

/// Importador de horarios: el conductor pega el texto de un horario
/// (web del operador, PDF copiado, etc.) y la pantalla extrae las horas
/// de salida.
///
/// NOTA: el análisis es un parser local heurístico (regex `HH:MM`), no
/// un modelo de IA ni una llamada de backend. La integración con un
/// servicio de extracción real es trabajo futuro.
class AiScheduleImport extends StatefulWidget {
  const AiScheduleImport({super.key});

  @override
  State<AiScheduleImport> createState() => _AiScheduleImportState();
}

class _AiScheduleImportState extends State<AiScheduleImport> {
  final _controller = TextEditingController();
  List<String> _times = const [];
  bool _parsed = false;

  static final _timeRe = RegExp(r'\b([01]?\d|2[0-3])[:.]([0-5]\d)\b');

  void _parse() {
    final raw = _controller.text;
    final found = <String>{};
    for (final m in _timeRe.allMatches(raw)) {
      final h = m.group(1)!.padLeft(2, '0');
      final min = m.group(2)!;
      found.add('$h:$min');
    }
    final list = found.toList()..sort();
    setState(() {
      _times = list;
      _parsed = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TransitAppBar(title: 'Importar horario'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(TransitSpacing.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(TransitSpacing.space12),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Pega el horario y se extraerán las horas de salida. '
                      'El análisis es local (demo): detecta patrones HH:MM, '
                      'no usa IA ni backend.',
                      style: TransitTypography.bodySecondary(c.textMid),
                    ),
                  ),
                  const SizedBox(height: TransitSpacing.space16),
                  TextField(
                    controller: _controller,
                    maxLines: 8,
                    style: TransitTypography.bodyPrimary(c.textHi),
                    decoration: InputDecoration(
                      hintText: 'Ej.: 06:00  06:30  07:00 ...',
                      hintStyle: TransitTypography.bodySecondary(c.textLo),
                      filled: true,
                      fillColor: c.bgSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.border, width: 0.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.border, width: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: TransitSpacing.space16),
                  TransitButton(
                    label: 'ANALIZAR',
                    onPressed: _controller.text.trim().isEmpty ? null : _parse,
                  ),
                  const SizedBox(height: TransitSpacing.space24),
                  if (_parsed) ...[
                    Text(
                      _times.isEmpty
                          ? 'No se detectaron horas'
                          : '${_times.length} salidas detectadas',
                      style: TransitTypography.sectionTitle(c.textHi),
                    ),
                    const SizedBox(height: TransitSpacing.space12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in _times)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: c.bgSurface,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: c.border, width: 0.5),
                            ),
                            child: Text(t,
                                style:
                                    TransitTypography.bodyPrimary(c.textHi)),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
