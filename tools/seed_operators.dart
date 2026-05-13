// tools/seed_operators.dart
//
// Herramienta standalone que lee data/seed/spanish_gtfs_feeds.yaml
// y crea operadores en Supabase vía service_role key.
//
// Uso:
//   dart run tools/seed_operators.dart
//
// Requiere SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY en entorno
// o en .env en la raíz del proyecto.

import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main(List<String> args) async {
  final dryRun = args.contains('--dry-run');

  final yamlContent = File('data/seed/spanish_gtfs_feeds.yaml').readAsStringSync();
  final yaml = loadYaml(yamlContent) as YamlMap;
  final operators = yaml['operators'] as YamlList;

  final url = Platform.environment['SUPABASE_URL'] ?? '';
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ??
      Platform.environment['SUPABASE_ANON_KEY'] ?? '';

  if (url.isEmpty || key.isEmpty) {
    stderr.writeln('Error: SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY requeridas');
    exit(1);
  }

  final client = SupabaseClient(url, key);
  int created = 0;
  int skipped = 0;

  for (final op in operators) {
    final slug = (op as YamlMap)['slug'] as String;
    final name = op['name'] as String;
    final region = op['region'] as String?;
    final website = op['website'] as String?;

    // Verificar si ya existe
    final existing = await client
        .from('operators')
        .select('id')
        .eq('slug', slug)
        .maybeSingle();

    if (existing != null) {
      print('SKIP $slug — ya existe (id=${existing['id']})');
      skipped++;
      continue;
    }

    if (dryRun) {
      print('DRY-RUN $slug — se crearía como "$name" ($region)');
      continue;
    }

    await client.from('operators').insert({
      'slug': slug,
      'name': name,
      'region': region ?? 'ES',
      'website': website,
    });

    print('CREATE $slug — $name ($region)');
    created++;
  }

  print('');
  print('Resultado: $created creados, $skipped ya existían (${operators.length} total)');
  if (dryRun) print('Ejecución en modo dry-run. Sin --dry-run para escribir.');
}
