import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../shared/widgets/single_field_dialog.dart';
import '../../shared/widgets/smoke_background.dart';
import '../../shared/widgets/transit_button.dart';
import '../../shared/widgets/transit_input.dart';

class SuggestRouteScreen extends StatefulWidget {
  const SuggestRouteScreen({super.key});

  @override
  State<SuggestRouteScreen> createState() => _SuggestRouteScreenState();
}

class _SuggestRouteScreenState extends State<SuggestRouteScreen> {
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _operator = '';
  String _source = '';
  final List<TextEditingController> _stopCtrls = [];
  final List<String> _hours = [];

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _codeCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _stopCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          onPressed: () => context.pop(),
        ),
        title: Text('SUGERIR RUTA',
            style: TransitTypography.sectionTitle(c.textHi)),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: SmokeBackground(color: c.accent, isDark: isDark)),
          SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ayúdanos a completar el mapa de transporte',
              style: TransitTypography.bodySecondary(c.textMid),
            ),
            const SizedBox(height: 16),

            // From / To
            Text('Desde', style: TransitTypography.bodySecondary(c.textMid)),
            const SizedBox(height: 6),
            TransitInput(
              hint: 'Origen',
              controller: _fromCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text('Hasta', style: TransitTypography.bodySecondary(c.textMid)),
            const SizedBox(height: 6),
            TransitInput(
              hint: 'Destino',
              controller: _toCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // Operator chips
            Text('¿Operador?',
                style: TransitTypography.bodySecondary(c.textMid)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['COMUJESA', 'Otra', 'No lo sé'].map((op) {
                final selected = _operator == op;
                return GestureDetector(
                  onTap: () => setState(() => _operator = op),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? c.accentBg : c.bgRaised,
                      border: Border.all(
                        color: selected ? c.accent : c.border,
                        width: selected ? 1 : 0.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      op,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? c.accent : c.textMid,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Code
            Text('Código de línea',
                style: TransitTypography.bodySecondary(c.textMid)),
            const SizedBox(height: 6),
            TransitInput(hint: 'Ej: M-250', controller: _codeCtrl),
            const SizedBox(height: 20),

            // Source
            Text('¿Cómo lo sabes?',
                style: TransitTypography.bodySecondary(c.textMid)),
            const SizedBox(height: 8),
            ...['La uso', 'La he visto', 'Me lo dijeron', 'Web oficial']
                .map((opt) => GestureDetector(
                      onTap: () => setState(() => _source = opt),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _source == opt ? c.accent : c.textLo,
                                  width: 1.5,
                                ),
                              ),
                              child: _source == opt
                                  ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: c.accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text(opt,
                                style:
                                    TransitTypography.subheading(c.textHi)),
                          ],
                        ),
                      ),
                    )),
            const SizedBox(height: 16),

            // Expansion: more details
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Añadir más detalles',
                    style: TransitTypography.bodySecondary(c.accent)),
                iconColor: c.accent,
                collapsedIconColor: c.accent,
                children: [
                  // Stops
                  Text('Paradas que recuerdas',
                      style: TransitTypography.bodySecondary(c.textMid)),
                  const SizedBox(height: 8),
                  ..._stopCtrls.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: TransitInput(
                          hint: 'Parada ${e.key + 1}',
                          controller: e.value,
                        ),
                      )),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _stopCtrls.add(TextEditingController())),
                      child: Text('+ Añadir parada',
                          style: TransitTypography.bodySecondary(c.accent)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hours
                  Text('Horas que conoces',
                      style: TransitTypography.bodySecondary(c.textMid)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._hours.map((h) => Container(
                            width: 60,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.bgSurface,
                              border:
                                  Border.all(color: c.border, width: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(h,
                                style: GoogleFonts.ibmPlexMono(
                                    fontSize: 14, color: c.textHi)),
                          )),
                      GestureDetector(
                        onTap: () => _addHourDialog(c),
                        child: Container(
                          width: 60,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.bgSurface,
                            border:
                                Border.all(color: c.accent, width: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(Icons.add, size: 18, color: c.accent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  Text('Notas',
                      style: TransitTypography.bodySecondary(c.textMid)),
                  const SizedBox(height: 6),
                  TransitInput(
                    hint: 'Cualquier detalle adicional...',
                    controller: _notesCtrl,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              child: TransitButton(
                label: 'ENVIAR SUGERENCIA',
                onPressed:
                    _fromCtrl.text.isNotEmpty && _toCtrl.text.isNotEmpty
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Sugerencia enviada · Te avisaremos')),
                            );
                            context.pop();
                          }
                        : null,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
        ],
      ),
    );
  }

  Future<void> _addHourDialog(TransitColorScheme c) async {
    final hour = await showSingleFieldDialog(
      context,
      title: 'Añadir hora',
      hint: 'HH:MM',
      confirmLabel: 'AÑADIR',
    );
    if (hour != null && mounted) {
      setState(() {
        _hours
          ..add(hour)
          ..sort();
      });
    }
  }
}
