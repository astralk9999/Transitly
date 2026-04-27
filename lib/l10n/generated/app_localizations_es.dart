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
}
