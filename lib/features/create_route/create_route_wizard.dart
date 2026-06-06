import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/uuid.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../../data/user_routes/user_route_schedules_repository.dart';
import '../../data/user_routes/user_routes_repository.dart';
import '../../data/user_stops/user_stops_repository.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_button.dart';
import 'steps/step_basic_info.dart';
import 'steps/step_route_path.dart';
import 'steps/step_schedules.dart';
import 'steps/step_stops.dart';
import 'steps/step_summary.dart';
import 'steps/step_visibility.dart';
import 'steps/wizard_models.dart';

class CreateRouteWizard extends ConsumerStatefulWidget {
  const CreateRouteWizard({super.key, this.routeId});

  final String? routeId;

  @override
  ConsumerState<CreateRouteWizard> createState() => _CreateRouteWizardState();
}

class _CreateRouteWizardState extends ConsumerState<CreateRouteWizard> {
  static const _logTag = 'CreateRouteWizard';

  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1 — Basic info
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _routeColor = '#977DDF';
  String _serviceType = 'urban';

  // Step 2 — Stops
  final List<WizardStop> _stops = [];

  // Step 3 — Route path
  final WizardRoutePath _routePath = WizardRoutePath();

  // Step 4 — Schedules
  final List<WizardSchedule> _schedules = [];

  // Step 5 — Visibility
  String _visibility = 'private';

  // Step 6 — Summary
  bool _proposeAsCommunity = false;
  bool _isSaving = false;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    // Sin este listener, el botón "Siguiente"/"Publicar" no recalcula
    // canProceed cuando el usuario escribe el nombre y queda en gris.
    _nameCtrl.addListener(_onWizardFieldChanged);
    if (widget.routeId != null) {
      _isEditing = true;
      _loadExisting();
    }
  }

  void _onWizardFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadExisting() async {
    final routeRepo = ref.read(userRoutesRepositoryProvider);
    if (routeRepo == null || widget.routeId == null) return;
    try {
      final route = await routeRepo.getById(widget.routeId!);
      if (route == null || !mounted) return;
      setState(() {
        _nameCtrl.text = route.name;
        _descCtrl.text = route.description ?? '';
        _routeColor = route.routeColor;
        _serviceType = route.serviceType;
        _visibility = route.visibility;
      });
      final stopsRepo = ref.read(userStopsRepositoryProvider);
      if (stopsRepo != null) {
        final routeStops = await stopsRepo.getStopsForRoute(widget.routeId!);
        if (mounted) {
          setState(() {
            _stops.clear();
            for (final rs in routeStops) {
              _stops.add(WizardStop(
                stopId: rs.userStopId,
                name: rs.stop?.name ?? '',
                lat: rs.stop?.lat ?? 0,
                lng: rs.stop?.lng ?? 0,
                stopType: rs.stop?.stopType ?? 'custom',
                officialStopId: rs.stop?.officialStopId,
                suggestAsOfficial: rs.stop?.promotionStatus == 'suggested',
                orderIndex: rs.orderIndex,
              ));
            }
          });
        }
      }
      final schedRepo = ref.read(userRouteSchedulesRepositoryProvider);
      if (schedRepo != null) {
        final schedules = await schedRepo.getForRoute(widget.routeId!);
        if (mounted) {
          setState(() {
            _schedules.clear();
            for (final s in schedules) {
              _schedules.add(WizardSchedule(
                dayType: s.dayType,
                departureTime: s.departureTime,
                originStopId: s.originStopId,
                notes: s.notes,
              ));
            }
          });
        }
      }
    } catch (e) {
      AppLogger.error(_logTag, 'loadExisting failed', e);
    }
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onWizardFieldChanged);
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  static const _stepCount = 6;

  void _goToStep(int step) {
    // Antes de entrar al paso de "Trazado" (índice 2) garantizamos
    // que los segmentos están al día con las paradas actuales. Sin
    // esto, si añades paradas y saltas al trazado, la lista de
    // segmentos puede quedar desfasada.
    if (step == 2) _syncPathSegments();
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
  }

  void _next() {
    if (_currentStep < _stepCount - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _nameCtrl.text.trim().length >= 3 &&
            _nameCtrl.text.trim().length <= 80;
      case 1:
        // Mínimo 2 paradas (origen + destino). Sin esto los segmentos
        // del paso "Trazado" no se pueden construir.
        return _stops.length >= 2;
      case 2:
        return true;
      case 3:
        return true;
      case 4:
        return true;
      case 5:
        // Step Resumen: habilitamos "Publicar" si el nombre sigue
        // válido y hay al menos dos paradas.
        return _nameCtrl.text.trim().length >= 3 && _stops.length >= 2;
      default:
        return false;
    }
  }

  Future<void> _publish() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final routeRepo = ref.read(userRoutesRepositoryProvider);
      final stopsRepo = ref.read(userStopsRepositoryProvider);
      final schedRepo = ref.read(userRouteSchedulesRepositoryProvider);

      if (routeRepo == null || stopsRepo == null || schedRepo == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Debes iniciar sesión para crear una ruta'),
            ),
          );
        }
        setState(() => _isSaving = false);
        return;
      }

      final client = ref.read(supabaseClientProvider);
      final uid = client.auth.currentUser?.id;
      if (uid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesión no válida. Inicia sesión de nuevo.')),
          );
        }
        setState(() => _isSaving = false);
        return;
      }

      final color = _routeColor.startsWith('#') ? _routeColor : '#$_routeColor';

      final status = _proposeAsCommunity ? 'review_pending' : 'published';

      final routeModel = UserRouteModel(
        id: widget.routeId ?? generateUuidV4(),
        authorId: uid,
        name: _nameCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        routeColor: color,
        serviceType: _serviceType,
        visibility: _visibility,
        status: status,
      );

      UserRouteModel? savedRoute;
      if (_isEditing && widget.routeId != null) {
        savedRoute = await routeRepo.update(routeModel);
      } else {
        savedRoute = await routeRepo.create(routeModel);
      }

      if (savedRoute == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al guardar la ruta')),
          );
        }
        setState(() => _isSaving = false);
        return;
      }

      final routeId = savedRoute.id;

      final routeStops = <UserRouteStopModel>[];
      for (var i = 0; i < _stops.length; i++) {
        final ws = _stops[i];
        final stopModel = UserStopModel(
          id: ws.stopId,
          authorId: uid,
          name: ws.name,
          lat: ws.lat,
          lng: ws.lng,
          officialStopId: ws.officialStopId,
          stopType: ws.stopType,
          promotionStatus: ws.suggestAsOfficial ? 'requested' : 'none',
        );
        await stopsRepo.create(stopModel);
        routeStops.add(UserRouteStopModel(
          userStopId: ws.stopId,
          orderIndex: i,
        ));
      }
      await stopsRepo.saveRouteStops(routeId, routeStops);

      final scheduleModels = _schedules
          .map((s) => UserRouteScheduleModel(
                routeId: routeId,
                dayType: s.dayType,
                departureTime: _normalizeTime(s.departureTime),
                originStopId: s.originStopId,
                notes: s.notes,
              ))
          .toList();
      if (scheduleModels.isNotEmpty) {
        await schedRepo.saveAll(routeId, scheduleModels);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Ruta actualizada' : 'Ruta publicada con éxito',
            ),
          ),
        );
        if (context.mounted) context.pop();
      }
    } on PostgrestException catch (e) {
      AppLogger.error(_logTag, 'publish PG error code=${e.code} msg=${e.message}');
      String msg = 'Error al publicar';
      if (e.code == '22P02') {
        msg = 'Error de formato en los datos. Revisa el color, tipo de servicio y horarios.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      AppLogger.error(_logTag, 'publish failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _normalizeTime(String time) {
    final parts = time.split(':');
    if (parts.length == 2) return '$time:00';
    return time;
  }

  void _syncPathSegments() {
    final existing = _routePath.segments;
    final needed = <WizardSegment>[];
    for (var i = 0; i < _stops.length - 1; i++) {
      final fromId = _stops[i].stopId;
      final toId = _stops[i + 1].stopId;
      final found = existing.where(
          (s) => s.fromStopId == fromId && s.toStopId == toId);
      if (found.isNotEmpty) {
        needed.add(found.first);
      } else {
        needed.add(WizardSegment(fromStopId: fromId, toStopId: toId));
      }
    }
    existing
      ..clear()
      ..addAll(needed);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: TransitAppBar(
        title: _isEditing ? 'Editar ruta' : 'Crear ruta',
        transparent: true,
      ),
      body: Column(
        children: [
          _StepIndicator(
            currentStep: _currentStep,
            stepCount: _stepCount,
            colors: colors,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: [
                StepBasicInfo(
                  nameCtrl: _nameCtrl,
                  descCtrl: _descCtrl,
                  routeColor: _routeColor,
                  serviceType: _serviceType,
                  onColorChanged: (c) => setState(() => _routeColor = c),
                  onServiceTypeChanged: (t) =>
                      setState(() => _serviceType = t),
                ),
                StepStops(
                  stops: _stops,
                  // Resync segmentos del trazado cada vez que se
                  // añade/quita/reordena una parada — antes los
                  // segmentos solo se creaban al editar el trazado y
                  // el step "Trazado" parecía vacío.
                  onChanged: () => _syncPathSegments(),
                ),
                StepRoutePath(
                  stops: _stops,
                  path: _routePath,
                  onChanged: () => _syncPathSegments(),
                ),
                StepSchedules(
                  schedules: _schedules,
                  stops: _stops,
                  onChanged: () => setState(() {}),
                ),
                StepVisibility(
                  visibility: _visibility,
                  onChanged: (v) => setState(() => _visibility = v),
                ),
                StepSummary(
                  routeName: _nameCtrl.text.trim(),
                  routeColor: _routeColor,
                  serviceType: _serviceType,
                  stopsCount: _stops.length,
                  schedulesCount: _schedules.length,
                  visibility: _visibility,
                  proposeAsCommunity: _proposeAsCommunity,
                  onProposeChanged: (v) =>
                      setState(() => _proposeAsCommunity = v),
                  stops: _stops,
                  path: _routePath,
                ),
              ],
            ),
          ),
          _BottomBar(
            currentStep: _currentStep,
            stepCount: _stepCount,
            canProceed: _canProceed(),
            isSaving: _isSaving,
            onPrev: _prev,
            onNext: _next,
            onPublish: _publish,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.currentStep,
    required this.stepCount,
    required this.colors,
  });

  final int currentStep;
  final int stepCount;
  final TransitColorScheme colors;

  static const _labels = [
    'Info',
    'Paradas',
    'Trazado',
    'Horarios',
    'Visibilidad',
    'Resumen',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TransitSpacing.space16,
        vertical: TransitSpacing.space12,
      ),
      color: colors.bgRaised,
      child: Column(
        children: [
          Row(
            children: List.generate(stepCount, (i) {
              final isActive = i <= currentStep;
              final isCurrent = i == currentStep;
              return Expanded(
                child: Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isActive ? colors.accent : colors.border,
                        ),
                      ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrent
                            ? colors.accent
                            : isActive
                                ? colors.accent.withValues(alpha: 0.3)
                                : colors.border,
                      ),
                      alignment: Alignment.center,
                      child: isActive && !isCurrent
                          ? Icon(Icons.check, size: 14, color: colors.accent)
                          : Text(
                              '${i + 1}',
                              style: TransitTypography.bodySmall(
                                isActive ? colors.bgRoot : colors.textMid,
                              ),
                            ),
                    ),
                    if (i < stepCount - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i < currentStep
                              ? colors.accent
                              : colors.border,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: TransitSpacing.space6),
          Row(
            children: List.generate(stepCount, (i) {
              final isCurrent = i == currentStep;
              return Expanded(
                child: Text(
                  _labels[i],
                  textAlign: TextAlign.center,
                  style: TransitTypography.bodySmall(
                    isCurrent ? colors.accent : colors.textLo,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentStep,
    required this.stepCount,
    required this.canProceed,
    required this.isSaving,
    required this.onPrev,
    required this.onNext,
    required this.onPublish,
    required this.colors,
  });

  final int currentStep;
  final int stepCount;
  final bool canProceed;
  final bool isSaving;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPublish;
  final TransitColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final isLast = currentStep == stepCount - 1;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TransitSpacing.space16,
        vertical: TransitSpacing.space12,
      ),
      decoration: BoxDecoration(
        color: colors.bgRaised,
        border: Border(top: BorderSide(color: colors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (currentStep > 0)
              TransitButton(
                label: 'Atrás',
                isPrimary: false,
                onPressed: onPrev,
              ),
            const Spacer(),
            if (isLast)
              TransitButton(
                label: isSaving ? 'Guardando...' : 'Publicar',
                onPressed: canProceed && !isSaving ? onPublish : null,
                isLoading: isSaving,
              )
            else
              TransitButton(
                label: 'Siguiente',
                onPressed: canProceed ? onNext : null,
              ),
          ],
        ),
      ),
    );
  }
}
