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

  @override
  String get appearanceTitle => 'Apariencia';

  @override
  String get appearancePalettesSection => 'PALETAS';

  @override
  String get appearanceBrightnessSection => 'BRILLO';

  @override
  String get appearanceBackgroundSection => 'FONDO';

  @override
  String get appearanceTextSection => 'TEXTO';

  @override
  String get appearanceAccessibilitySection => 'ACCESIBILIDAD VISUAL';

  @override
  String get appearanceShowBackground => 'Mostrar fondo decorativo';

  @override
  String get appearanceBackgroundOpacity => 'Opacidad del fondo';

  @override
  String get appearanceFontScale => 'Tamaño de texto';

  @override
  String get appearanceDyslexiaFont => 'Fuente para dislexia';

  @override
  String get appearanceColorBlindMode => 'Modo daltónico';

  @override
  String get appearanceReduceMotion => 'Reducir animaciones';

  @override
  String get appearanceResetButton => 'Restaurar valores por defecto';

  @override
  String get appearanceResetConfirm =>
      '¿Restaurar todos los ajustes de apariencia a sus valores por defecto?';

  @override
  String get appearanceResetDone => 'Ajustes restaurados';

  @override
  String get appearanceColorBlindNone => 'Ninguno';

  @override
  String get appearanceColorBlindProtanopia => 'Protanopia';

  @override
  String get appearanceColorBlindDeuteranopia => 'Deuteranopia';

  @override
  String get appearanceColorBlindTritanopia => 'Tritanopia';

  @override
  String get appearanceBrightnessSystem => 'Sistema';

  @override
  String get appearanceBrightnessLight => 'Claro';

  @override
  String get appearanceBrightnessDark => 'Oscuro';

  @override
  String get appearanceLinkAppearance => 'Personalizar apariencia';

  @override
  String get appearanceBgNone => 'Ninguno';

  @override
  String get appearanceBgSmoke => 'Humo';

  @override
  String get appearanceBgGradient => 'Degradado';

  @override
  String get appearanceBgGrid => 'Cuadrícula';

  @override
  String get appearanceBgTopo => 'Topografía';

  @override
  String get appearanceTextPreview =>
      'El rápido zorro marrón salta sobre el perro perezoso. Este texto de muestra te permite ver cómo se ve la tipografía con los ajustes actuales.';

  @override
  String get appearanceCustomPaletteTitle => 'Paleta personalizada';

  @override
  String get appearanceCustomPalettePrimary => 'Primario';

  @override
  String get appearanceCustomPaletteSecondary => 'Secundario';

  @override
  String get appearanceCustomPaletteBgRoot => 'Fondo raíz';

  @override
  String get appearanceCustomPaletteBgSurface => 'Fondo superficie';

  @override
  String get appearanceCustomPaletteTextHi => 'Texto principal';

  @override
  String get appearanceCustomPalettePreview => 'Vista previa';

  @override
  String get appearanceCustomPaletteContrastPass => 'Contraste AA';

  @override
  String get appearanceCustomPaletteContrastFail => 'Contraste bajo';

  @override
  String get appearanceCustomPaletteSaved => 'Paleta guardada';

  @override
  String get appearanceCustomPaletteAdd => 'Crear paleta';

  @override
  String get appearanceHighContrast => 'Alto contraste';

  @override
  String get appearanceHighContrastSubtitle =>
      'Bordes más gruesos y mayor contraste de texto';

  @override
  String get accessibilityHighContrast => 'Alto contraste';

  @override
  String get accessibleBusesTitle => 'Buses cercanos';

  @override
  String get accessibleBusesEmpty => 'Sin buses activos';

  @override
  String get accessibleBusesNoActiveBuses =>
      'No se encontraron buses en operación en este momento';

  @override
  String get accessibleBusesError => 'Error al cargar buses';

  @override
  String get accessibleBusesNextStop => 'Próxima parada';

  @override
  String get accessibleBusesSourceEstimated => 'Estimado';

  @override
  String get accessibleBusesSourceDriver => 'Conductor';

  @override
  String get accessibleBusesSourceOfficial => 'Oficial';

  @override
  String get accessibleBusesLinkLabel => 'Ver lista de buses';

  @override
  String get onboardingSkip => 'Saltar';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingGetStarted => 'Empezar';

  @override
  String get onboardingPage1Title => 'Transporte en tiempo real';

  @override
  String get onboardingPage1Description =>
      'Consulta dónde está tu autobús ahora mismo, sin esperas innecesarias.';

  @override
  String get onboardingPage2Title => 'Tu comunidad te ayuda';

  @override
  String get onboardingPage2Description =>
      'Reporta incidencias, sugiere rutas y ayuda a otros pasajeros como tú.';

  @override
  String get onboardingPage3Title => 'Funciona sin internet';

  @override
  String get onboardingPage3Description =>
      'Descarga tus rutas y consulta horarios incluso sin conexión.';
}
