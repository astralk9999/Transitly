import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/models.dart';
import 'route_plan_models.dart';
import 'route_planner_service.dart';

final routePlanResultsProvider = FutureProvider.family<
    List<RoutePlanResult>,
    ({StopModel from, StopModel to})>((ref, args) async {
  final service = ref.read(routePlannerServiceProvider);
  return service.plan(from: args.from, to: args.to);
});
