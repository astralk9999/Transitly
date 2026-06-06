import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/transit_colors.dart';
import '../../../../core/theme/transit_typography.dart';
import '../../../../shared/widgets/transit_input.dart';

/// Pre-recording form: route code, name, service type, and "start" button.
class RecorderPreForm extends StatelessWidget {
  const RecorderPreForm({
    super.key,
    required this.c,
    required this.isDark,
    required this.codeCtrl,
    required this.nameCtrl,
    required this.serviceType,
    required this.onServiceTypeChanged,
    required this.onStart,
  });

  final TransitColorScheme c;
  final bool isDark;
  final TextEditingController codeCtrl;
  final TextEditingController nameCtrl;
  final String serviceType;
  final ValueChanged<String> onServiceTypeChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          tooltip: 'Volver',
          onPressed: () => context.pop(),
        ),
        title: Text('GRABAR RUTA',
            style: TransitTypography.sectionTitle(c.textHi)),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Código',
                    style: TransitTypography.bodySecondary(c.textMid)),
                const SizedBox(height: 6),
                TransitInput(hint: 'Ej: L12', controller: codeCtrl),
                const SizedBox(height: 16),
                Text('Nombre',
                    style: TransitTypography.bodySecondary(c.textMid)),
                const SizedBox(height: 6),
                TransitInput(
                    hint: 'Ej: Esteve - San Telmo', controller: nameCtrl),
                const SizedBox(height: 16),
                Text('Tipo de servicio',
                    style: TransitTypography.bodySecondary(c.textMid)),
                const SizedBox(height: 6),
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: c.bgInput,
                    border: Border.all(color: c.border, width: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: serviceType,
                      isExpanded: true,
                      dropdownColor: c.bgSurface,
                      style: TransitTypography.bodyPrimary(c.textHi),
                      items: const [
                        DropdownMenuItem(
                            value: 'urban', child: Text('Urbano')),
                        DropdownMenuItem(
                            value: 'metropolitan',
                            child: Text('Metropolitano')),
                      ],
                      onChanged: (v) {
                        if (v != null) onServiceTypeChanged(v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 100,
                  child: GestureDetector(
                    onTap: onStart,
                    child: Container(
                      color: c.accent,
                      alignment: Alignment.center,
                      child: Text(
                        '● EMPEZAR A GRABAR',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: c.bgRoot,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
