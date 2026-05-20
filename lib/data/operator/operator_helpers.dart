import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../../shared/models/operator_model.dart';
import 'domain/operator_repository.dart';

OperatorModel operatorFromRow(Map<String, dynamic> row) {
  final slug = row['slug'] as String? ?? '';
  final name = row['name'] as String? ?? '';
  return OperatorModel(
    id: row['id'] as String,
    name: name,
    shortName: slug.isNotEmpty ? slug.toUpperCase() : name,
    slug: slug,
    region: row['region'] as String? ?? '',
    website: row['website'] as String? ?? '',
    contactEmail: row['contact_email'] as String? ?? '',
    phone: '',
  );
}

const _logTag = 'Repo:Operator';

OperatorRepositoryException mapOperatorError(
  Object e,
  StackTrace st,
  String op,
) {
  AppLogger.warn(_logTag, '$op failed', e);
  if (e is PostgrestException) {
    final code = e.code;
    if (code == 'PGRST116') {
      return OperatorRepositoryException(
        error: OperatorRepositoryError.notFound,
        message: 'Operator not found',
        cause: e,
        stackTrace: st,
      );
    }
    if (code == '23505') {
      return OperatorRepositoryException(
        error: OperatorRepositoryError.conflict,
        message: 'An operator with that slug already exists',
        cause: e,
        stackTrace: st,
      );
    }
    if (code == '42501') {
      return OperatorRepositoryException(
        error: OperatorRepositoryError.denied,
        message: 'Access denied by RLS',
        cause: e,
        stackTrace: st,
      );
    }
    return OperatorRepositoryException(
      error: OperatorRepositoryError.unknown,
      message: 'Postgrest error: ${e.message}',
      cause: e,
      stackTrace: st,
    );
  }
  return OperatorRepositoryException(
    error: OperatorRepositoryError.network,
    message: 'Network or unknown error in $op',
    cause: e,
    stackTrace: st,
  );
}
