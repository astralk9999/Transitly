// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Transitly';

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabSearch => 'Buscar';

  @override
  String get tabMap => 'Mapa';

  @override
  String get tabCard => 'Tarjeta';

  @override
  String get tabProfile => 'Perfil';

  @override
  String get nfcErrorUnsupported => 'NFC no disponible en este dispositivo';

  @override
  String get nfcErrorNotMifareClassic => 'Esta tarjeta no es compatible';

  @override
  String get nfcErrorAuthFailed => 'No se pudo autenticar la tarjeta';

  @override
  String get nfcErrorReadFailed => 'Error al leer la tarjeta';

  @override
  String get nfcErrorTagLost => 'Tarjeta retirada demasiado pronto';

  @override
  String get nfcErrorUnknown => 'Error desconocido';

  @override
  String get profileSectionAppearance => 'APARIENCIA';

  @override
  String get profileSectionDemoProfile => 'PERFIL DE DEMO';

  @override
  String get profileSectionAccessibility => 'ACCESIBILIDAD';

  @override
  String get profileSectionOfflineData => 'DATOS OFFLINE';

  @override
  String get profileSectionAbout => 'ACERCA DE';

  @override
  String get accessibilityTitle => 'Accesibilidad';

  @override
  String get accessibilityThemeSection => 'TEMA';

  @override
  String get accessibilityThemeSystem => 'Sistema';

  @override
  String get accessibilityThemeLight => 'Claro';

  @override
  String get accessibilityThemeDark => 'Oscuro';

  @override
  String get accessibilitySystemPreferencesSection =>
      'PREFERENCIAS DEL SISTEMA';

  @override
  String get accessibilityLanguageSection => 'IDIOMA';

  @override
  String get accessibilityLanguageEs => 'Español';

  @override
  String get accessibilityLanguageEn => 'Inglés';

  @override
  String get accessibilityLanguageSystem => 'Seguir idioma del sistema';

  @override
  String get offlineDataTitle => 'Datos offline';

  @override
  String get offlineDataContent => 'CONTENIDO';

  @override
  String get offlineDataArchive => 'ARCHIVO';

  @override
  String get offlineDataReload => 'Recargar desde assets';

  @override
  String get offlineDataReloaded => 'Datos recargados';

  @override
  String get offlineDataSize => 'Tamaño';

  @override
  String get offlineDataLoaded => 'Cargado';

  @override
  String get offlineDataRoutes => 'Rutas';

  @override
  String get offlineDataStops => 'Paradas';

  @override
  String get actionClose => 'Cerrar';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionSave => 'Guardar';

  @override
  String get adminUsersTitle => 'Gestión de usuarios';

  @override
  String get adminUsersSearchHint => 'Buscar usuario...';

  @override
  String get adminUsersFilterAll => 'Todos';

  @override
  String get adminUsersEmpty => 'No se encontraron usuarios';

  @override
  String get adminUsersOffline => 'Conecta a internet para gestionar usuarios';

  @override
  String get adminUsersRoleAdmin => 'Admin';

  @override
  String get adminUsersRoleModerator => 'Moderador';

  @override
  String get adminUsersRoleOperatorAdmin => 'Operador Admin';

  @override
  String get adminUsersRoleDriver => 'Conductor';

  @override
  String get adminUsersRolePassenger => 'Pasajero';

  @override
  String get adminUsersRoleAll => 'Todos';

  @override
  String get adminUsersError => 'Error al cargar usuarios';

  @override
  String get adminUsersNoConnection => 'Sin conexión';

  @override
  String get adminUsersNoResults => 'Sin resultados';

  @override
  String adminUsersNoMatchSearch(String query) {
    return 'No hay usuarios que coincidan con \"$query\"';
  }

  @override
  String get adminUsersNoMatchRole => 'No hay usuarios con el rol seleccionado';

  @override
  String get adminOperatorsTitle => 'Gestión de operadores';

  @override
  String get adminOperatorsCreate => 'Crear operador';

  @override
  String get adminOperatorsEdit => 'Editar operador';

  @override
  String get adminOperatorsDelete => 'Eliminar';

  @override
  String get adminOperatorsSlug => 'Slug';

  @override
  String get adminOperatorsName => 'Nombre';

  @override
  String get adminOperatorsRegion => 'Región';

  @override
  String get adminOperatorsWebsite => 'Sitio web';

  @override
  String get adminOperatorsEmail => 'Correo de contacto';

  @override
  String get adminOperatorsDeleteConfirm => '¿Eliminar este operador?';

  @override
  String get adminOperatorsEmpty => 'No hay operadores registrados';

  @override
  String get adminOperatorsCreated => 'Operador creado';

  @override
  String get adminOperatorsUpdated => 'Operador actualizado';

  @override
  String get adminOperatorsDeleted => 'Operador eliminado';

  @override
  String get adminOperatorsError => 'Error al cargar operadores';

  @override
  String get adminOperatorsNoConnection => 'Sin conexión';

  @override
  String get adminOperatorsOffline =>
      'Conecta a internet para gestionar operadores';

  @override
  String get adminOperatorsErrorDenied =>
      'Permiso denegado para gestionar operadores';

  @override
  String get adminOperatorsErrorNetwork => 'Error de red al cargar operadores';

  @override
  String get adminOperatorsErrorUnknown =>
      'Error desconocido al cargar operadores';

  @override
  String get managerInboxTitle => 'Bandeja de gestión';

  @override
  String get managerInboxFeedback => 'Feedback';

  @override
  String get managerInboxSuggestions => 'Sugerencias';

  @override
  String get managerInboxResolved => 'Resueltos';

  @override
  String managerInboxPending(int count) {
    return '$count pendientes';
  }

  @override
  String get managerInboxMarkInReview => 'Marcar en revisión';

  @override
  String get managerInboxResolve => 'Resolver';

  @override
  String get managerInboxReject => 'Rechazar';

  @override
  String get managerInboxEmptyFeedback => 'No hay feedback pendiente';

  @override
  String get managerInboxEmptySuggestions => 'No hay sugerencias';

  @override
  String get managerInboxEmptyResolved => 'No hay elementos resueltos';

  @override
  String get managerInboxOpen => 'Abrir';

  @override
  String get managerInboxStatus => 'Estado';

  @override
  String get managerInboxItemDescription => 'Descripción';

  @override
  String get managerInboxItemDate => 'Fecha';

  @override
  String get managerInboxItemType => 'Tipo';
}
