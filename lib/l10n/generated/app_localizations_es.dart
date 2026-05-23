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
  String get actionSend => 'Enviar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionBack => 'Volver';

  @override
  String get actionSignOut => 'Cerrar sesión';

  @override
  String get actionSaveDraft => 'Guardar borrador';

  @override
  String get actionSendSuggestion => 'Enviar sugerencia';

  @override
  String get actionSendFeedback => 'Enviar feedback';

  @override
  String get actionSendImprovement => 'Enviar mejora';

  @override
  String get actionSendRequest => 'Enviar solicitud';

  @override
  String get actionSending => 'Enviando...';

  @override
  String get sectionUpcomingArrivals => 'PRÓXIMAS LLEGADAS';

  @override
  String get sectionSchedules => 'HORARIOS';

  @override
  String get sectionRecentChanges => 'CAMBIOS RECIENTES';

  @override
  String get routeDayWeekday => 'Laborable';

  @override
  String get routeDaySaturday => 'Sábado';

  @override
  String get routeDaySunday => 'Domingo';

  @override
  String get routeDayHoliday => 'Festivo';

  @override
  String get stopLinesHeader => 'LÍNEAS';

  @override
  String get routeTimeline => 'RECORRIDO';

  @override
  String get editorStepInfo => 'Información';

  @override
  String get editorStepTrace => 'Trazado';

  @override
  String get editorStepStops => 'Paradas';

  @override
  String get editorStepReturn => 'Vuelta';

  @override
  String get editorStepReview => 'Revisión';

  @override
  String get actionNext => 'Siguiente';

  @override
  String get actionConfirm => 'Confirmar';

  @override
  String get actionAdd => 'Añadir';

  @override
  String get actionPause => 'Pausar';

  @override
  String get actionResume => 'Reanudar';

  @override
  String get actionFinish => 'Finalizar';

  @override
  String get actionUndo => 'Deshacer';

  @override
  String get actionPublish => 'Publicar';

  @override
  String get actionGenerate => 'Generar';

  @override
  String get actionRevoke => 'Revocar';

  @override
  String get actionShare => 'Compartir';

  @override
  String get actionApply => 'Aplicar';

  @override
  String get actionReset => 'Restablecer';

  @override
  String get actionStop => 'Detener';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get actionFollow => 'Seguir';

  @override
  String get featureComingSoon =>
      'Funcionalidad disponible en próxima versión.';

  @override
  String get statusPaused => 'PAUSADO';

  @override
  String get statusLive => 'EN VIVO';

  @override
  String get statusRecordingRoute => 'GRABANDO RUTA';

  @override
  String get recorderMarkStop => 'MARCAR PARADA';

  @override
  String recorderStopMarkedFmt(int number, String distance) {
    return 'PARADA #$number MARCADA · $distance km';
  }

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
  String get appearanceMapStyleSection => 'ESTILO DE MAPA';

  @override
  String get mapStyleStreets => 'Calles';

  @override
  String get mapStyleBasic => 'Básico';

  @override
  String get mapStyleBright => 'Brillante';

  @override
  String get mapStyleDark => 'Oscuro';

  @override
  String get mapStyleLight => 'Claro';

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

  @override
  String get reputationRankNone => 'Sin rango';

  @override
  String get reputationRankNovice => 'Novato';

  @override
  String get reputationRankContributor => 'Colaborador';

  @override
  String get reputationRankAdvocate => 'Defensor';

  @override
  String get reputationRankCartographer => 'Cartógrafo';

  @override
  String get reputationRankGuardian => 'Guardián';

  @override
  String get reputationRankLegend => 'Leyenda';

  @override
  String get reputationEventIncidentCreated => 'Reporte creado';

  @override
  String get reputationEventIncidentRejectedSpam => 'Reporte rechazado (spam)';

  @override
  String get reputationEventFeedbackSubmitted => 'Feedback enviado';

  @override
  String get reputationEventFeedbackAccepted => 'Feedback aceptado';

  @override
  String get reputationEventSuggestionCreated => 'Sugerencia creada';

  @override
  String get reputationEventSuggestionVoteReceived => 'Voto recibido';

  @override
  String get reputationEventSuggestionVerified => 'Sugerencia verificada';

  @override
  String get reputationEventSuggestionOfficial => 'Sugerencia oficializada';

  @override
  String get reputationEventDuplicateReport => 'Reporte duplicado';

  @override
  String get achievementsTitle => 'Logros';

  @override
  String achievementsLevel(String level, int xp) {
    return 'Nivel: $level · $xp XP';
  }

  @override
  String get achievementsCategoryContribution => 'Contribución';

  @override
  String get achievementsCategoryUsage => 'Uso';

  @override
  String get reputationTitle => 'Reputación';

  @override
  String get reputationHowToEarn => 'Cómo subir';

  @override
  String get reputationRanks => 'Rangos';

  @override
  String get reputationTooltip =>
      'La reputación es decorativa. Más adelante desbloqueará privilegios.';

  @override
  String get reputationPoints => 'puntos';

  @override
  String get reputationNextRank => 'Siguiente rango';

  @override
  String get reputationMaxRank => 'Rango máximo alcanzado';

  @override
  String get offlineRegionsTitle => 'Mapas offline';

  @override
  String get offlineRegionsAddRegion => 'Añadir región';

  @override
  String get offlineRegionsEmpty => 'No hay mapas descargados';

  @override
  String get offlineRegionsEmptySubtitle =>
      'Descarga zonas del mapa para usarlas sin conexión';

  @override
  String get offlineRegionsDeleteConfirm => '¿Eliminar esta región?';

  @override
  String get offlineRegionsDeleteDesc =>
      'Los tiles descargados se perderán y deberás volver a descargarlos para usar el mapa sin conexión';

  @override
  String get offlineRegionsStatusReady => 'Listo';

  @override
  String get offlineRegionsStatusDownloading => 'Descargando';

  @override
  String get offlineRegionsStatusError => 'Error';

  @override
  String get offlineRegionsStatusStale => 'Desactualizado';

  @override
  String get offlineRegionsDownloaded => 'Descargado';

  @override
  String get offlineRegionsSize => 'Tamaño';

  @override
  String get offlineRegionsActionDownload => 'Descargar';

  @override
  String get offlineRegionsActionDelete => 'Eliminar';

  @override
  String get offlineRegionsRegionName => 'Nombre de la región';

  @override
  String get offlineRegionsRegionNameHint => 'Ej. Centro de Jerez';

  @override
  String get offlineRegionsZoomMin => 'Zoom mínimo';

  @override
  String get offlineRegionsZoomMax => 'Zoom máximo';

  @override
  String get offlineRegionsEstimatedSize => 'Tamaño estimado';

  @override
  String get offlineRegionsSelectArea =>
      'Mueve el mapa para seleccionar un área';

  @override
  String get offlineRegionsDataSynced => 'Datos sincronizados';

  @override
  String get offlineRegionsMapLink => 'Mapas offline';

  @override
  String get appearanceStorageSection => 'ALMACENAMIENTO OFF LINE';

  @override
  String get appearanceStorageTotal => 'Espacio usado';

  @override
  String get appearanceStorageFmtc => 'Mapas FMTC';

  @override
  String get appearanceStorageHive => 'Datos locales';

  @override
  String get appearanceStoragePending => 'Adjuntos pendientes';

  @override
  String get appearanceStorageClearCache => 'Limpiar caché de mapas';

  @override
  String get appearanceStorageClearCacheConfirm =>
      '¿Eliminar todos los mapas offline descargados?';

  @override
  String get appearanceStorageClearCacheDone => 'Caché de mapas eliminada';

  @override
  String get appearanceStorageMaxInfo => 'Almacenamiento máximo: 500 MB';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsEmpty => 'No tienes notificaciones';

  @override
  String get notificationsMarkAllRead => 'Marcar todo leído';

  @override
  String get notificationsAllRead => 'Todo leído';

  @override
  String get notificationTypeIncidentResolved => 'Incidencia resuelta';

  @override
  String get notificationTypeRoutePromoted => 'Ruta promocionada';

  @override
  String get notificationTypeShareReceived => 'Ruta compartida contigo';

  @override
  String get notificationTypeFeatureRequestReplied =>
      'Respuesta a tu solicitud';

  @override
  String get notificationTypeBusApproaching => 'Bus acercándose';

  @override
  String get notificationTypeCustom => 'Aviso';

  @override
  String get notificationTimeNow => 'Ahora';

  @override
  String notificationTimeMinutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Hace $n min',
      one: 'Hace 1 min',
    );
    return '$_temp0';
  }

  @override
  String notificationTimeHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Hace $n h',
      one: 'Hace 1 h',
    );
    return '$_temp0';
  }

  @override
  String notificationTimeDays(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Hace $n d',
      one: 'Hace 1 d',
    );
    return '$_temp0';
  }

  @override
  String get notifPrefSectionTitle => 'NOTIFICACIONES';

  @override
  String get notifPrefIncidentResolved => 'Reportes resueltos';

  @override
  String get notifPrefRoutePromoted => 'Mis rutas';

  @override
  String get notifPrefBusApproaching => 'Buses cerca';

  @override
  String get notifPrefFeatureRequestReplied => 'Sugerencias';

  @override
  String get notifPrefQuietHoursSection => 'HORARIO SILENCIOSO';

  @override
  String get notifPrefQuietHoursEnabled => 'Activar horario silencioso';

  @override
  String get notifPrefQuietHoursDescription =>
      'Durante este horario no recibirás notificaciones sonoras. Las notificaciones seguirán apareciendo en el centro de notificaciones.';

  @override
  String get notifPrefQuietHoursStart => 'Desde';

  @override
  String get notifPrefQuietHoursEnd => 'Hasta';

  @override
  String get notifPrefQuietHoursNotSet => 'No configurado';

  @override
  String get notifPrefSelectTime => 'Seleccionar hora';

  @override
  String get privacyTitle => 'Privacidad';

  @override
  String get privacySectionConsents => 'CONSENTIMIENTOS';

  @override
  String get privacyConsentAnalytics => 'Analíticas';

  @override
  String get privacyConsentAnalyticsDesc =>
      'Datos anónimos de uso para mejorar la app';

  @override
  String get privacyConsentCrashReporting => 'Informes de fallos';

  @override
  String get privacyConsentCrashReportingDesc =>
      'Envía informes automáticos cuando la app falla';

  @override
  String get privacyConsentMarketing => 'Marketing';

  @override
  String get privacyConsentMarketingDesc =>
      'Recibe novedades y promociones sobre Transitly';

  @override
  String get privacySectionMyData => 'MIS DATOS';

  @override
  String get privacyDownloadData => 'Descargar mis datos';

  @override
  String get privacyRequestDeletion => 'Solicitar borrado de cuenta';

  @override
  String get privacySectionLegal => 'LEGAL';

  @override
  String get privacyTermsOfService => 'Términos de servicio';

  @override
  String get privacyPrivacyPolicy => 'Política de privacidad';

  @override
  String get privacyDataExportRequested =>
      'Solicitud de exportación enviada. Recibirás un enlace cuando esté lista.';

  @override
  String get privacyDeletionRequested =>
      'Solicitud de borrado enviada. Tus datos se eliminarán en 30 días.';

  @override
  String get privacyDeleteConfirmTitle => '¿Solicitar borrado de cuenta?';

  @override
  String get privacyDeleteConfirmMessage =>
      'Tus datos se eliminarán tras un periodo de espera de 30 días.';

  @override
  String get privacyDeleteConfirmCancel => 'Cancelar';

  @override
  String get privacyDeleteConfirmAction => 'Solicitar borrado';

  @override
  String get privacyLinkLabel => 'Privacidad';

  @override
  String get widgetsTitle => 'Widgets';

  @override
  String get widgetsSectionInstructions => 'INSTRUCCIONES';

  @override
  String get widgetsInstructionsAndroid =>
      'En Android, mantén pulsado en la pantalla de inicio y selecciona \"Añadir widget\". Busca Transitly en la lista.';

  @override
  String get widgetsInstructionsIos =>
      'En iOS, mantén pulsado en la pantalla de inicio, pulsa el botón + y busca Transitly.';

  @override
  String get widgetsFavoriteStop => 'Parada favorita';

  @override
  String get widgetsFavoriteLine => 'Línea favorita';

  @override
  String get widgetsHowToAdd => 'Cómo añadir el widget';

  @override
  String get widgetsConfigSaved => 'Configuración guardada';

  @override
  String get offlineBannerOffline =>
      'Sin conexión. Los cambios se guardarán y se enviarán al volver.';

  @override
  String offlineBannerQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count acciones en cola',
      one: '1 acción en cola',
    );
    return 'Sin conexión · $_temp0.';
  }

  @override
  String offlineBannerSyncing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count acciones pendientes',
      one: '1 acción pendiente',
    );
    return 'Sincronizando $_temp0…';
  }

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailHint => 'tu@email.com';

  @override
  String get authPassword => 'Contraseña';

  @override
  String get authPasswordHint => '••••••••';

  @override
  String get authPasswordMinHint => 'Mínimo 6 caracteres';

  @override
  String get authName => 'Nombre';

  @override
  String get authNameHint => 'Tu nombre';

  @override
  String get authRequired => 'Requerido';

  @override
  String get authRequiredField => 'Requerida';

  @override
  String get authInvalidEmail => 'Email inválido';

  @override
  String get authMinChars => 'Mínimo 6 caracteres';

  @override
  String get authEnterValidEmail => 'Introduce un email válido';

  @override
  String get authErrorConnection => 'Error de conexión';

  @override
  String get authErrorGoogle => 'Error de conexión con Google';

  @override
  String get authSignInSubtitle => 'Inicia sesión para continuar';

  @override
  String get authSignInButton => 'INICIAR SESIÓN';

  @override
  String get authSignInError => 'Error al iniciar sesión';

  @override
  String get authNoAccount => '¿No tienes cuenta?';

  @override
  String get authRegister => 'Regístrate';

  @override
  String get authForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get authOrContinue => 'o continúa con';

  @override
  String get authGoogleButton => 'GOOGLE';

  @override
  String get authMagicLink => 'Acceder con enlace mágico';

  @override
  String get authSignUpTitle => 'Crear cuenta';

  @override
  String get authSignUpSubtitle => 'Únete a Transitly';

  @override
  String get authSignUpButton => 'CREAR CUENTA';

  @override
  String get authSignUpError => 'Error al registrarse';

  @override
  String get authAlreadyHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get authSignInLink => 'Inicia sesión';

  @override
  String get signupAgeGateTitle => 'Verificación de edad';

  @override
  String get signupAgeGateUnder16 => 'Debes tener al menos 16 años';

  @override
  String get signupAgeGateLabel => 'Fecha de nacimiento';

  @override
  String get authRecoverTitle => 'Recuperar contraseña';

  @override
  String get authRecoverSent =>
      'Si el email existe, recibirás un enlace para restablecer tu contraseña.';

  @override
  String get authRecoverHint => 'Introduce tu email y te enviaremos un enlace';

  @override
  String get authSendLinkButton => 'ENVIAR ENLACE';

  @override
  String get authBackToSignIn => 'Volver al inicio de sesión';

  @override
  String get authRecoverError => 'Error al enviar la recuperación';

  @override
  String get authMagicLinkTitle => 'Enlace mágico';

  @override
  String get authMagicLinkSent =>
      'Revisa tu email. Te hemos enviado un enlace para acceder.';

  @override
  String get authMagicLinkHint => 'Te enviamos un enlace de acceso a tu email';

  @override
  String get authMagicLinkError => 'Error al enviar el enlace';

  @override
  String get authVerifyTitle => 'Verifica tu email';

  @override
  String get authVerifyMessage =>
      'Te hemos enviado un email de verificación. Revisa tu bandeja de entrada y haz clic en el enlace para continuar.';

  @override
  String get authResendButton => 'REENVIAR EMAIL';

  @override
  String get authSignOutAndBack => 'Cerrar sesión y volver';

  @override
  String get authResendSuccess => 'Email de verificación reenviado.';

  @override
  String get authResendError => 'Error al reenviar';

  @override
  String get authActivateDriverTitle => 'Activar modo conductor';

  @override
  String get authActivateDriverHint =>
      'Tu compañía te ha dado un código.\nIntrodúcelo aquí para activar el modo conductor.';

  @override
  String get authActivateNeedLogin =>
      'Necesitas iniciar sesión para activar el modo conductor.';

  @override
  String get authActivateButton => 'ACTIVAR';

  @override
  String get authActivateEnterCode => 'Introduce el código';

  @override
  String get authActivateCodeNotFound => 'Código no encontrado';

  @override
  String get authActivateCodeExpired => 'El código ha expirado';

  @override
  String get authActivateCodeDepleted =>
      'El código ya no tiene usos disponibles';

  @override
  String get authActivateError => 'Error al activar el código';

  @override
  String get authActivateNeedSession => 'Necesitas iniciar sesión primero';

  @override
  String get authActivateSuccess =>
      'Bienvenido. Ya puedes usar el modo conductor.';

  @override
  String get authSignOutTitle => '¿Cerrar sesión?';

  @override
  String get authSignOutMessage =>
      'Volverás a la pantalla de inicio de sesión.';

  @override
  String get authSignOutCancel => 'CANCELAR';

  @override
  String get authSignOutConfirm => 'CERRAR SESIÓN';

  @override
  String get authDeleteAccountTitle => '¿Eliminar cuenta?';

  @override
  String get authDeleteAccountMessage => 'Esta acción es irreversible.';

  @override
  String get authDeleteAccountButton => 'ELIMINAR';

  @override
  String get authDeleteAccountError => 'No se pudo eliminar la cuenta';

  @override
  String get authDeleteAccountCancel => 'CANCELAR';

  @override
  String get filterPresetsTitle => 'Filtros predefinidos';

  @override
  String get filterPresetsEmptyTitle => 'Sin presets guardados';

  @override
  String get filterPresetsEmptySubtitle =>
      'Guarda la combinación de filtros del mapa que más uses para aplicarla con un toque.';

  @override
  String get filterPresetsActionSave => 'GUARDAR FILTROS ACTUALES';

  @override
  String get filterPresetsTileHint => 'Tocar para aplicar';

  @override
  String get filterPresetsTileDelete => 'Eliminar';

  @override
  String get filterPresetsDialogTitle => 'Guardar filtros';

  @override
  String get filterPresetsDialogHint => 'Nombre del preset';

  @override
  String get filterPresetsDialogConfirm => 'GUARDAR';

  @override
  String filterPresetsApplied(String name) {
    return 'Filtros «$name» aplicados';
  }

  @override
  String get driverStatsTitle => 'Estadísticas';

  @override
  String get driverStatsEmptyTitle => 'Sin datos aún';

  @override
  String get driverStatsEmptySubtitle =>
      'Tus estadísticas se calculan a partir del historial de viajes.';

  @override
  String get driverStatsTrips => 'Viajes';

  @override
  String get driverStatsDistinctLines => 'Líneas distintas';

  @override
  String get driverStatsTotalCost => 'Coste total';

  @override
  String get driverStatsDistance => 'Distancia';

  @override
  String get driverStatsCo2Saved => 'CO₂ ahorrado';

  @override
  String get driverHistoryTitle => 'Historial de conductor';

  @override
  String get driverHistoryEmptyTitle => 'Sin viajes todavía';

  @override
  String get driverHistoryEmptySubtitle =>
      'Cuando completes rutas aparecerán aquí con su trayecto y coste.';

  @override
  String get driverHistoryUnknownRoute => 'Ruta desconocida';

  @override
  String get plannedTripsTitle => 'Viajes planificados';

  @override
  String get plannedTripsEmptyTitle => 'Sin viajes planificados';

  @override
  String get plannedTripsEmptySubtitle =>
      'Marca una ruta como favorita y configura un aviso para verla aquí como viaje habitual.';

  @override
  String get plannedTripsNoStop => 'Parada no definida';

  @override
  String plannedTripsFrom(String stop) {
    return 'Desde $stop';
  }

  @override
  String get aiScheduleImportTitle => 'Importar horario';

  @override
  String get aiScheduleImportEmptyTitle => 'Importar horarios';

  @override
  String get aiScheduleImportEmptySubtitle =>
      'Pega el texto de un horario para extraer las horas de salida automáticamente.';

  @override
  String get aiScheduleImportHint =>
      'Pega el horario y se extraerán las horas de salida. El análisis es local (demo): detecta patrones HH:MM, no usa IA ni backend.';

  @override
  String get aiScheduleImportFieldHint => 'Ej.: 06:00  06:30  07:00 ...';

  @override
  String get aiScheduleImportAnalyze => 'ANALIZAR';

  @override
  String get aiScheduleImportNoTimes => 'No se detectaron horas';

  @override
  String aiScheduleImportDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count salidas detectadas',
      one: '1 salida detectada',
    );
    return '$_temp0';
  }

  @override
  String get suggestionContributeTitle => 'Contribuir a sugerencias';

  @override
  String get suggestionContributeEmptyTitle => 'Nada que contribuir ahora';

  @override
  String get suggestionContributeEmptySubtitle =>
      'No hay sugerencias abiertas. Vuelve más tarde o propón una ruta nueva desde la pestaña de sugerencias.';

  @override
  String get cityPickerErrorOperators => 'Error al cargar operadores';

  @override
  String get driversErrorLoading => 'Error al cargar conductores';

  @override
  String get driversErrorRevoking => 'Error al revocar conductor';

  @override
  String get invitationCodesErrorLoading => 'Error al cargar códigos';

  @override
  String get invitationCodesErrorGenerating => 'Error al generar código';

  @override
  String get invitationCodesErrorRevoking => 'Error al revocar código';

  @override
  String get routeOfficializeError => 'Error al enviar solicitud';

  @override
  String get routeShareUserNotFound => 'Usuario no encontrado';

  @override
  String routeShareSuccess(String email) {
    return 'Ruta compartida con $email';
  }

  @override
  String get routeShareError => 'Error al compartir ruta';

  @override
  String get routeShareErrorGeneratingLink => 'Error al generar enlace';

  @override
  String get routeDetailNotFound => 'Ruta no encontrada';

  @override
  String get routeDetailAddFavorite => 'AÑADIR A MIS LÍNEAS ★';

  @override
  String get routeDetailRemoveFavorite => 'EN MIS LÍNEAS ✓';

  @override
  String get favoriteAdded => 'Línea añadida a tus favoritas';

  @override
  String get favoriteRemoved => 'Línea eliminada de tus favoritas';

  @override
  String get stopDetailNotFound => 'Parada no encontrada';

  @override
  String get feedbackErrorSending => 'Error al enviar mejora';

  @override
  String get incidentErrorSending => 'Error al enviar reporte';

  @override
  String homeRouteSemanticsLabel(String code, String time) {
    return '$code, $time';
  }

  @override
  String nfcCardBalance(String amount) {
    return 'Saldo: $amount euros';
  }

  @override
  String homeNextBusSemantics(String route) {
    return 'Tu próximo bus, $route';
  }

  @override
  String generalComingSoon(String feature) {
    return '$feature: próximamente';
  }

  @override
  String capacitySemanticsLabel(String level) {
    return 'Ocupación: $level';
  }

  @override
  String reputationSemanticsLabel(String level) {
    return 'Reputación: $level';
  }

  @override
  String reputationScoreSemantics(String label, int score) {
    return '$label: $score puntos';
  }

  @override
  String routeCardSemantics(
    String code,
    String name,
    String status,
    String minutes,
  ) {
    return 'Línea $code, $name$status$minutes';
  }

  @override
  String get adminPanelTitle => 'Panel de administración';

  @override
  String get adminPanelSubtitle => 'Gestiona la plataforma';

  @override
  String get cityPickerSelectOperator => 'Seleccionar operador';

  @override
  String get driverPermissionRequired => 'Permiso de ubicación requerido';

  @override
  String get driverModeLabel => 'Modo conductor';

  @override
  String driverGreeting(String name) {
    return 'Hola $name';
  }

  @override
  String driverCurrentOperator(String name) {
    return 'Operador: $name';
  }

  @override
  String get driverSelectRoute => 'Seleccionar ruta';

  @override
  String get driverNoRoutesLoaded => 'Sin rutas cargadas';

  @override
  String get driverChooseAnother => 'Elegir otra';

  @override
  String envErrorLabel(String name) {
    return 'Error: $name';
  }

  @override
  String envKeyLabel(String key) {
    return 'Clave: $key';
  }

  @override
  String get feedbackSelectCategoryFirst => 'Selecciona una categoría primero';

  @override
  String get feedbackEnterDescription => 'Escribe una descripción';

  @override
  String get feedbackSent => 'Feedback enviado · Gracias';

  @override
  String get routeFeedbackImprovementSent => 'Mejora enviada. ¡Gracias!';

  @override
  String get mapSearchComingSoon => 'Búsqueda en mapa: próximamente';

  @override
  String get profileDeleteAccount => 'Eliminar cuenta';

  @override
  String get profileCreateAccount => 'Crear cuenta';

  @override
  String get profileColorBlindModeNone => 'Modo: Ninguno';

  @override
  String get profileDarkMode => 'Modo oscuro';

  @override
  String get incidentReportSent =>
      'Reporte enviado. Gracias por tu colaboración.';

  @override
  String inviteCodeGenerated(String code) {
    return 'Código generado: $code';
  }

  @override
  String get inviteGenerateCode => 'Generar código';

  @override
  String get operatorPanelTitle => 'Panel del operador';

  @override
  String get operatorPanelSubtitle => 'Gestiona tu operador de transporte';

  @override
  String get routeChangelogEmpty => 'Sin cambios recientes';

  @override
  String get routeFeedbackThanksConfirming => '¡Gracias por confirmar!';

  @override
  String get routeNoUpcomingSchedules => 'Sin horarios próximos';

  @override
  String get stopNoLinesRegistered => 'Sin líneas registradas';

  @override
  String get suggestRouteSent => 'Sugerencia enviada · Te avisaremos';

  @override
  String suggestRouteSubmitError(String error) {
    return 'Error al enviar: $error';
  }

  @override
  String get searchEmptyTitle => 'Escribe un origen y un destino';

  @override
  String get searchEmptySubtitle => 'Te mostraremos las rutas más rápidas';

  @override
  String get searchUnderConstructionTitle => 'Buscador en construcción';

  @override
  String get searchUnderConstructionSubtitle =>
      'Mientras tanto, puedes sugerirnos rutas';

  @override
  String get searchReportRouteAction => 'Sugerir ruta';

  @override
  String get driverPanelTitle => 'MODO CONDUCTOR';

  @override
  String get driverPanelStartRoute => 'Iniciar ruta';

  @override
  String get driverPanelActiveRoute => 'Ruta activa';

  @override
  String get driverPanelCreateManualRoute => 'Crear ruta manual';

  @override
  String get driverPanelCreateLiveRoute => 'Crear ruta en vivo';

  @override
  String get driverPanelMyRoutes => 'Mis rutas';

  @override
  String get driverPanelImportSchedules => 'Importar horarios';

  @override
  String get driverPanelManagementInbox => 'Bandeja de gestión';

  @override
  String get driverActiveNoActiveRoute => 'No hay ruta activa';

  @override
  String get driverActiveRouteHeader => 'RUTA ACTIVA';

  @override
  String driverActiveRouteStartedAt(String code, String time) {
    return '$code · $time INICIO';
  }

  @override
  String get driverActiveNextStopHeader => 'PRÓXIMA PARADA';

  @override
  String driverActiveStopRegisteredFmt(String time) {
    return 'PARADA REGISTRADA · $time';
  }

  @override
  String get driverActiveRegisterStop => 'REGISTRAR PARADA';

  @override
  String get driverActiveIncidentButton => 'INCIDENCIA';

  @override
  String get driverActiveFinishRouteButton => 'FINALIZAR RUTA';

  @override
  String get driverActiveFinishConfirmTitle => '¿Finalizar ruta?';

  @override
  String get driverActiveFinishConfirmMessage =>
      'Se registrará la ruta como completada.';

  @override
  String get driverActiveFinishConfirmButton => 'FINALIZAR';

  @override
  String get driverStartTitle => 'INICIAR RUTA';

  @override
  String driverStartSuggestionFmt(String code, String time, String day) {
    return 'SUGERENCIA: $code · $time · $day';
  }

  @override
  String get driverStartIsThisYourRoute => '¿Es tu ruta?';

  @override
  String get driverStartYesStart => 'SÍ, INICIAR';

  @override
  String get driverStartSelectLine => 'SELECCIONA LÍNEA';

  @override
  String get driverStartSelectSchedule => 'SELECCIONA HORARIO';

  @override
  String driverStartDepartureFmt(String time) {
    return 'Salida: $time';
  }

  @override
  String driverStartStopsAndTime(int count, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paradas',
      one: '1 parada',
    );
    return '$_temp0 · ~$minutes min';
  }

  @override
  String get driverStartStartButton => 'INICIAR RUTA';

  @override
  String feedbackScreenTitleFmt(String code) {
    return 'FEEDBACK · $code';
  }

  @override
  String get feedbackDescriptionLabel => 'Descripción';

  @override
  String get feedbackDescriptionHint => 'Descripción de lo que has encontrado';

  @override
  String get feedbackCategoryRouteLabel => 'El recorrido en el mapa';

  @override
  String get feedbackCategoryStopsLabel =>
      'Una parada (falta, sobra o está mal)';

  @override
  String get feedbackCategorySchedulesLabel => 'Los horarios';

  @override
  String get feedbackCategoryInfoLabel => 'Información general';

  @override
  String get feedbackCategorySuggestionLabel => 'Tengo una sugerencia';

  @override
  String get suggestRouteScreenTitle => 'SUGERIR RUTA';

  @override
  String get suggestRouteHelpText =>
      'Ayúdanos a completar el mapa de transporte';

  @override
  String get suggestRouteFromLabel => 'Desde';

  @override
  String get suggestRouteFromHint => 'Origen';

  @override
  String get suggestRouteToLabel => 'Hasta';

  @override
  String get suggestRouteToHint => 'Destino';

  @override
  String get suggestRouteOperatorLabel => '¿Operador?';

  @override
  String get suggestRouteOperatorComujesa => 'COMUJESA';

  @override
  String get suggestRouteOperatorOther => 'Otra';

  @override
  String get suggestRouteOperatorDontKnow => 'No lo sé';

  @override
  String get suggestRouteCodeLabel => 'Código de línea';

  @override
  String get suggestRouteCodeHint => 'Ej: M-250';

  @override
  String get suggestRouteHowKnow => '¿Cómo lo sabes?';

  @override
  String get suggestRouteSourceUseIt => 'La uso';

  @override
  String get suggestRouteSourceSawIt => 'La he visto';

  @override
  String get suggestRouteSourceTold => 'Me lo dijeron';

  @override
  String get suggestRouteSourceWeb => 'Web oficial';

  @override
  String get suggestRouteAddDetails => 'Añadir más detalles';

  @override
  String get suggestRouteStopsRemember => 'Paradas que recuerdas';

  @override
  String suggestRouteStopNumber(int number) {
    return 'Parada $number';
  }

  @override
  String get suggestRouteAddStop => '+ Añadir parada';

  @override
  String get suggestRouteTimesKnown => 'Horas que conoces';

  @override
  String get suggestRouteNotesLabel => 'Notas';

  @override
  String get suggestRouteNotesHint => 'Cualquier detalle adicional...';

  @override
  String get suggestRouteAddTimeTitle => 'Añadir hora';

  @override
  String get suggestRouteAddTimeHint => 'HH:MM';

  @override
  String get suggestRouteAddTimeConfirm => 'AÑADIR';

  @override
  String get incidentSheetTitle => '¿QUÉ HA PASADO?';

  @override
  String get incidentNoShow => 'No pasó';

  @override
  String get incidentDelay => 'Retraso';

  @override
  String get incidentFull => 'Lleno';

  @override
  String get incidentDetour => 'Desvío';

  @override
  String get incidentBreakdown => 'Avería';

  @override
  String get incidentOther => 'Otro';

  @override
  String get incidentPositiveLabel => 'POSITIVO:';

  @override
  String get incidentPunctual => 'Puntual';

  @override
  String get incidentKind => 'Amable';

  @override
  String get incidentClean => 'Limpio';

  @override
  String get incidentCommentHint => 'Comentario (opcional)';

  @override
  String get driverStartTrip => 'Iniciar viaje';

  @override
  String get driverSelectRouteFirst => 'Selecciona una ruta';

  @override
  String get driverLoadRoutes => 'Cargar rutas';

  @override
  String get routeShareTitle => 'Compartir ruta';

  @override
  String get routeShareWithUser => 'Compartir con usuario';

  @override
  String get routeShareEmailHint => 'email@ejemplo.com';

  @override
  String get routeSharePublicLink => 'Enlace público';

  @override
  String get routeShareGenerateLink => 'Generar enlace';

  @override
  String get routeShareRegenerateLink => 'Regenerar enlace';

  @override
  String get routeShareNeedLogin => 'Inicia sesión para compartir rutas';

  @override
  String get routeShareLinkGenerated => 'Enlace generado';

  @override
  String get mapFilterTitle => 'Filtros del mapa';

  @override
  String get mapFilterRouteSource => 'Origen de la ruta';

  @override
  String get mapFilterOfficial => 'Oficiales';

  @override
  String get mapFilterCommunity => 'Comunitarias';

  @override
  String get mapFilterUpcoming => 'Próximas salidas';

  @override
  String mapFilterMinutes(int m) {
    return '$m min';
  }

  @override
  String get mapFilterAccessibility => 'Accesibilidad';

  @override
  String get mapFilterOnlyAccessible => 'Solo accesibles';

  @override
  String get mapFilterFavorites => 'Favoritos';

  @override
  String get mapFilterOnlyFavorites => 'Solo favoritos';

  @override
  String get myContributionsTitle => 'Mis contribuciones';

  @override
  String get myContributionsReload => 'Recargar';

  @override
  String myContributionsSummary(int suggestions, int feedbacks, int reports) {
    return '$suggestions sugerencias · $feedbacks feedbacks · $reports reportes';
  }

  @override
  String get myContributionsLabelSuggestions => 'sugerencias';

  @override
  String get myContributionsLabelCorrections => 'correcciones';

  @override
  String get myContributionsLabelReports => 'reportes';

  @override
  String get myContributionsLabelPhotos => 'fotos';

  @override
  String get myContributionsTabSuggestions => 'Sugerencias';

  @override
  String get myContributionsTabFeedback => 'Feedback';

  @override
  String get myContributionsTabReports => 'Reportes';

  @override
  String get myContributionsEmptyFeedback => 'Sin feedback';

  @override
  String get myContributionsEmptyFeedbackSubtitle =>
      'Tu feedback enviado aparecerá aquí';

  @override
  String get myContributionsEmptyReports => 'Sin reportes';

  @override
  String get myContributionsEmptyReportsSubtitle =>
      'Tus reportes de incidencias aparecerán aquí';

  @override
  String get myContributionsLocalDraft => 'Borrador local';

  @override
  String get myContributionsNoDescription => 'Sin descripción';

  @override
  String get reputationCurrentRank => 'Actual';

  @override
  String get appTagline => 'TU TRANSPORTE PÚBLICO';

  @override
  String get homeSectionNearbyStops => 'PARADAS CERCA DE TI';

  @override
  String get homeSectionMyLines => 'MIS LÍNEAS';

  @override
  String get homeSectionAlerts => 'AVISOS';

  @override
  String get homeSectionNextBus => 'TU PRÓXIMO BUS';

  @override
  String get homeChangeCityTooltip => 'Cambiar ciudad';

  @override
  String get homeDefaultCity => 'Jerez de la Frontera';

  @override
  String get accessibilityThemeSystemSubtitle =>
      'Sigue la configuración del dispositivo';

  @override
  String get accessibilityThemeLightSubtitle =>
      'Fondo luminoso, alto contraste diurno';

  @override
  String get accessibilityThemeDarkSubtitle =>
      'Fondo oscuro, menor consumo en OLED';

  @override
  String get accessibilityLanguageSystemSubtitle =>
      'Sigue el idioma del dispositivo';

  @override
  String get accessibilityLanguageEsSubtitle => 'Forzar idioma en español';

  @override
  String get accessibilityLanguageEnSubtitle => 'Force English language';

  @override
  String get accessibilitySystemPrefAnimations => 'Animaciones';

  @override
  String get accessibilitySystemPrefTextSize => 'Tamaño de texto';

  @override
  String get accessibilitySystemPrefBoldText => 'Texto en negrita';

  @override
  String get accessibilitySystemPrefActivated => 'Activado';

  @override
  String get accessibilitySystemPrefDeactivated => 'Desactivado';

  @override
  String get accessibilitySystemPrefReduced => 'Reducidas';

  @override
  String get accessibilitySystemPrefEnabled => 'Habilitadas';

  @override
  String get accessibilitySystemPrefFootnote =>
      'Estos ajustes se leen del sistema operativo. Cámbialos desde los ajustes del dispositivo para que la app responda.';

  @override
  String get operatorAdminMissingOperator =>
      'No se encontró el operador asociado a tu cuenta. Contacta con soporte.';

  @override
  String get adminUsersLoadError =>
      'No se pudo cargar la lista de usuarios. Inténtalo de nuevo.';

  @override
  String get offlineRegionDemoLimitation =>
      'Versión demo: solo se puede descargar la región de Jerez de la Frontera. Selección libre de región disponible en próximas versiones.';

  @override
  String get editorDraftSaved => 'Borrador guardado correctamente';
}
