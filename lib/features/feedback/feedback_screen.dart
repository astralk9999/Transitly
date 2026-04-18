import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/mock/mock_data_service.dart';
import '../../shared/widgets/smoke_background.dart';
import '../../shared/widgets/transit_button.dart';
import '../../shared/widgets/transit_input.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key, required this.routeId});

  final String routeId;

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mockData = ref.watch(mockDataServiceProvider);
    final route = mockData.getRouteById(widget.routeId);
    final code = route?.code ?? widget.routeId;

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          onPressed: () => context.pop(),
        ),
        title: Text('FEEDBACK · $code',
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
            _feedbackOption(
              c,
              Icons.route,
              'El recorrido en el mapa',
              'Editor de trazado',
            ),
            _feedbackOption(
              c,
              Icons.location_on,
              'Una parada (falta, sobra o está mal)',
              'Paradas',
            ),
            _feedbackOption(
              c,
              Icons.schedule,
              'Los horarios',
              'Horarios',
            ),
            _feedbackOption(
              c,
              Icons.info_outline,
              'Información general',
              'Información general',
            ),
            _feedbackOption(
              c,
              Icons.lightbulb_outline,
              'Tengo una sugerencia',
              'Sugerencia',
            ),

            const SizedBox(height: 24),

            Text('Descripción',
                style: TransitTypography.bodySecondary(c.textMid)),
            const SizedBox(height: 6),
            TransitInput(
              hint: 'Descripción de lo que has encontrado',
              controller: _descCtrl,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TransitButton(
                label: 'ENVIAR FEEDBACK',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Feedback enviado · Gracias')),
                  );
                  context.pop();
                },
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

  Widget _feedbackOption(
      TransitColorScheme c, IconData icon, String label, String type) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Formulario de $type: próximamente')),
        );
      },
      child: Container(
        height: 56,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: c.bgSurface,
          border: Border.all(color: c.border, width: 0.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: c.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TransitTypography.bodyPrimary(c.textHi)),
            ),
            Icon(Icons.chevron_right, size: 20, color: c.textLo),
          ],
        ),
      ),
    );
  }
}
