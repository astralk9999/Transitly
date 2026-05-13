// tools/migrate_comujesa.dart
//
// Migra los datos de COMUJESA desde assets/mock/comujesa_data.json
// a las tablas de Supabase (operators, routes, stops, route_stops,
// schedules).
//
// Uso:
//   dart run tools/migrate_comujesa.dart [--dry-run]
//
// Requiere SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY en entorno
// o en .env en la raíz del proyecto.

import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

void main(List<String> args) async {
  final dryRun = args.contains('--dry-run');

  final jsonFile = File('assets/mock/comujesa_data.json');
  if (!jsonFile.existsSync()) {
    stderr.writeln('Error: assets/mock/comujesa_data.json no encontrado');
    exit(1);
  }

  final jsonContent = jsonFile.readAsStringSync();
  final data = json.decode(jsonContent) as Map<String, dynamic>;

  final url = Platform.environment['SUPABASE_URL'] ?? '';
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ??
      Platform.environment['SUPABASE_ANON_KEY'] ?? '';

  if (url.isEmpty || key.isEmpty) {
    stderr.writeln('Error: SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY requeridas');
    exit(1);
  }

  final client = SupabaseClient(url, key);

  final operatorJson = data['operator'] as Map<String, dynamic>;
  final lines = data['lines'] as List<dynamic>;

  // ── Operator ──
  final slug = 'comujesa';
  print('Migrando operador: $slug');

  final existingOp = await client
      .from('operators')
      .select('id')
      .eq('slug', slug)
      .maybeSingle();

  String operatorId;

  if (existingOp != null) {
    operatorId = existingOp['id'] as String;
    print('  SKIP operator — ya existe (id=$operatorId)');
  } else if (dryRun) {
    operatorId = 'dry-run-operator-id';
    print('  DRY-RUN operator');
  } else {
    final {data: newOp} = await client.from('operators').insert({
      'slug': slug,
      'name': operatorJson['name'] ?? 'COMUJESA',
      'region': 'Andalucía',
      'website': operatorJson['website'] ?? '',
    }).select().single();
    operatorId = newOp['id'] as String;
    print('  CREATE operator (id=$operatorId)');
  }

  // ── Stops ──
  print('Migrando paradas...');
  final allStops = <Map<String, dynamic>>[];
  final stopIdMap = <String, String>{}; // code → UUID

  for (final line in lines) {
    final lineStops = line['stops'] as List<dynamic>? ?? [];
    for (final stop in lineStops) {
      final code = stop['code'] as String;
      if (stopIdMap.containsKey(code)) continue;

      stopIdMap[code] = 'pending';
      allStops.add({
        'code': code,
        'name': stop['name'] as String? ?? code,
        'lat': stop['lat'] as double? ?? 0,
        'lng': stop['lng'] as double? ?? 0,
      });
    }
  }

  int stopsUpserted = 0;
  for (final stop in allStops) {
    final existingStop = await client
        .from('stops')
        .select('id')
        .eq('operator_id', operatorId)
        .eq('code', stop['code'])
        .maybeSingle();

    if (existingStop != null) {
      stopIdMap[stop['code'] as String] = existingStop['id'] as String;
      continue;
    }

    if (dryRun) {
      stopIdMap[stop['code'] as String] = 'dry-run-stop-${stop['code']}';
      continue;
    }

    final geom = 'SRID=4326;POINT(${stop['lng']} ${stop['lat']})';
    final {data: newStop} = await client.from('stops').insert({
      'operator_id': operatorId,
      'code': stop['code'],
      'name': stop['name'],
      'geom': geom,
    }).select().single();

    stopIdMap[stop['code'] as String] = newStop['id'] as String;
    stopsUpserted++;
  }
  print('  Stops: $stopsUpserted creados (${allStops.length} totales, ${stopIdMap.length} con UUID)');

  // ── Routes ──
  print('Migrando rutas...');
  int routesUpserted = 0;
  final routeIdMap = <String, String>{}; // code → UUID

  for (final line in lines) {
    final code = line['code'] as String;
    final name = line['name'] as String? ?? code;

    final existingRoute = await client
        .from('routes')
        .select('id')
        .eq('operator_id', operatorId)
        .eq('code', code)
        .maybeSingle();

    if (existingRoute != null) {
      routeIdMap[code] = existingRoute['id'] as String;
      continue;
    }

    if (dryRun) {
      routeIdMap[code] = 'dry-run-route-$code';
      continue;
    }

    final color = line['color'] as String? ?? '#977ddf';
    final {data: newRoute} = await client.from('routes').insert({
      'operator_id': operatorId,
      'source': 'official',
      'status': 'official',
      'code': code,
      'name': name,
      'color': color.startsWith('#') ? color : '#$color',
    }).select().single();

    routeIdMap[code] = newRoute['id'] as String;
    routesUpserted++;
  }
  print('  Routes: $routesUpserted creadas (${lines.length} totales)');

  // ── Route Stops ──
  print('Migrando route-stops...');
  int routeStopsUpserted = 0;

  for (final line in lines) {
    final routeCode = line['code'] as String;
    final routeId = routeIdMap[routeCode];
    if (routeId == null || routeId.startsWith('dry-run')) continue;

    final lineStops = line['stops'] as List<dynamic>? ?? [];
    final routeStopSet = <String>{};

    for (int i = 0; i < lineStops.length; i++) {
      final stopCode = lineStops[i]['code'] as String;
      final stopId = stopIdMap[stopCode];
      if (stopId == null || stopId.startsWith('dry-run')) continue;

      final key = '$routeId:$stopId:0:$i';
      if (routeStopSet.contains(key)) continue;
      routeStopSet.add(key);

      if (dryRun) continue;

      try {
        await client.from('route_stops').upsert({
          'route_id': routeId,
          'stop_id': stopId,
          'sequence': i,
          'direction': 0,
        }, {onConflict: 'route_id, stop_id, direction, sequence'});
        routeStopsUpserted++;
      } catch (e) {
        print('  WARN route_stop $routeCode-$stopCode: $e');
      }
    }
  }
  print('  RouteStops: $routeStopsUpserted upserted');

  // ── Schedules ──
  print('Migrando horarios...');
  int schedulesUpserted = 0;

  for (final line in lines) {
    final routeCode = line['code'] as String;
    final routeId = routeIdMap[routeCode];
    if (routeId == null || routeId.startsWith('dry-run')) continue;

    final schedules = line['schedules'] as List<dynamic>? ?? [];
    final scheduleSet = <String>{};

    for (final sched in schedules) {
      final departure = sched['departure'] as String? ?? sched['departureTime'] as String?;
      if (departure == null) continue;

      final dayType = (sched['dayType'] as String? ?? 'weekday').replaceAll('domingo', 'sunday_holiday');
      final key = '$routeId:$dayType:0:$departure';
      if (scheduleSet.contains(key)) continue;
      scheduleSet.add(key);

      if (dryRun) continue;

      try {
        await client.from('schedules').upsert({
          'route_id': routeId,
          'day_type': dayType,
          'direction': 0,
          'departure_time': departure,
        });
        schedulesUpserted++;
      } catch (e) {
        print('  WARN schedule $routeCode-$departure: $e');
      }
    }
  }
  print('  Schedules: $schedulesUpserted upserted');

  print('');
  print('Migración completada.');
  print('Operador: $slug ($operatorId)');
  print('Paradas: ${allStops.length} totales, $stopsUpserted nuevas');
  print('Rutas: ${lines.length} totales, $routesUpserted nuevas');
  print('RouteStops: $routeStopsUpserted');
  print('Horarios: $schedulesUpserted');
  if (dryRun) print('Modo dry-run. Sin --dry-run para escribir.');
}
