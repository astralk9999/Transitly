import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
  ];

  /// App display name
  ///
  /// In es, this message translates to:
  /// **'Transitly'**
  String get appTitle;

  /// Bottom nav: Home tab
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get tabHome;

  /// Bottom nav: Search tab
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get tabSearch;

  /// Bottom nav: Map tab
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get tabMap;

  /// Bottom nav: NFC card tab
  ///
  /// In es, this message translates to:
  /// **'Tarjeta'**
  String get tabCard;

  /// Bottom nav: Profile tab
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get tabProfile;

  /// No description provided for @nfcErrorUnsupported.
  ///
  /// In es, this message translates to:
  /// **'NFC no disponible en este dispositivo'**
  String get nfcErrorUnsupported;

  /// No description provided for @nfcErrorNotMifareClassic.
  ///
  /// In es, this message translates to:
  /// **'Esta tarjeta no es compatible'**
  String get nfcErrorNotMifareClassic;

  /// No description provided for @nfcErrorAuthFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo autenticar la tarjeta'**
  String get nfcErrorAuthFailed;

  /// No description provided for @nfcErrorReadFailed.
  ///
  /// In es, this message translates to:
  /// **'Error al leer la tarjeta'**
  String get nfcErrorReadFailed;

  /// No description provided for @nfcErrorTagLost.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta retirada demasiado pronto'**
  String get nfcErrorTagLost;

  /// No description provided for @nfcErrorUnknown.
  ///
  /// In es, this message translates to:
  /// **'Error desconocido'**
  String get nfcErrorUnknown;

  /// No description provided for @profileSectionAppearance.
  ///
  /// In es, this message translates to:
  /// **'APARIENCIA'**
  String get profileSectionAppearance;

  /// No description provided for @profileSectionDemoProfile.
  ///
  /// In es, this message translates to:
  /// **'PERFIL DE DEMO'**
  String get profileSectionDemoProfile;

  /// No description provided for @profileSectionAccessibility.
  ///
  /// In es, this message translates to:
  /// **'ACCESIBILIDAD'**
  String get profileSectionAccessibility;

  /// No description provided for @profileSectionOfflineData.
  ///
  /// In es, this message translates to:
  /// **'DATOS OFFLINE'**
  String get profileSectionOfflineData;

  /// No description provided for @profileSectionAbout.
  ///
  /// In es, this message translates to:
  /// **'ACERCA DE'**
  String get profileSectionAbout;

  /// No description provided for @accessibilityTitle.
  ///
  /// In es, this message translates to:
  /// **'Accesibilidad'**
  String get accessibilityTitle;

  /// No description provided for @accessibilityThemeSection.
  ///
  /// In es, this message translates to:
  /// **'TEMA'**
  String get accessibilityThemeSection;

  /// No description provided for @accessibilityThemeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get accessibilityThemeSystem;

  /// No description provided for @accessibilityThemeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get accessibilityThemeLight;

  /// No description provided for @accessibilityThemeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get accessibilityThemeDark;

  /// No description provided for @accessibilitySystemPreferencesSection.
  ///
  /// In es, this message translates to:
  /// **'PREFERENCIAS DEL SISTEMA'**
  String get accessibilitySystemPreferencesSection;

  /// No description provided for @accessibilityLanguageSection.
  ///
  /// In es, this message translates to:
  /// **'IDIOMA'**
  String get accessibilityLanguageSection;

  /// No description provided for @accessibilityLanguageEs.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get accessibilityLanguageEs;

  /// No description provided for @accessibilityLanguageEn.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get accessibilityLanguageEn;

  /// No description provided for @accessibilityLanguageSystem.
  ///
  /// In es, this message translates to:
  /// **'Seguir idioma del sistema'**
  String get accessibilityLanguageSystem;

  /// No description provided for @offlineDataTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos offline'**
  String get offlineDataTitle;

  /// No description provided for @offlineDataContent.
  ///
  /// In es, this message translates to:
  /// **'CONTENIDO'**
  String get offlineDataContent;

  /// No description provided for @offlineDataArchive.
  ///
  /// In es, this message translates to:
  /// **'ARCHIVO'**
  String get offlineDataArchive;

  /// No description provided for @offlineDataReload.
  ///
  /// In es, this message translates to:
  /// **'Recargar desde assets'**
  String get offlineDataReload;

  /// No description provided for @offlineDataReloaded.
  ///
  /// In es, this message translates to:
  /// **'Datos recargados'**
  String get offlineDataReloaded;

  /// No description provided for @offlineDataSize.
  ///
  /// In es, this message translates to:
  /// **'Tamaño'**
  String get offlineDataSize;

  /// No description provided for @offlineDataLoaded.
  ///
  /// In es, this message translates to:
  /// **'Cargado'**
  String get offlineDataLoaded;

  /// No description provided for @offlineDataRoutes.
  ///
  /// In es, this message translates to:
  /// **'Rutas'**
  String get offlineDataRoutes;

  /// No description provided for @offlineDataStops.
  ///
  /// In es, this message translates to:
  /// **'Paradas'**
  String get offlineDataStops;

  /// No description provided for @actionClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get actionClose;

  /// No description provided for @actionRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get actionRetry;

  /// No description provided for @actionCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get actionSave;

  /// No description provided for @actionSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get actionSend;

  /// No description provided for @actionDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get actionDelete;

  /// No description provided for @actionBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get actionBack;

  /// No description provided for @actionSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get actionSignOut;

  /// No description provided for @actionSaveDraft.
  ///
  /// In es, this message translates to:
  /// **'Guardar borrador'**
  String get actionSaveDraft;

  /// No description provided for @actionSendSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Enviar sugerencia'**
  String get actionSendSuggestion;

  /// No description provided for @actionSendFeedback.
  ///
  /// In es, this message translates to:
  /// **'Enviar feedback'**
  String get actionSendFeedback;

  /// No description provided for @actionSendImprovement.
  ///
  /// In es, this message translates to:
  /// **'Enviar mejora'**
  String get actionSendImprovement;

  /// No description provided for @actionSendRequest.
  ///
  /// In es, this message translates to:
  /// **'Enviar solicitud'**
  String get actionSendRequest;

  /// No description provided for @actionSending.
  ///
  /// In es, this message translates to:
  /// **'Enviando...'**
  String get actionSending;

  /// No description provided for @sectionUpcomingArrivals.
  ///
  /// In es, this message translates to:
  /// **'PRÓXIMAS LLEGADAS'**
  String get sectionUpcomingArrivals;

  /// No description provided for @sectionSchedules.
  ///
  /// In es, this message translates to:
  /// **'HORARIOS'**
  String get sectionSchedules;

  /// No description provided for @sectionRecentChanges.
  ///
  /// In es, this message translates to:
  /// **'CAMBIOS RECIENTES'**
  String get sectionRecentChanges;

  /// No description provided for @routeDayWeekday.
  ///
  /// In es, this message translates to:
  /// **'Laborable'**
  String get routeDayWeekday;

  /// No description provided for @routeDaySaturday.
  ///
  /// In es, this message translates to:
  /// **'Sábado'**
  String get routeDaySaturday;

  /// No description provided for @routeDaySunday.
  ///
  /// In es, this message translates to:
  /// **'Domingo'**
  String get routeDaySunday;

  /// No description provided for @routeDayHoliday.
  ///
  /// In es, this message translates to:
  /// **'Festivo'**
  String get routeDayHoliday;

  /// No description provided for @stopLinesHeader.
  ///
  /// In es, this message translates to:
  /// **'LÍNEAS'**
  String get stopLinesHeader;

  /// No description provided for @routeTimeline.
  ///
  /// In es, this message translates to:
  /// **'RECORRIDO'**
  String get routeTimeline;

  /// No description provided for @editorStepInfo.
  ///
  /// In es, this message translates to:
  /// **'Información'**
  String get editorStepInfo;

  /// No description provided for @editorStepTrace.
  ///
  /// In es, this message translates to:
  /// **'Trazado'**
  String get editorStepTrace;

  /// No description provided for @editorStepStops.
  ///
  /// In es, this message translates to:
  /// **'Paradas'**
  String get editorStepStops;

  /// No description provided for @editorStepReturn.
  ///
  /// In es, this message translates to:
  /// **'Vuelta'**
  String get editorStepReturn;

  /// No description provided for @editorStepReview.
  ///
  /// In es, this message translates to:
  /// **'Revisión'**
  String get editorStepReview;

  /// No description provided for @actionNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get actionNext;

  /// No description provided for @actionConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get actionConfirm;

  /// No description provided for @actionAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get actionAdd;

  /// No description provided for @actionPause.
  ///
  /// In es, this message translates to:
  /// **'Pausar'**
  String get actionPause;

  /// No description provided for @actionResume.
  ///
  /// In es, this message translates to:
  /// **'Reanudar'**
  String get actionResume;

  /// No description provided for @actionFinish.
  ///
  /// In es, this message translates to:
  /// **'Finalizar'**
  String get actionFinish;

  /// No description provided for @actionUndo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get actionUndo;

  /// No description provided for @actionPublish.
  ///
  /// In es, this message translates to:
  /// **'Publicar'**
  String get actionPublish;

  /// No description provided for @actionGenerate.
  ///
  /// In es, this message translates to:
  /// **'Generar'**
  String get actionGenerate;

  /// No description provided for @actionRevoke.
  ///
  /// In es, this message translates to:
  /// **'Revocar'**
  String get actionRevoke;

  /// No description provided for @actionShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get actionShare;

  /// No description provided for @actionApply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get actionApply;

  /// No description provided for @actionReset.
  ///
  /// In es, this message translates to:
  /// **'Restablecer'**
  String get actionReset;

  /// No description provided for @actionStop.
  ///
  /// In es, this message translates to:
  /// **'Detener'**
  String get actionStop;

  /// No description provided for @actionContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get actionContinue;

  /// No description provided for @actionFollow.
  ///
  /// In es, this message translates to:
  /// **'Seguir'**
  String get actionFollow;

  /// Placeholder para features en construcción
  ///
  /// In es, this message translates to:
  /// **'Funcionalidad disponible en próxima versión.'**
  String get featureComingSoon;

  /// No description provided for @statusPaused.
  ///
  /// In es, this message translates to:
  /// **'PAUSADO'**
  String get statusPaused;

  /// No description provided for @statusLive.
  ///
  /// In es, this message translates to:
  /// **'EN VIVO'**
  String get statusLive;

  /// No description provided for @statusRecordingRoute.
  ///
  /// In es, this message translates to:
  /// **'GRABANDO RUTA'**
  String get statusRecordingRoute;

  /// Live route recorder: mark-stop big button
  ///
  /// In es, this message translates to:
  /// **'MARCAR PARADA'**
  String get recorderMarkStop;

  /// Live route recorder: stop marked snackbar
  ///
  /// In es, this message translates to:
  /// **'PARADA #{number} MARCADA · {distance} km'**
  String recorderStopMarkedFmt(int number, String distance);

  /// Admin users screen title
  ///
  /// In es, this message translates to:
  /// **'Gestión de usuarios'**
  String get adminUsersTitle;

  /// Admin users search hint
  ///
  /// In es, this message translates to:
  /// **'Buscar usuario...'**
  String get adminUsersSearchHint;

  /// Admin users filter: all roles
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get adminUsersFilterAll;

  /// Admin users empty state
  ///
  /// In es, this message translates to:
  /// **'No se encontraron usuarios'**
  String get adminUsersEmpty;

  /// Admin users offline message
  ///
  /// In es, this message translates to:
  /// **'Conecta a internet para gestionar usuarios'**
  String get adminUsersOffline;

  /// Role label: Admin
  ///
  /// In es, this message translates to:
  /// **'Admin'**
  String get adminUsersRoleAdmin;

  /// Role label: Moderator
  ///
  /// In es, this message translates to:
  /// **'Moderador'**
  String get adminUsersRoleModerator;

  /// Role label: Operator Admin
  ///
  /// In es, this message translates to:
  /// **'Operador Admin'**
  String get adminUsersRoleOperatorAdmin;

  /// Role label: Driver
  ///
  /// In es, this message translates to:
  /// **'Conductor'**
  String get adminUsersRoleDriver;

  /// Role label: Passenger
  ///
  /// In es, this message translates to:
  /// **'Pasajero'**
  String get adminUsersRolePassenger;

  /// Role filter label: All roles
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get adminUsersRoleAll;

  /// Admin users error loading
  ///
  /// In es, this message translates to:
  /// **'Error al cargar usuarios'**
  String get adminUsersError;

  /// Admin users no connection title
  ///
  /// In es, this message translates to:
  /// **'Sin conexión'**
  String get adminUsersNoConnection;

  /// Admin users no search results title
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get adminUsersNoResults;

  /// Admin users search no match text
  ///
  /// In es, this message translates to:
  /// **'No hay usuarios que coincidan con \"{query}\"'**
  String adminUsersNoMatchSearch(String query);

  /// Admin users role filter no match text
  ///
  /// In es, this message translates to:
  /// **'No hay usuarios con el rol seleccionado'**
  String get adminUsersNoMatchRole;

  /// Admin operators screen title
  ///
  /// In es, this message translates to:
  /// **'Gestión de operadores'**
  String get adminOperatorsTitle;

  /// Admin operators create button
  ///
  /// In es, this message translates to:
  /// **'Crear operador'**
  String get adminOperatorsCreate;

  /// Admin operators edit title
  ///
  /// In es, this message translates to:
  /// **'Editar operador'**
  String get adminOperatorsEdit;

  /// Admin operators delete button
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get adminOperatorsDelete;

  /// Admin operators slug field
  ///
  /// In es, this message translates to:
  /// **'Slug'**
  String get adminOperatorsSlug;

  /// Admin operators name field
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get adminOperatorsName;

  /// Admin operators region field
  ///
  /// In es, this message translates to:
  /// **'Región'**
  String get adminOperatorsRegion;

  /// Admin operators website field
  ///
  /// In es, this message translates to:
  /// **'Sitio web'**
  String get adminOperatorsWebsite;

  /// Admin operators contact email field
  ///
  /// In es, this message translates to:
  /// **'Correo de contacto'**
  String get adminOperatorsEmail;

  /// Admin operators delete confirmation
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este operador?'**
  String get adminOperatorsDeleteConfirm;

  /// Admin operators empty state
  ///
  /// In es, this message translates to:
  /// **'No hay operadores registrados'**
  String get adminOperatorsEmpty;

  /// Admin operators created toast
  ///
  /// In es, this message translates to:
  /// **'Operador creado'**
  String get adminOperatorsCreated;

  /// Admin operators updated toast
  ///
  /// In es, this message translates to:
  /// **'Operador actualizado'**
  String get adminOperatorsUpdated;

  /// Admin operators deleted toast
  ///
  /// In es, this message translates to:
  /// **'Operador eliminado'**
  String get adminOperatorsDeleted;

  /// Admin operators error loading
  ///
  /// In es, this message translates to:
  /// **'Error al cargar operadores'**
  String get adminOperatorsError;

  /// Admin operators no connection title
  ///
  /// In es, this message translates to:
  /// **'Sin conexión'**
  String get adminOperatorsNoConnection;

  /// Admin operators offline message
  ///
  /// In es, this message translates to:
  /// **'Conecta a internet para gestionar operadores'**
  String get adminOperatorsOffline;

  /// Admin operators permission denied error
  ///
  /// In es, this message translates to:
  /// **'Permiso denegado para gestionar operadores'**
  String get adminOperatorsErrorDenied;

  /// Admin operators network error
  ///
  /// In es, this message translates to:
  /// **'Error de red al cargar operadores'**
  String get adminOperatorsErrorNetwork;

  /// No description provided for @adminOperatorsErrorUnknown.
  ///
  /// In es, this message translates to:
  /// **'Error desconocido al cargar operadores'**
  String get adminOperatorsErrorUnknown;

  /// Manager inbox screen title
  ///
  /// In es, this message translates to:
  /// **'Bandeja de gestión'**
  String get managerInboxTitle;

  /// Manager inbox: feedback tab label
  ///
  /// In es, this message translates to:
  /// **'Feedback'**
  String get managerInboxFeedback;

  /// Manager inbox: suggestions tab label
  ///
  /// In es, this message translates to:
  /// **'Sugerencias'**
  String get managerInboxSuggestions;

  /// Manager inbox: resolved tab label
  ///
  /// In es, this message translates to:
  /// **'Resueltos'**
  String get managerInboxResolved;

  /// Manager inbox pending count
  ///
  /// In es, this message translates to:
  /// **'{count} pendientes'**
  String managerInboxPending(int count);

  /// Manager inbox: mark in review button
  ///
  /// In es, this message translates to:
  /// **'Marcar en revisión'**
  String get managerInboxMarkInReview;

  /// Manager inbox: resolve button
  ///
  /// In es, this message translates to:
  /// **'Resolver'**
  String get managerInboxResolve;

  /// Manager inbox: reject button
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get managerInboxReject;

  /// Manager inbox: empty feedback state
  ///
  /// In es, this message translates to:
  /// **'No hay feedback pendiente'**
  String get managerInboxEmptyFeedback;

  /// Manager inbox: empty suggestions state
  ///
  /// In es, this message translates to:
  /// **'No hay sugerencias'**
  String get managerInboxEmptySuggestions;

  /// Manager inbox: empty resolved state
  ///
  /// In es, this message translates to:
  /// **'No hay elementos resueltos'**
  String get managerInboxEmptyResolved;

  /// Manager inbox: open button
  ///
  /// In es, this message translates to:
  /// **'Abrir'**
  String get managerInboxOpen;

  /// Manager inbox: status label
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get managerInboxStatus;

  /// Manager inbox: description label
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get managerInboxItemDescription;

  /// Manager inbox: date label
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get managerInboxItemDate;

  /// Manager inbox: type label
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get managerInboxItemType;

  /// No description provided for @appearanceTitle.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get appearanceTitle;

  /// No description provided for @appearancePalettesSection.
  ///
  /// In es, this message translates to:
  /// **'PALETAS'**
  String get appearancePalettesSection;

  /// No description provided for @appearanceBrightnessSection.
  ///
  /// In es, this message translates to:
  /// **'BRILLO'**
  String get appearanceBrightnessSection;

  /// No description provided for @appearanceBackgroundSection.
  ///
  /// In es, this message translates to:
  /// **'FONDO'**
  String get appearanceBackgroundSection;

  /// No description provided for @appearanceTextSection.
  ///
  /// In es, this message translates to:
  /// **'TEXTO'**
  String get appearanceTextSection;

  /// No description provided for @appearanceAccessibilitySection.
  ///
  /// In es, this message translates to:
  /// **'ACCESIBILIDAD VISUAL'**
  String get appearanceAccessibilitySection;

  /// No description provided for @appearanceShowBackground.
  ///
  /// In es, this message translates to:
  /// **'Mostrar fondo decorativo'**
  String get appearanceShowBackground;

  /// No description provided for @appearanceBackgroundOpacity.
  ///
  /// In es, this message translates to:
  /// **'Opacidad del fondo'**
  String get appearanceBackgroundOpacity;

  /// No description provided for @appearanceFontScale.
  ///
  /// In es, this message translates to:
  /// **'Tamaño de texto'**
  String get appearanceFontScale;

  /// No description provided for @appearanceDyslexiaFont.
  ///
  /// In es, this message translates to:
  /// **'Fuente para dislexia'**
  String get appearanceDyslexiaFont;

  /// No description provided for @appearanceColorBlindMode.
  ///
  /// In es, this message translates to:
  /// **'Modo daltónico'**
  String get appearanceColorBlindMode;

  /// No description provided for @appearanceReduceMotion.
  ///
  /// In es, this message translates to:
  /// **'Reducir animaciones'**
  String get appearanceReduceMotion;

  /// No description provided for @appearanceResetButton.
  ///
  /// In es, this message translates to:
  /// **'Restaurar valores por defecto'**
  String get appearanceResetButton;

  /// No description provided for @appearanceResetConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Restaurar todos los ajustes de apariencia a sus valores por defecto?'**
  String get appearanceResetConfirm;

  /// No description provided for @appearanceResetDone.
  ///
  /// In es, this message translates to:
  /// **'Ajustes restaurados'**
  String get appearanceResetDone;

  /// No description provided for @appearanceColorBlindNone.
  ///
  /// In es, this message translates to:
  /// **'Ninguno'**
  String get appearanceColorBlindNone;

  /// No description provided for @appearanceColorBlindProtanopia.
  ///
  /// In es, this message translates to:
  /// **'Protanopia'**
  String get appearanceColorBlindProtanopia;

  /// No description provided for @appearanceColorBlindDeuteranopia.
  ///
  /// In es, this message translates to:
  /// **'Deuteranopia'**
  String get appearanceColorBlindDeuteranopia;

  /// No description provided for @appearanceColorBlindTritanopia.
  ///
  /// In es, this message translates to:
  /// **'Tritanopia'**
  String get appearanceColorBlindTritanopia;

  /// No description provided for @appearanceBrightnessSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get appearanceBrightnessSystem;

  /// No description provided for @appearanceBrightnessLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get appearanceBrightnessLight;

  /// No description provided for @appearanceBrightnessDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get appearanceBrightnessDark;

  /// No description provided for @appearanceLinkAppearance.
  ///
  /// In es, this message translates to:
  /// **'Personalizar apariencia'**
  String get appearanceLinkAppearance;

  /// No description provided for @appearanceBgNone.
  ///
  /// In es, this message translates to:
  /// **'Ninguno'**
  String get appearanceBgNone;

  /// No description provided for @appearanceBgSmoke.
  ///
  /// In es, this message translates to:
  /// **'Humo'**
  String get appearanceBgSmoke;

  /// No description provided for @appearanceBgGradient.
  ///
  /// In es, this message translates to:
  /// **'Degradado'**
  String get appearanceBgGradient;

  /// No description provided for @appearanceBgGrid.
  ///
  /// In es, this message translates to:
  /// **'Cuadrícula'**
  String get appearanceBgGrid;

  /// No description provided for @appearanceBgTopo.
  ///
  /// In es, this message translates to:
  /// **'Topografía'**
  String get appearanceBgTopo;

  /// No description provided for @appearanceTextPreview.
  ///
  /// In es, this message translates to:
  /// **'El rápido zorro marrón salta sobre el perro perezoso. Este texto de muestra te permite ver cómo se ve la tipografía con los ajustes actuales.'**
  String get appearanceTextPreview;

  /// No description provided for @appearanceCustomPaletteTitle.
  ///
  /// In es, this message translates to:
  /// **'Paleta personalizada'**
  String get appearanceCustomPaletteTitle;

  /// No description provided for @appearanceCustomPalettePrimary.
  ///
  /// In es, this message translates to:
  /// **'Primario'**
  String get appearanceCustomPalettePrimary;

  /// No description provided for @appearanceCustomPaletteSecondary.
  ///
  /// In es, this message translates to:
  /// **'Secundario'**
  String get appearanceCustomPaletteSecondary;

  /// No description provided for @appearanceCustomPaletteBgRoot.
  ///
  /// In es, this message translates to:
  /// **'Fondo raíz'**
  String get appearanceCustomPaletteBgRoot;

  /// No description provided for @appearanceCustomPaletteBgSurface.
  ///
  /// In es, this message translates to:
  /// **'Fondo superficie'**
  String get appearanceCustomPaletteBgSurface;

  /// No description provided for @appearanceCustomPaletteTextHi.
  ///
  /// In es, this message translates to:
  /// **'Texto principal'**
  String get appearanceCustomPaletteTextHi;

  /// No description provided for @appearanceCustomPalettePreview.
  ///
  /// In es, this message translates to:
  /// **'Vista previa'**
  String get appearanceCustomPalettePreview;

  /// No description provided for @appearanceCustomPaletteContrastPass.
  ///
  /// In es, this message translates to:
  /// **'Contraste AA'**
  String get appearanceCustomPaletteContrastPass;

  /// No description provided for @appearanceCustomPaletteContrastFail.
  ///
  /// In es, this message translates to:
  /// **'Contraste bajo'**
  String get appearanceCustomPaletteContrastFail;

  /// No description provided for @appearanceCustomPaletteSaved.
  ///
  /// In es, this message translates to:
  /// **'Paleta guardada'**
  String get appearanceCustomPaletteSaved;

  /// No description provided for @appearanceCustomPaletteAdd.
  ///
  /// In es, this message translates to:
  /// **'Crear paleta'**
  String get appearanceCustomPaletteAdd;

  /// Appearance map style section header
  ///
  /// In es, this message translates to:
  /// **'ESTILO DE MAPA'**
  String get appearanceMapStyleSection;

  /// Map style: Streets
  ///
  /// In es, this message translates to:
  /// **'Calles'**
  String get mapStyleStreets;

  /// Map style: Basic
  ///
  /// In es, this message translates to:
  /// **'Básico'**
  String get mapStyleBasic;

  /// Map style: Bright
  ///
  /// In es, this message translates to:
  /// **'Brillante'**
  String get mapStyleBright;

  /// Map style: Dark
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get mapStyleDark;

  /// Map style: Light
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get mapStyleLight;

  /// High contrast mode toggle label
  ///
  /// In es, this message translates to:
  /// **'Alto contraste'**
  String get appearanceHighContrast;

  /// High contrast mode toggle subtitle
  ///
  /// In es, this message translates to:
  /// **'Bordes más gruesos y mayor contraste de texto'**
  String get appearanceHighContrastSubtitle;

  /// High contrast mode toggle label in accessibility screen
  ///
  /// In es, this message translates to:
  /// **'Alto contraste'**
  String get accessibilityHighContrast;

  /// Accessible buses screen title
  ///
  /// In es, this message translates to:
  /// **'Buses cercanos'**
  String get accessibleBusesTitle;

  /// Accessible buses empty state title
  ///
  /// In es, this message translates to:
  /// **'Sin buses activos'**
  String get accessibleBusesEmpty;

  /// Accessible buses empty state subtitle
  ///
  /// In es, this message translates to:
  /// **'No se encontraron buses en operación en este momento'**
  String get accessibleBusesNoActiveBuses;

  /// Accessible buses error message
  ///
  /// In es, this message translates to:
  /// **'Error al cargar buses'**
  String get accessibleBusesError;

  /// Accessible buses next stop label
  ///
  /// In es, this message translates to:
  /// **'Próxima parada'**
  String get accessibleBusesNextStop;

  /// Accessible buses source tag: estimated
  ///
  /// In es, this message translates to:
  /// **'Estimado'**
  String get accessibleBusesSourceEstimated;

  /// Accessible buses source tag: driver
  ///
  /// In es, this message translates to:
  /// **'Conductor'**
  String get accessibleBusesSourceDriver;

  /// Accessible buses link in home tab
  ///
  /// In es, this message translates to:
  /// **'Ver lista de buses'**
  String get accessibleBusesLinkLabel;

  /// Onboarding skip button
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get onboardingSkip;

  /// Onboarding next button
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get onboardingNext;

  /// Onboarding get started button
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get onboardingGetStarted;

  /// Onboarding page 1 title
  ///
  /// In es, this message translates to:
  /// **'Transporte en tiempo real'**
  String get onboardingPage1Title;

  /// Onboarding page 1 description
  ///
  /// In es, this message translates to:
  /// **'Consulta dónde está tu autobús ahora mismo, sin esperas innecesarias.'**
  String get onboardingPage1Description;

  /// Onboarding page 2 title
  ///
  /// In es, this message translates to:
  /// **'Tu comunidad te ayuda'**
  String get onboardingPage2Title;

  /// Onboarding page 2 description
  ///
  /// In es, this message translates to:
  /// **'Reporta incidencias, sugiere rutas y ayuda a otros pasajeros como tú.'**
  String get onboardingPage2Description;

  /// Onboarding page 3 title
  ///
  /// In es, this message translates to:
  /// **'Funciona sin internet'**
  String get onboardingPage3Title;

  /// Onboarding page 3 description
  ///
  /// In es, this message translates to:
  /// **'Descarga tus rutas y consulta horarios incluso sin conexión.'**
  String get onboardingPage3Description;

  /// No description provided for @reputationRankNone.
  ///
  /// In es, this message translates to:
  /// **'Sin rango'**
  String get reputationRankNone;

  /// No description provided for @reputationRankNovice.
  ///
  /// In es, this message translates to:
  /// **'Novato'**
  String get reputationRankNovice;

  /// No description provided for @reputationRankContributor.
  ///
  /// In es, this message translates to:
  /// **'Colaborador'**
  String get reputationRankContributor;

  /// No description provided for @reputationRankAdvocate.
  ///
  /// In es, this message translates to:
  /// **'Defensor'**
  String get reputationRankAdvocate;

  /// No description provided for @reputationRankCartographer.
  ///
  /// In es, this message translates to:
  /// **'Cartógrafo'**
  String get reputationRankCartographer;

  /// No description provided for @reputationRankGuardian.
  ///
  /// In es, this message translates to:
  /// **'Guardián'**
  String get reputationRankGuardian;

  /// No description provided for @reputationRankLegend.
  ///
  /// In es, this message translates to:
  /// **'Leyenda'**
  String get reputationRankLegend;

  /// No description provided for @reputationEventIncidentCreated.
  ///
  /// In es, this message translates to:
  /// **'Reporte creado'**
  String get reputationEventIncidentCreated;

  /// No description provided for @reputationEventIncidentRejectedSpam.
  ///
  /// In es, this message translates to:
  /// **'Reporte rechazado (spam)'**
  String get reputationEventIncidentRejectedSpam;

  /// No description provided for @reputationEventFeedbackSubmitted.
  ///
  /// In es, this message translates to:
  /// **'Feedback enviado'**
  String get reputationEventFeedbackSubmitted;

  /// No description provided for @reputationEventFeedbackAccepted.
  ///
  /// In es, this message translates to:
  /// **'Feedback aceptado'**
  String get reputationEventFeedbackAccepted;

  /// No description provided for @reputationEventSuggestionCreated.
  ///
  /// In es, this message translates to:
  /// **'Sugerencia creada'**
  String get reputationEventSuggestionCreated;

  /// No description provided for @reputationEventSuggestionVoteReceived.
  ///
  /// In es, this message translates to:
  /// **'Voto recibido'**
  String get reputationEventSuggestionVoteReceived;

  /// No description provided for @reputationEventSuggestionVerified.
  ///
  /// In es, this message translates to:
  /// **'Sugerencia verificada'**
  String get reputationEventSuggestionVerified;

  /// No description provided for @reputationEventSuggestionOfficial.
  ///
  /// In es, this message translates to:
  /// **'Sugerencia oficializada'**
  String get reputationEventSuggestionOfficial;

  /// No description provided for @reputationEventDuplicateReport.
  ///
  /// In es, this message translates to:
  /// **'Reporte duplicado'**
  String get reputationEventDuplicateReport;

  /// Achievements screen title
  ///
  /// In es, this message translates to:
  /// **'Logros'**
  String get achievementsTitle;

  /// Achievements level display with level name and XP
  ///
  /// In es, this message translates to:
  /// **'Nivel: {level} · {xp} XP'**
  String achievementsLevel(String level, int xp);

  /// Achievement category: contribution
  ///
  /// In es, this message translates to:
  /// **'Contribución'**
  String get achievementsCategoryContribution;

  /// Achievement category: usage
  ///
  /// In es, this message translates to:
  /// **'Uso'**
  String get achievementsCategoryUsage;

  /// Reputation screen title
  ///
  /// In es, this message translates to:
  /// **'Reputación'**
  String get reputationTitle;

  /// Reputation how to earn section header
  ///
  /// In es, this message translates to:
  /// **'Cómo subir'**
  String get reputationHowToEarn;

  /// Reputation ranks section header
  ///
  /// In es, this message translates to:
  /// **'Rangos'**
  String get reputationRanks;

  /// Reputation screen decorative tooltip
  ///
  /// In es, this message translates to:
  /// **'La reputación es decorativa. Más adelante desbloqueará privilegios.'**
  String get reputationTooltip;

  /// Points unit label
  ///
  /// In es, this message translates to:
  /// **'puntos'**
  String get reputationPoints;

  /// Next rank label in reputation progress
  ///
  /// In es, this message translates to:
  /// **'Siguiente rango'**
  String get reputationNextRank;

  /// Max rank reached label
  ///
  /// In es, this message translates to:
  /// **'Rango máximo alcanzado'**
  String get reputationMaxRank;

  /// Offline regions screen title
  ///
  /// In es, this message translates to:
  /// **'Mapas offline'**
  String get offlineRegionsTitle;

  /// FAB tooltip to add an offline region
  ///
  /// In es, this message translates to:
  /// **'Añadir región'**
  String get offlineRegionsAddRegion;

  /// Empty state title for offline regions
  ///
  /// In es, this message translates to:
  /// **'No hay mapas descargados'**
  String get offlineRegionsEmpty;

  /// Empty state subtitle for offline regions
  ///
  /// In es, this message translates to:
  /// **'Descarga zonas del mapa para usarlas sin conexión'**
  String get offlineRegionsEmptySubtitle;

  /// Delete region confirmation message
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar esta región?'**
  String get offlineRegionsDeleteConfirm;

  /// Delete region description
  ///
  /// In es, this message translates to:
  /// **'Los tiles descargados se perderán y deberás volver a descargarlos para usar el mapa sin conexión'**
  String get offlineRegionsDeleteDesc;

  /// Region status: ready
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get offlineRegionsStatusReady;

  /// Region status: downloading
  ///
  /// In es, this message translates to:
  /// **'Descargando'**
  String get offlineRegionsStatusDownloading;

  /// Region status: error
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get offlineRegionsStatusError;

  /// Region status: stale
  ///
  /// In es, this message translates to:
  /// **'Desactualizado'**
  String get offlineRegionsStatusStale;

  /// Downloaded date label prefix
  ///
  /// In es, this message translates to:
  /// **'Descargado'**
  String get offlineRegionsDownloaded;

  /// Size label prefix
  ///
  /// In es, this message translates to:
  /// **'Tamaño'**
  String get offlineRegionsSize;

  /// Download button label
  ///
  /// In es, this message translates to:
  /// **'Descargar'**
  String get offlineRegionsActionDownload;

  /// Delete button label
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get offlineRegionsActionDelete;

  /// Region name input label
  ///
  /// In es, this message translates to:
  /// **'Nombre de la región'**
  String get offlineRegionsRegionName;

  /// Region name input hint
  ///
  /// In es, this message translates to:
  /// **'Ej. Centro de Jerez'**
  String get offlineRegionsRegionNameHint;

  /// Min zoom selector label
  ///
  /// In es, this message translates to:
  /// **'Zoom mínimo'**
  String get offlineRegionsZoomMin;

  /// Max zoom selector label
  ///
  /// In es, this message translates to:
  /// **'Zoom máximo'**
  String get offlineRegionsZoomMax;

  /// Estimated download size label
  ///
  /// In es, this message translates to:
  /// **'Tamaño estimado'**
  String get offlineRegionsEstimatedSize;

  /// Instruction to select area on map
  ///
  /// In es, this message translates to:
  /// **'Mueve el mapa para seleccionar un área'**
  String get offlineRegionsSelectArea;

  /// Data synced indicator in region card
  ///
  /// In es, this message translates to:
  /// **'Datos sincronizados'**
  String get offlineRegionsDataSynced;

  /// No description provided for @offlineRegionsMapLink.
  ///
  /// In es, this message translates to:
  /// **'Mapas offline'**
  String get offlineRegionsMapLink;

  /// Appearance storage section header
  ///
  /// In es, this message translates to:
  /// **'ALMACENAMIENTO OFF LINE'**
  String get appearanceStorageSection;

  /// Total storage used label
  ///
  /// In es, this message translates to:
  /// **'Espacio usado'**
  String get appearanceStorageTotal;

  /// FMTC maps storage label
  ///
  /// In es, this message translates to:
  /// **'Mapas FMTC'**
  String get appearanceStorageFmtc;

  /// Hive local data storage label
  ///
  /// In es, this message translates to:
  /// **'Datos locales'**
  String get appearanceStorageHive;

  /// Pending uploads storage label
  ///
  /// In es, this message translates to:
  /// **'Adjuntos pendientes'**
  String get appearanceStoragePending;

  /// Clear map cache button
  ///
  /// In es, this message translates to:
  /// **'Limpiar caché de mapas'**
  String get appearanceStorageClearCache;

  /// Clear map cache confirmation message
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar todos los mapas offline descargados?'**
  String get appearanceStorageClearCacheConfirm;

  /// Map cache cleared confirmation
  ///
  /// In es, this message translates to:
  /// **'Caché de mapas eliminada'**
  String get appearanceStorageClearCacheDone;

  /// No description provided for @appearanceStorageMaxInfo.
  ///
  /// In es, this message translates to:
  /// **'Almacenamiento máximo: 500 MB'**
  String get appearanceStorageMaxInfo;

  /// Notifications screen title
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notificationsTitle;

  /// Notifications empty state
  ///
  /// In es, this message translates to:
  /// **'No tienes notificaciones'**
  String get notificationsEmpty;

  /// Mark all notifications as read button
  ///
  /// In es, this message translates to:
  /// **'Marcar todo leído'**
  String get notificationsMarkAllRead;

  /// All notifications marked as read toast
  ///
  /// In es, this message translates to:
  /// **'Todo leído'**
  String get notificationsAllRead;

  /// Notification type: incident resolved
  ///
  /// In es, this message translates to:
  /// **'Incidencia resuelta'**
  String get notificationTypeIncidentResolved;

  /// Notification type: route promoted
  ///
  /// In es, this message translates to:
  /// **'Ruta promocionada'**
  String get notificationTypeRoutePromoted;

  /// Notification type: share received
  ///
  /// In es, this message translates to:
  /// **'Ruta compartida contigo'**
  String get notificationTypeShareReceived;

  /// Notification type: feature request replied
  ///
  /// In es, this message translates to:
  /// **'Respuesta a tu solicitud'**
  String get notificationTypeFeatureRequestReplied;

  /// Notification type: bus approaching
  ///
  /// In es, this message translates to:
  /// **'Bus acercándose'**
  String get notificationTypeBusApproaching;

  /// Notification type: custom/fallback
  ///
  /// In es, this message translates to:
  /// **'Aviso'**
  String get notificationTypeCustom;

  /// Relative time: just now
  ///
  /// In es, this message translates to:
  /// **'Ahora'**
  String get notificationTimeNow;

  /// Relative time: n minutes ago
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Hace 1 min} other{Hace {n} min}}'**
  String notificationTimeMinutes(int n);

  /// Relative time: n hours ago
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Hace 1 h} other{Hace {n} h}}'**
  String notificationTimeHours(int n);

  /// No description provided for @notificationTimeDays.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Hace 1 d} other{Hace {n} d}}'**
  String notificationTimeDays(num n);

  /// Profile notifications section header
  ///
  /// In es, this message translates to:
  /// **'NOTIFICACIONES'**
  String get notifPrefSectionTitle;

  /// Notification toggle: incident resolved
  ///
  /// In es, this message translates to:
  /// **'Reportes resueltos'**
  String get notifPrefIncidentResolved;

  /// Notification toggle: route promoted and shares
  ///
  /// In es, this message translates to:
  /// **'Mis rutas'**
  String get notifPrefRoutePromoted;

  /// Notification toggle: bus approaching favorite stop
  ///
  /// In es, this message translates to:
  /// **'Buses cerca'**
  String get notifPrefBusApproaching;

  /// Notification toggle: feature request replied
  ///
  /// In es, this message translates to:
  /// **'Sugerencias'**
  String get notifPrefFeatureRequestReplied;

  /// Quiet hours section header
  ///
  /// In es, this message translates to:
  /// **'HORARIO SILENCIOSO'**
  String get notifPrefQuietHoursSection;

  /// Quiet hours enable toggle label
  ///
  /// In es, this message translates to:
  /// **'Activar horario silencioso'**
  String get notifPrefQuietHoursEnabled;

  /// Quiet hours description text
  ///
  /// In es, this message translates to:
  /// **'Durante este horario no recibirás notificaciones sonoras. Las notificaciones seguirán apareciendo en el centro de notificaciones.'**
  String get notifPrefQuietHoursDescription;

  /// Quiet hours start time label
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get notifPrefQuietHoursStart;

  /// Quiet hours end time label
  ///
  /// In es, this message translates to:
  /// **'Hasta'**
  String get notifPrefQuietHoursEnd;

  /// Quiet hours time not set placeholder
  ///
  /// In es, this message translates to:
  /// **'No configurado'**
  String get notifPrefQuietHoursNotSet;

  /// Time picker dialog title
  ///
  /// In es, this message translates to:
  /// **'Seleccionar hora'**
  String get notifPrefSelectTime;

  /// Privacy screen title
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get privacyTitle;

  /// Privacy consents section header
  ///
  /// In es, this message translates to:
  /// **'CONSENTIMIENTOS'**
  String get privacySectionConsents;

  /// Privacy toggle: analytics
  ///
  /// In es, this message translates to:
  /// **'Analíticas'**
  String get privacyConsentAnalytics;

  /// Privacy toggle description: analytics
  ///
  /// In es, this message translates to:
  /// **'Datos anónimos de uso para mejorar la app'**
  String get privacyConsentAnalyticsDesc;

  /// Privacy toggle: crash reporting
  ///
  /// In es, this message translates to:
  /// **'Informes de fallos'**
  String get privacyConsentCrashReporting;

  /// Privacy toggle description: crash reporting
  ///
  /// In es, this message translates to:
  /// **'Envía informes automáticos cuando la app falla'**
  String get privacyConsentCrashReportingDesc;

  /// Privacy toggle: marketing
  ///
  /// In es, this message translates to:
  /// **'Marketing'**
  String get privacyConsentMarketing;

  /// Privacy toggle description: marketing
  ///
  /// In es, this message translates to:
  /// **'Recibe novedades y promociones sobre Transitly'**
  String get privacyConsentMarketingDesc;

  /// Privacy my data section header
  ///
  /// In es, this message translates to:
  /// **'MIS DATOS'**
  String get privacySectionMyData;

  /// Privacy button: download my data
  ///
  /// In es, this message translates to:
  /// **'Descargar mis datos'**
  String get privacyDownloadData;

  /// Privacy button: request account deletion
  ///
  /// In es, this message translates to:
  /// **'Solicitar borrado de cuenta'**
  String get privacyRequestDeletion;

  /// Privacy legal section header
  ///
  /// In es, this message translates to:
  /// **'LEGAL'**
  String get privacySectionLegal;

  /// Privacy link: terms of service
  ///
  /// In es, this message translates to:
  /// **'Términos de servicio'**
  String get privacyTermsOfService;

  /// Privacy link: privacy policy
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get privacyPrivacyPolicy;

  /// Privacy toast: data export requested
  ///
  /// In es, this message translates to:
  /// **'Solicitud de exportación enviada. Recibirás un enlace cuando esté lista.'**
  String get privacyDataExportRequested;

  /// Privacy toast: deletion requested
  ///
  /// In es, this message translates to:
  /// **'Solicitud de borrado enviada. Tus datos se eliminarán en 30 días.'**
  String get privacyDeletionRequested;

  /// Privacy deletion confirmation dialog title
  ///
  /// In es, this message translates to:
  /// **'¿Solicitar borrado de cuenta?'**
  String get privacyDeleteConfirmTitle;

  /// Privacy deletion confirmation dialog message
  ///
  /// In es, this message translates to:
  /// **'Tus datos se eliminarán tras un periodo de espera de 30 días.'**
  String get privacyDeleteConfirmMessage;

  /// Privacy deletion dialog cancel
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get privacyDeleteConfirmCancel;

  /// Privacy deletion dialog confirm
  ///
  /// In es, this message translates to:
  /// **'Solicitar borrado'**
  String get privacyDeleteConfirmAction;

  /// Profile link to privacy screen
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get privacyLinkLabel;

  /// Widgets settings screen title
  ///
  /// In es, this message translates to:
  /// **'Widgets'**
  String get widgetsTitle;

  /// Widgets settings instructions section header
  ///
  /// In es, this message translates to:
  /// **'INSTRUCCIONES'**
  String get widgetsSectionInstructions;

  /// Widget add instructions for Android
  ///
  /// In es, this message translates to:
  /// **'En Android, mantén pulsado en la pantalla de inicio y selecciona \"Añadir widget\". Busca Transitly en la lista.'**
  String get widgetsInstructionsAndroid;

  /// Widget add instructions for iOS
  ///
  /// In es, this message translates to:
  /// **'En iOS, mantén pulsado en la pantalla de inicio, pulsa el botón + y busca Transitly.'**
  String get widgetsInstructionsIos;

  /// Favorite stop selector label
  ///
  /// In es, this message translates to:
  /// **'Parada favorita'**
  String get widgetsFavoriteStop;

  /// Favorite line selector label
  ///
  /// In es, this message translates to:
  /// **'Línea favorita'**
  String get widgetsFavoriteLine;

  /// How to add widget info button
  ///
  /// In es, this message translates to:
  /// **'Cómo añadir el widget'**
  String get widgetsHowToAdd;

  /// Widget config saved toast
  ///
  /// In es, this message translates to:
  /// **'Configuración guardada'**
  String get widgetsConfigSaved;

  /// Offline banner: no connectivity, no pending actions
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Los cambios se guardarán y se enviarán al volver.'**
  String get offlineBannerOffline;

  /// Offline banner: offline with queued actions
  ///
  /// In es, this message translates to:
  /// **'Sin conexión · {count, plural, =1{1 acción en cola} other{{count} acciones en cola}}.'**
  String offlineBannerQueued(int count);

  /// Offline banner: syncing pending actions
  ///
  /// In es, this message translates to:
  /// **'Sincronizando {count, plural, =1{1 acción pendiente} other{{count} acciones pendientes}}…'**
  String offlineBannerSyncing(int count);

  /// Auth: email field label
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// Auth: email field hint
  ///
  /// In es, this message translates to:
  /// **'tu@email.com'**
  String get authEmailHint;

  /// Auth: password field label
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get authPassword;

  /// Auth: password field hint
  ///
  /// In es, this message translates to:
  /// **'••••••••'**
  String get authPasswordHint;

  /// Auth: password minimum length hint
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get authPasswordMinHint;

  /// Auth: name field label
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get authName;

  /// Auth: name field hint
  ///
  /// In es, this message translates to:
  /// **'Tu nombre'**
  String get authNameHint;

  /// Auth: required field validation
  ///
  /// In es, this message translates to:
  /// **'Requerido'**
  String get authRequired;

  /// Auth: required field validation (feminine)
  ///
  /// In es, this message translates to:
  /// **'Requerida'**
  String get authRequiredField;

  /// Auth: invalid email validation
  ///
  /// In es, this message translates to:
  /// **'Email inválido'**
  String get authInvalidEmail;

  /// Auth: minimum 6 characters validation
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get authMinChars;

  /// Auth: enter valid email error
  ///
  /// In es, this message translates to:
  /// **'Introduce un email válido'**
  String get authEnterValidEmail;

  /// Auth: connection error
  ///
  /// In es, this message translates to:
  /// **'Error de conexión'**
  String get authErrorConnection;

  /// Auth: Google connection error
  ///
  /// In es, this message translates to:
  /// **'Error de conexión con Google'**
  String get authErrorGoogle;

  /// Auth: sign in screen subtitle
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para continuar'**
  String get authSignInSubtitle;

  /// Auth: sign in button
  ///
  /// In es, this message translates to:
  /// **'INICIAR SESIÓN'**
  String get authSignInButton;

  /// Auth: sign in error fallback
  ///
  /// In es, this message translates to:
  /// **'Error al iniciar sesión'**
  String get authSignInError;

  /// Auth: no account question
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta?'**
  String get authNoAccount;

  /// Auth: register link
  ///
  /// In es, this message translates to:
  /// **'Regístrate'**
  String get authRegister;

  /// Auth: forgot password link
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get authForgotPassword;

  /// Auth: or continue with divider
  ///
  /// In es, this message translates to:
  /// **'o continúa con'**
  String get authOrContinue;

  /// Auth: Google sign in button
  ///
  /// In es, this message translates to:
  /// **'GOOGLE'**
  String get authGoogleButton;

  /// Auth: magic link access button
  ///
  /// In es, this message translates to:
  /// **'Acceder con enlace mágico'**
  String get authMagicLink;

  /// Auth: sign up screen title
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get authSignUpTitle;

  /// Auth: sign up screen subtitle
  ///
  /// In es, this message translates to:
  /// **'Únete a Transitly'**
  String get authSignUpSubtitle;

  /// Auth: sign up button
  ///
  /// In es, this message translates to:
  /// **'CREAR CUENTA'**
  String get authSignUpButton;

  /// Auth: sign up error fallback
  ///
  /// In es, this message translates to:
  /// **'Error al registrarse'**
  String get authSignUpError;

  /// Auth: already have account question
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta?'**
  String get authAlreadyHaveAccount;

  /// Auth: sign in link
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión'**
  String get authSignInLink;

  /// No description provided for @signupAgeGateTitle.
  ///
  /// In es, this message translates to:
  /// **'Verificación de edad'**
  String get signupAgeGateTitle;

  /// No description provided for @signupAgeGateUnder16.
  ///
  /// In es, this message translates to:
  /// **'Debes tener al menos 16 años'**
  String get signupAgeGateUnder16;

  /// No description provided for @signupAgeGateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get signupAgeGateLabel;

  /// Auth: recover password screen title
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get authRecoverTitle;

  /// Auth: recover password sent message
  ///
  /// In es, this message translates to:
  /// **'Si el email existe, recibirás un enlace para restablecer tu contraseña.'**
  String get authRecoverSent;

  /// Auth: recover password hint
  ///
  /// In es, this message translates to:
  /// **'Introduce tu email y te enviaremos un enlace'**
  String get authRecoverHint;

  /// Auth: send link button
  ///
  /// In es, this message translates to:
  /// **'ENVIAR ENLACE'**
  String get authSendLinkButton;

  /// Auth: back to sign in link
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio de sesión'**
  String get authBackToSignIn;

  /// Auth: recover password error fallback
  ///
  /// In es, this message translates to:
  /// **'Error al enviar la recuperación'**
  String get authRecoverError;

  /// Auth: magic link screen title
  ///
  /// In es, this message translates to:
  /// **'Enlace mágico'**
  String get authMagicLinkTitle;

  /// Auth: magic link sent message
  ///
  /// In es, this message translates to:
  /// **'Revisa tu email. Te hemos enviado un enlace para acceder.'**
  String get authMagicLinkSent;

  /// Auth: magic link hint
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un enlace de acceso a tu email'**
  String get authMagicLinkHint;

  /// Auth: magic link error fallback
  ///
  /// In es, this message translates to:
  /// **'Error al enviar el enlace'**
  String get authMagicLinkError;

  /// Auth: email verification screen title
  ///
  /// In es, this message translates to:
  /// **'Verifica tu email'**
  String get authVerifyTitle;

  /// Auth: email verification message
  ///
  /// In es, this message translates to:
  /// **'Te hemos enviado un email de verificación. Revisa tu bandeja de entrada y haz clic en el enlace para continuar.'**
  String get authVerifyMessage;

  /// Auth: resend verification button
  ///
  /// In es, this message translates to:
  /// **'REENVIAR EMAIL'**
  String get authResendButton;

  /// Auth: sign out and go back
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión y volver'**
  String get authSignOutAndBack;

  /// Auth: resend success toast
  ///
  /// In es, this message translates to:
  /// **'Email de verificación reenviado.'**
  String get authResendSuccess;

  /// Auth: resend error fallback
  ///
  /// In es, this message translates to:
  /// **'Error al reenviar'**
  String get authResendError;

  /// Auth: activate driver screen title
  ///
  /// In es, this message translates to:
  /// **'Activar modo conductor'**
  String get authActivateDriverTitle;

  /// Auth: activate driver hint text
  ///
  /// In es, this message translates to:
  /// **'Tu compañía te ha dado un código.\nIntrodúcelo aquí para activar el modo conductor.'**
  String get authActivateDriverHint;

  /// Auth: activate driver need login message
  ///
  /// In es, this message translates to:
  /// **'Necesitas iniciar sesión para activar el modo conductor.'**
  String get authActivateNeedLogin;

  /// Auth: activate driver button
  ///
  /// In es, this message translates to:
  /// **'ACTIVAR'**
  String get authActivateButton;

  /// Auth: activate driver enter code error
  ///
  /// In es, this message translates to:
  /// **'Introduce el código'**
  String get authActivateEnterCode;

  /// Auth: activate driver code not found
  ///
  /// In es, this message translates to:
  /// **'Código no encontrado'**
  String get authActivateCodeNotFound;

  /// Auth: activate driver code expired
  ///
  /// In es, this message translates to:
  /// **'El código ha expirado'**
  String get authActivateCodeExpired;

  /// Auth: activate driver code depleted
  ///
  /// In es, this message translates to:
  /// **'El código ya no tiene usos disponibles'**
  String get authActivateCodeDepleted;

  /// Auth: activate driver error fallback
  ///
  /// In es, this message translates to:
  /// **'Error al activar el código'**
  String get authActivateError;

  /// Auth: activate driver need session error
  ///
  /// In es, this message translates to:
  /// **'Necesitas iniciar sesión primero'**
  String get authActivateNeedSession;

  /// Auth: activate driver success message
  ///
  /// In es, this message translates to:
  /// **'Bienvenido. Ya puedes usar el modo conductor.'**
  String get authActivateSuccess;

  /// Auth: sign out confirmation title
  ///
  /// In es, this message translates to:
  /// **'¿Cerrar sesión?'**
  String get authSignOutTitle;

  /// Auth: sign out confirmation message
  ///
  /// In es, this message translates to:
  /// **'Volverás a la pantalla de inicio de sesión.'**
  String get authSignOutMessage;

  /// Auth: sign out cancel button
  ///
  /// In es, this message translates to:
  /// **'CANCELAR'**
  String get authSignOutCancel;

  /// Auth: sign out confirm button
  ///
  /// In es, this message translates to:
  /// **'CERRAR SESIÓN'**
  String get authSignOutConfirm;

  /// Auth: delete account confirmation title
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar cuenta?'**
  String get authDeleteAccountTitle;

  /// Auth: delete account confirmation message
  ///
  /// In es, this message translates to:
  /// **'Esta acción es irreversible.'**
  String get authDeleteAccountMessage;

  /// Auth: delete account button
  ///
  /// In es, this message translates to:
  /// **'ELIMINAR'**
  String get authDeleteAccountButton;

  /// Auth: delete account error toast
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar la cuenta'**
  String get authDeleteAccountError;

  /// Auth: delete account cancel button
  ///
  /// In es, this message translates to:
  /// **'CANCELAR'**
  String get authDeleteAccountCancel;

  /// No description provided for @filterPresetsTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtros predefinidos'**
  String get filterPresetsTitle;

  /// No description provided for @filterPresetsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin presets guardados'**
  String get filterPresetsEmptyTitle;

  /// No description provided for @filterPresetsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Guarda la combinación de filtros del mapa que más uses para aplicarla con un toque.'**
  String get filterPresetsEmptySubtitle;

  /// No description provided for @filterPresetsActionSave.
  ///
  /// In es, this message translates to:
  /// **'GUARDAR FILTROS ACTUALES'**
  String get filterPresetsActionSave;

  /// No description provided for @filterPresetsTileHint.
  ///
  /// In es, this message translates to:
  /// **'Tocar para aplicar'**
  String get filterPresetsTileHint;

  /// No description provided for @filterPresetsTileDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get filterPresetsTileDelete;

  /// No description provided for @filterPresetsDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Guardar filtros'**
  String get filterPresetsDialogTitle;

  /// No description provided for @filterPresetsDialogHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre del preset'**
  String get filterPresetsDialogHint;

  /// No description provided for @filterPresetsDialogConfirm.
  ///
  /// In es, this message translates to:
  /// **'GUARDAR'**
  String get filterPresetsDialogConfirm;

  /// No description provided for @filterPresetsApplied.
  ///
  /// In es, this message translates to:
  /// **'Filtros «{name}» aplicados'**
  String filterPresetsApplied(String name);

  /// No description provided for @driverStatsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get driverStatsTitle;

  /// No description provided for @driverStatsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin datos aún'**
  String get driverStatsEmptyTitle;

  /// No description provided for @driverStatsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tus estadísticas se calculan a partir del historial de viajes.'**
  String get driverStatsEmptySubtitle;

  /// No description provided for @driverStatsTrips.
  ///
  /// In es, this message translates to:
  /// **'Viajes'**
  String get driverStatsTrips;

  /// No description provided for @driverStatsDistinctLines.
  ///
  /// In es, this message translates to:
  /// **'Líneas distintas'**
  String get driverStatsDistinctLines;

  /// No description provided for @driverStatsTotalCost.
  ///
  /// In es, this message translates to:
  /// **'Coste total'**
  String get driverStatsTotalCost;

  /// No description provided for @driverStatsDistance.
  ///
  /// In es, this message translates to:
  /// **'Distancia'**
  String get driverStatsDistance;

  /// No description provided for @driverStatsCo2Saved.
  ///
  /// In es, this message translates to:
  /// **'CO₂ ahorrado'**
  String get driverStatsCo2Saved;

  /// No description provided for @driverHistoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Historial de conductor'**
  String get driverHistoryTitle;

  /// No description provided for @driverHistoryEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin viajes todavía'**
  String get driverHistoryEmptyTitle;

  /// No description provided for @driverHistoryEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuando completes rutas aparecerán aquí con su trayecto y coste.'**
  String get driverHistoryEmptySubtitle;

  /// No description provided for @driverHistoryUnknownRoute.
  ///
  /// In es, this message translates to:
  /// **'Ruta desconocida'**
  String get driverHistoryUnknownRoute;

  /// No description provided for @plannedTripsTitle.
  ///
  /// In es, this message translates to:
  /// **'Viajes planificados'**
  String get plannedTripsTitle;

  /// No description provided for @plannedTripsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin viajes planificados'**
  String get plannedTripsEmptyTitle;

  /// No description provided for @plannedTripsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Marca una ruta como favorita y configura un aviso para verla aquí como viaje habitual.'**
  String get plannedTripsEmptySubtitle;

  /// No description provided for @plannedTripsNoStop.
  ///
  /// In es, this message translates to:
  /// **'Parada no definida'**
  String get plannedTripsNoStop;

  /// No description provided for @plannedTripsFrom.
  ///
  /// In es, this message translates to:
  /// **'Desde {stop}'**
  String plannedTripsFrom(String stop);

  /// No description provided for @aiScheduleImportTitle.
  ///
  /// In es, this message translates to:
  /// **'Importar horario'**
  String get aiScheduleImportTitle;

  /// No description provided for @aiScheduleImportEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Importar horarios'**
  String get aiScheduleImportEmptyTitle;

  /// No description provided for @aiScheduleImportEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Pega el texto de un horario para extraer las horas de salida automáticamente.'**
  String get aiScheduleImportEmptySubtitle;

  /// No description provided for @aiScheduleImportHint.
  ///
  /// In es, this message translates to:
  /// **'Pega el horario y se extraerán las horas de salida. El análisis es local (demo): detecta patrones HH:MM, no usa IA ni backend.'**
  String get aiScheduleImportHint;

  /// No description provided for @aiScheduleImportFieldHint.
  ///
  /// In es, this message translates to:
  /// **'Ej.: 06:00  06:30  07:00 ...'**
  String get aiScheduleImportFieldHint;

  /// No description provided for @aiScheduleImportAnalyze.
  ///
  /// In es, this message translates to:
  /// **'ANALIZAR'**
  String get aiScheduleImportAnalyze;

  /// No description provided for @aiScheduleImportNoTimes.
  ///
  /// In es, this message translates to:
  /// **'No se detectaron horas'**
  String get aiScheduleImportNoTimes;

  /// No description provided for @aiScheduleImportDetected.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 salida detectada} other{{count} salidas detectadas}}'**
  String aiScheduleImportDetected(int count);

  /// No description provided for @suggestionContributeTitle.
  ///
  /// In es, this message translates to:
  /// **'Contribuir a sugerencias'**
  String get suggestionContributeTitle;

  /// No description provided for @suggestionContributeEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Nada que contribuir ahora'**
  String get suggestionContributeEmptyTitle;

  /// No description provided for @suggestionContributeEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'No hay sugerencias abiertas. Vuelve más tarde o propón una ruta nueva desde la pestaña de sugerencias.'**
  String get suggestionContributeEmptySubtitle;

  /// No description provided for @cityPickerErrorOperators.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar operadores'**
  String get cityPickerErrorOperators;

  /// No description provided for @driversErrorLoading.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar conductores'**
  String get driversErrorLoading;

  /// No description provided for @driversErrorRevoking.
  ///
  /// In es, this message translates to:
  /// **'Error al revocar conductor'**
  String get driversErrorRevoking;

  /// No description provided for @invitationCodesErrorLoading.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar códigos'**
  String get invitationCodesErrorLoading;

  /// No description provided for @invitationCodesErrorGenerating.
  ///
  /// In es, this message translates to:
  /// **'Error al generar código'**
  String get invitationCodesErrorGenerating;

  /// No description provided for @invitationCodesErrorRevoking.
  ///
  /// In es, this message translates to:
  /// **'Error al revocar código'**
  String get invitationCodesErrorRevoking;

  /// No description provided for @routeOfficializeError.
  ///
  /// In es, this message translates to:
  /// **'Error al enviar solicitud'**
  String get routeOfficializeError;

  /// No description provided for @routeShareUserNotFound.
  ///
  /// In es, this message translates to:
  /// **'Usuario no encontrado'**
  String get routeShareUserNotFound;

  /// No description provided for @routeShareSuccess.
  ///
  /// In es, this message translates to:
  /// **'Ruta compartida con {email}'**
  String routeShareSuccess(String email);

  /// No description provided for @routeShareError.
  ///
  /// In es, this message translates to:
  /// **'Error al compartir ruta'**
  String get routeShareError;

  /// No description provided for @routeShareErrorGeneratingLink.
  ///
  /// In es, this message translates to:
  /// **'Error al generar enlace'**
  String get routeShareErrorGeneratingLink;

  /// No description provided for @routeDetailNotFound.
  ///
  /// In es, this message translates to:
  /// **'Ruta no encontrada'**
  String get routeDetailNotFound;

  /// Button to add route to user favorites
  ///
  /// In es, this message translates to:
  /// **'AÑADIR A MIS LÍNEAS ★'**
  String get routeDetailAddFavorite;

  /// Button to remove route from user favorites
  ///
  /// In es, this message translates to:
  /// **'EN MIS LÍNEAS ✓'**
  String get routeDetailRemoveFavorite;

  /// SnackBar message when a line is added to favorites
  ///
  /// In es, this message translates to:
  /// **'Línea añadida a tus favoritas'**
  String get favoriteAdded;

  /// SnackBar message when a line is removed from favorites
  ///
  /// In es, this message translates to:
  /// **'Línea eliminada de tus favoritas'**
  String get favoriteRemoved;

  /// No description provided for @stopDetailNotFound.
  ///
  /// In es, this message translates to:
  /// **'Parada no encontrada'**
  String get stopDetailNotFound;

  /// No description provided for @feedbackErrorSending.
  ///
  /// In es, this message translates to:
  /// **'Error al enviar mejora'**
  String get feedbackErrorSending;

  /// No description provided for @incidentErrorSending.
  ///
  /// In es, this message translates to:
  /// **'Error al enviar reporte'**
  String get incidentErrorSending;

  /// No description provided for @homeRouteSemanticsLabel.
  ///
  /// In es, this message translates to:
  /// **'{code}, {time}'**
  String homeRouteSemanticsLabel(String code, String time);

  /// No description provided for @nfcCardBalance.
  ///
  /// In es, this message translates to:
  /// **'Saldo: {amount} euros'**
  String nfcCardBalance(String amount);

  /// No description provided for @homeNextBusSemantics.
  ///
  /// In es, this message translates to:
  /// **'Tu próximo bus, {route}'**
  String homeNextBusSemantics(String route);

  /// No description provided for @generalComingSoon.
  ///
  /// In es, this message translates to:
  /// **'{feature}: próximamente'**
  String generalComingSoon(String feature);

  /// No description provided for @capacitySemanticsLabel.
  ///
  /// In es, this message translates to:
  /// **'Ocupación: {level}'**
  String capacitySemanticsLabel(String level);

  /// No description provided for @reputationSemanticsLabel.
  ///
  /// In es, this message translates to:
  /// **'Reputación: {level}'**
  String reputationSemanticsLabel(String level);

  /// No description provided for @reputationScoreSemantics.
  ///
  /// In es, this message translates to:
  /// **'{label}: {score} puntos'**
  String reputationScoreSemantics(String label, int score);

  /// No description provided for @routeCardSemantics.
  ///
  /// In es, this message translates to:
  /// **'Línea {code}, {name}{status}{minutes}'**
  String routeCardSemantics(
    String code,
    String name,
    String status,
    String minutes,
  );

  /// No description provided for @adminPanelTitle.
  ///
  /// In es, this message translates to:
  /// **'Panel de administración'**
  String get adminPanelTitle;

  /// No description provided for @adminPanelSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Gestiona la plataforma'**
  String get adminPanelSubtitle;

  /// No description provided for @cityPickerSelectOperator.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar operador'**
  String get cityPickerSelectOperator;

  /// No description provided for @driverPermissionRequired.
  ///
  /// In es, this message translates to:
  /// **'Permiso de ubicación requerido'**
  String get driverPermissionRequired;

  /// No description provided for @driverModeLabel.
  ///
  /// In es, this message translates to:
  /// **'Modo conductor'**
  String get driverModeLabel;

  /// No description provided for @driverGreeting.
  ///
  /// In es, this message translates to:
  /// **'Hola {name}'**
  String driverGreeting(String name);

  /// No description provided for @driverCurrentOperator.
  ///
  /// In es, this message translates to:
  /// **'Operador: {name}'**
  String driverCurrentOperator(String name);

  /// No description provided for @driverSelectRoute.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar ruta'**
  String get driverSelectRoute;

  /// No description provided for @driverNoRoutesLoaded.
  ///
  /// In es, this message translates to:
  /// **'Sin rutas cargadas'**
  String get driverNoRoutesLoaded;

  /// No description provided for @driverChooseAnother.
  ///
  /// In es, this message translates to:
  /// **'Elegir otra'**
  String get driverChooseAnother;

  /// No description provided for @envErrorLabel.
  ///
  /// In es, this message translates to:
  /// **'Error: {name}'**
  String envErrorLabel(String name);

  /// No description provided for @envKeyLabel.
  ///
  /// In es, this message translates to:
  /// **'Clave: {key}'**
  String envKeyLabel(String key);

  /// No description provided for @feedbackSelectCategoryFirst.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una categoría primero'**
  String get feedbackSelectCategoryFirst;

  /// No description provided for @feedbackEnterDescription.
  ///
  /// In es, this message translates to:
  /// **'Escribe una descripción'**
  String get feedbackEnterDescription;

  /// No description provided for @feedbackSent.
  ///
  /// In es, this message translates to:
  /// **'Feedback enviado · Gracias'**
  String get feedbackSent;

  /// No description provided for @routeFeedbackImprovementSent.
  ///
  /// In es, this message translates to:
  /// **'Mejora enviada. ¡Gracias!'**
  String get routeFeedbackImprovementSent;

  /// No description provided for @mapSearchComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Búsqueda en mapa: próximamente'**
  String get mapSearchComingSoon;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get profileDeleteAccount;

  /// No description provided for @profileCreateAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get profileCreateAccount;

  /// No description provided for @profileColorBlindModeNone.
  ///
  /// In es, this message translates to:
  /// **'Modo: Ninguno'**
  String get profileColorBlindModeNone;

  /// No description provided for @profileDarkMode.
  ///
  /// In es, this message translates to:
  /// **'Modo oscuro'**
  String get profileDarkMode;

  /// No description provided for @incidentReportSent.
  ///
  /// In es, this message translates to:
  /// **'Reporte enviado. Gracias por tu colaboración.'**
  String get incidentReportSent;

  /// No description provided for @inviteCodeGenerated.
  ///
  /// In es, this message translates to:
  /// **'Código generado: {code}'**
  String inviteCodeGenerated(String code);

  /// No description provided for @inviteGenerateCode.
  ///
  /// In es, this message translates to:
  /// **'Generar código'**
  String get inviteGenerateCode;

  /// No description provided for @operatorPanelTitle.
  ///
  /// In es, this message translates to:
  /// **'Panel del operador'**
  String get operatorPanelTitle;

  /// No description provided for @operatorPanelSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Gestiona tu operador de transporte'**
  String get operatorPanelSubtitle;

  /// No description provided for @routeChangelogEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin cambios recientes'**
  String get routeChangelogEmpty;

  /// No description provided for @routeFeedbackThanksConfirming.
  ///
  /// In es, this message translates to:
  /// **'¡Gracias por confirmar!'**
  String get routeFeedbackThanksConfirming;

  /// No description provided for @routeNoUpcomingSchedules.
  ///
  /// In es, this message translates to:
  /// **'Sin horarios próximos'**
  String get routeNoUpcomingSchedules;

  /// No description provided for @stopNoLinesRegistered.
  ///
  /// In es, this message translates to:
  /// **'Sin líneas registradas'**
  String get stopNoLinesRegistered;

  /// No description provided for @suggestRouteSent.
  ///
  /// In es, this message translates to:
  /// **'Sugerencia enviada · Te avisaremos'**
  String get suggestRouteSent;

  /// No description provided for @suggestRouteSubmitError.
  ///
  /// In es, this message translates to:
  /// **'Error al enviar: {error}'**
  String suggestRouteSubmitError(String error);

  /// No description provided for @searchEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Escribe un origen y un destino'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Te mostraremos las rutas más rápidas'**
  String get searchEmptySubtitle;

  /// No description provided for @searchUnderConstructionTitle.
  ///
  /// In es, this message translates to:
  /// **'Buscador en construcción'**
  String get searchUnderConstructionTitle;

  /// No description provided for @searchUnderConstructionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Mientras tanto, puedes sugerirnos rutas'**
  String get searchUnderConstructionSubtitle;

  /// No description provided for @searchReportRouteAction.
  ///
  /// In es, this message translates to:
  /// **'Sugerir ruta'**
  String get searchReportRouteAction;

  /// No description provided for @driverPanelTitle.
  ///
  /// In es, this message translates to:
  /// **'MODO CONDUCTOR'**
  String get driverPanelTitle;

  /// No description provided for @driverPanelStartRoute.
  ///
  /// In es, this message translates to:
  /// **'Iniciar ruta'**
  String get driverPanelStartRoute;

  /// No description provided for @driverPanelActiveRoute.
  ///
  /// In es, this message translates to:
  /// **'Ruta activa'**
  String get driverPanelActiveRoute;

  /// No description provided for @driverPanelCreateManualRoute.
  ///
  /// In es, this message translates to:
  /// **'Crear ruta manual'**
  String get driverPanelCreateManualRoute;

  /// No description provided for @driverPanelCreateLiveRoute.
  ///
  /// In es, this message translates to:
  /// **'Crear ruta en vivo'**
  String get driverPanelCreateLiveRoute;

  /// No description provided for @driverPanelMyRoutes.
  ///
  /// In es, this message translates to:
  /// **'Mis rutas'**
  String get driverPanelMyRoutes;

  /// No description provided for @driverPanelImportSchedules.
  ///
  /// In es, this message translates to:
  /// **'Importar horarios'**
  String get driverPanelImportSchedules;

  /// No description provided for @driverPanelManagementInbox.
  ///
  /// In es, this message translates to:
  /// **'Bandeja de gestión'**
  String get driverPanelManagementInbox;

  /// No description provided for @driverActiveNoActiveRoute.
  ///
  /// In es, this message translates to:
  /// **'No hay ruta activa'**
  String get driverActiveNoActiveRoute;

  /// No description provided for @driverActiveRouteHeader.
  ///
  /// In es, this message translates to:
  /// **'RUTA ACTIVA'**
  String get driverActiveRouteHeader;

  /// No description provided for @driverActiveRouteStartedAt.
  ///
  /// In es, this message translates to:
  /// **'{code} · {time} INICIO'**
  String driverActiveRouteStartedAt(String code, String time);

  /// No description provided for @driverActiveNextStopHeader.
  ///
  /// In es, this message translates to:
  /// **'PRÓXIMA PARADA'**
  String get driverActiveNextStopHeader;

  /// No description provided for @driverActiveStopRegisteredFmt.
  ///
  /// In es, this message translates to:
  /// **'PARADA REGISTRADA · {time}'**
  String driverActiveStopRegisteredFmt(String time);

  /// No description provided for @driverActiveRegisterStop.
  ///
  /// In es, this message translates to:
  /// **'REGISTRAR PARADA'**
  String get driverActiveRegisterStop;

  /// No description provided for @driverActiveIncidentButton.
  ///
  /// In es, this message translates to:
  /// **'INCIDENCIA'**
  String get driverActiveIncidentButton;

  /// No description provided for @driverActiveFinishRouteButton.
  ///
  /// In es, this message translates to:
  /// **'FINALIZAR RUTA'**
  String get driverActiveFinishRouteButton;

  /// No description provided for @driverActiveFinishConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Finalizar ruta?'**
  String get driverActiveFinishConfirmTitle;

  /// No description provided for @driverActiveFinishConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Se registrará la ruta como completada.'**
  String get driverActiveFinishConfirmMessage;

  /// No description provided for @driverActiveFinishConfirmButton.
  ///
  /// In es, this message translates to:
  /// **'FINALIZAR'**
  String get driverActiveFinishConfirmButton;

  /// No description provided for @driverStartTitle.
  ///
  /// In es, this message translates to:
  /// **'INICIAR RUTA'**
  String get driverStartTitle;

  /// No description provided for @driverStartSuggestionFmt.
  ///
  /// In es, this message translates to:
  /// **'SUGERENCIA: {code} · {time} · {day}'**
  String driverStartSuggestionFmt(String code, String time, String day);

  /// No description provided for @driverStartIsThisYourRoute.
  ///
  /// In es, this message translates to:
  /// **'¿Es tu ruta?'**
  String get driverStartIsThisYourRoute;

  /// No description provided for @driverStartYesStart.
  ///
  /// In es, this message translates to:
  /// **'SÍ, INICIAR'**
  String get driverStartYesStart;

  /// No description provided for @driverStartSelectLine.
  ///
  /// In es, this message translates to:
  /// **'SELECCIONA LÍNEA'**
  String get driverStartSelectLine;

  /// No description provided for @driverStartSelectSchedule.
  ///
  /// In es, this message translates to:
  /// **'SELECCIONA HORARIO'**
  String get driverStartSelectSchedule;

  /// No description provided for @driverStartDepartureFmt.
  ///
  /// In es, this message translates to:
  /// **'Salida: {time}'**
  String driverStartDepartureFmt(String time);

  /// No description provided for @driverStartStopsAndTime.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 parada} other{{count} paradas}} · ~{minutes} min'**
  String driverStartStopsAndTime(int count, int minutes);

  /// No description provided for @driverStartStartButton.
  ///
  /// In es, this message translates to:
  /// **'INICIAR RUTA'**
  String get driverStartStartButton;

  /// No description provided for @feedbackScreenTitleFmt.
  ///
  /// In es, this message translates to:
  /// **'FEEDBACK · {code}'**
  String feedbackScreenTitleFmt(String code);

  /// No description provided for @feedbackDescriptionLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get feedbackDescriptionLabel;

  /// No description provided for @feedbackDescriptionHint.
  ///
  /// In es, this message translates to:
  /// **'Descripción de lo que has encontrado'**
  String get feedbackDescriptionHint;

  /// No description provided for @feedbackCategoryRouteLabel.
  ///
  /// In es, this message translates to:
  /// **'El recorrido en el mapa'**
  String get feedbackCategoryRouteLabel;

  /// No description provided for @feedbackCategoryStopsLabel.
  ///
  /// In es, this message translates to:
  /// **'Una parada (falta, sobra o está mal)'**
  String get feedbackCategoryStopsLabel;

  /// No description provided for @feedbackCategorySchedulesLabel.
  ///
  /// In es, this message translates to:
  /// **'Los horarios'**
  String get feedbackCategorySchedulesLabel;

  /// No description provided for @feedbackCategoryInfoLabel.
  ///
  /// In es, this message translates to:
  /// **'Información general'**
  String get feedbackCategoryInfoLabel;

  /// No description provided for @feedbackCategorySuggestionLabel.
  ///
  /// In es, this message translates to:
  /// **'Tengo una sugerencia'**
  String get feedbackCategorySuggestionLabel;

  /// No description provided for @suggestRouteScreenTitle.
  ///
  /// In es, this message translates to:
  /// **'SUGERIR RUTA'**
  String get suggestRouteScreenTitle;

  /// No description provided for @suggestRouteHelpText.
  ///
  /// In es, this message translates to:
  /// **'Ayúdanos a completar el mapa de transporte'**
  String get suggestRouteHelpText;

  /// No description provided for @suggestRouteFromLabel.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get suggestRouteFromLabel;

  /// No description provided for @suggestRouteFromHint.
  ///
  /// In es, this message translates to:
  /// **'Origen'**
  String get suggestRouteFromHint;

  /// No description provided for @suggestRouteToLabel.
  ///
  /// In es, this message translates to:
  /// **'Hasta'**
  String get suggestRouteToLabel;

  /// No description provided for @suggestRouteToHint.
  ///
  /// In es, this message translates to:
  /// **'Destino'**
  String get suggestRouteToHint;

  /// No description provided for @suggestRouteOperatorLabel.
  ///
  /// In es, this message translates to:
  /// **'¿Operador?'**
  String get suggestRouteOperatorLabel;

  /// No description provided for @suggestRouteOperatorComujesa.
  ///
  /// In es, this message translates to:
  /// **'COMUJESA'**
  String get suggestRouteOperatorComujesa;

  /// No description provided for @suggestRouteOperatorOther.
  ///
  /// In es, this message translates to:
  /// **'Otra'**
  String get suggestRouteOperatorOther;

  /// No description provided for @suggestRouteOperatorDontKnow.
  ///
  /// In es, this message translates to:
  /// **'No lo sé'**
  String get suggestRouteOperatorDontKnow;

  /// No description provided for @suggestRouteCodeLabel.
  ///
  /// In es, this message translates to:
  /// **'Código de línea'**
  String get suggestRouteCodeLabel;

  /// No description provided for @suggestRouteCodeHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: M-250'**
  String get suggestRouteCodeHint;

  /// No description provided for @suggestRouteHowKnow.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo lo sabes?'**
  String get suggestRouteHowKnow;

  /// No description provided for @suggestRouteSourceUseIt.
  ///
  /// In es, this message translates to:
  /// **'La uso'**
  String get suggestRouteSourceUseIt;

  /// No description provided for @suggestRouteSourceSawIt.
  ///
  /// In es, this message translates to:
  /// **'La he visto'**
  String get suggestRouteSourceSawIt;

  /// No description provided for @suggestRouteSourceTold.
  ///
  /// In es, this message translates to:
  /// **'Me lo dijeron'**
  String get suggestRouteSourceTold;

  /// No description provided for @suggestRouteSourceWeb.
  ///
  /// In es, this message translates to:
  /// **'Web oficial'**
  String get suggestRouteSourceWeb;

  /// No description provided for @suggestRouteAddDetails.
  ///
  /// In es, this message translates to:
  /// **'Añadir más detalles'**
  String get suggestRouteAddDetails;

  /// No description provided for @suggestRouteStopsRemember.
  ///
  /// In es, this message translates to:
  /// **'Paradas que recuerdas'**
  String get suggestRouteStopsRemember;

  /// No description provided for @suggestRouteStopNumber.
  ///
  /// In es, this message translates to:
  /// **'Parada {number}'**
  String suggestRouteStopNumber(int number);

  /// No description provided for @suggestRouteAddStop.
  ///
  /// In es, this message translates to:
  /// **'+ Añadir parada'**
  String get suggestRouteAddStop;

  /// No description provided for @suggestRouteTimesKnown.
  ///
  /// In es, this message translates to:
  /// **'Horas que conoces'**
  String get suggestRouteTimesKnown;

  /// No description provided for @suggestRouteNotesLabel.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get suggestRouteNotesLabel;

  /// No description provided for @suggestRouteNotesHint.
  ///
  /// In es, this message translates to:
  /// **'Cualquier detalle adicional...'**
  String get suggestRouteNotesHint;

  /// No description provided for @suggestRouteAddTimeTitle.
  ///
  /// In es, this message translates to:
  /// **'Añadir hora'**
  String get suggestRouteAddTimeTitle;

  /// No description provided for @suggestRouteAddTimeHint.
  ///
  /// In es, this message translates to:
  /// **'HH:MM'**
  String get suggestRouteAddTimeHint;

  /// No description provided for @suggestRouteAddTimeConfirm.
  ///
  /// In es, this message translates to:
  /// **'AÑADIR'**
  String get suggestRouteAddTimeConfirm;

  /// No description provided for @incidentSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'¿QUÉ HA PASADO?'**
  String get incidentSheetTitle;

  /// No description provided for @incidentNoShow.
  ///
  /// In es, this message translates to:
  /// **'No pasó'**
  String get incidentNoShow;

  /// No description provided for @incidentDelay.
  ///
  /// In es, this message translates to:
  /// **'Retraso'**
  String get incidentDelay;

  /// No description provided for @incidentFull.
  ///
  /// In es, this message translates to:
  /// **'Lleno'**
  String get incidentFull;

  /// No description provided for @incidentDetour.
  ///
  /// In es, this message translates to:
  /// **'Desvío'**
  String get incidentDetour;

  /// No description provided for @incidentBreakdown.
  ///
  /// In es, this message translates to:
  /// **'Avería'**
  String get incidentBreakdown;

  /// No description provided for @incidentOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get incidentOther;

  /// No description provided for @incidentPositiveLabel.
  ///
  /// In es, this message translates to:
  /// **'POSITIVO:'**
  String get incidentPositiveLabel;

  /// No description provided for @incidentPunctual.
  ///
  /// In es, this message translates to:
  /// **'Puntual'**
  String get incidentPunctual;

  /// No description provided for @incidentKind.
  ///
  /// In es, this message translates to:
  /// **'Amable'**
  String get incidentKind;

  /// No description provided for @incidentClean.
  ///
  /// In es, this message translates to:
  /// **'Limpio'**
  String get incidentClean;

  /// No description provided for @incidentCommentHint.
  ///
  /// In es, this message translates to:
  /// **'Comentario (opcional)'**
  String get incidentCommentHint;

  /// No description provided for @driverStartTrip.
  ///
  /// In es, this message translates to:
  /// **'Iniciar viaje'**
  String get driverStartTrip;

  /// No description provided for @driverSelectRouteFirst.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una ruta'**
  String get driverSelectRouteFirst;

  /// No description provided for @driverLoadRoutes.
  ///
  /// In es, this message translates to:
  /// **'Cargar rutas'**
  String get driverLoadRoutes;

  /// No description provided for @routeShareTitle.
  ///
  /// In es, this message translates to:
  /// **'Compartir ruta'**
  String get routeShareTitle;

  /// No description provided for @routeShareWithUser.
  ///
  /// In es, this message translates to:
  /// **'Compartir con usuario'**
  String get routeShareWithUser;

  /// No description provided for @routeShareEmailHint.
  ///
  /// In es, this message translates to:
  /// **'email@ejemplo.com'**
  String get routeShareEmailHint;

  /// No description provided for @routeSharePublicLink.
  ///
  /// In es, this message translates to:
  /// **'Enlace público'**
  String get routeSharePublicLink;

  /// No description provided for @routeShareGenerateLink.
  ///
  /// In es, this message translates to:
  /// **'Generar enlace'**
  String get routeShareGenerateLink;

  /// No description provided for @routeShareRegenerateLink.
  ///
  /// In es, this message translates to:
  /// **'Regenerar enlace'**
  String get routeShareRegenerateLink;

  /// No description provided for @routeShareNeedLogin.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para compartir rutas'**
  String get routeShareNeedLogin;

  /// No description provided for @routeShareLinkGenerated.
  ///
  /// In es, this message translates to:
  /// **'Enlace generado'**
  String get routeShareLinkGenerated;

  /// No description provided for @mapFilterTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtros del mapa'**
  String get mapFilterTitle;

  /// No description provided for @mapFilterRouteSource.
  ///
  /// In es, this message translates to:
  /// **'Origen de la ruta'**
  String get mapFilterRouteSource;

  /// No description provided for @mapFilterOfficial.
  ///
  /// In es, this message translates to:
  /// **'Oficiales'**
  String get mapFilterOfficial;

  /// No description provided for @mapFilterCommunity.
  ///
  /// In es, this message translates to:
  /// **'Comunitarias'**
  String get mapFilterCommunity;

  /// No description provided for @mapFilterUpcoming.
  ///
  /// In es, this message translates to:
  /// **'Próximas salidas'**
  String get mapFilterUpcoming;

  /// No description provided for @mapFilterMinutes.
  ///
  /// In es, this message translates to:
  /// **'{m} min'**
  String mapFilterMinutes(int m);

  /// No description provided for @mapFilterAccessibility.
  ///
  /// In es, this message translates to:
  /// **'Accesibilidad'**
  String get mapFilterAccessibility;

  /// No description provided for @mapFilterOnlyAccessible.
  ///
  /// In es, this message translates to:
  /// **'Solo accesibles'**
  String get mapFilterOnlyAccessible;

  /// No description provided for @mapFilterFavorites.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get mapFilterFavorites;

  /// No description provided for @mapFilterOnlyFavorites.
  ///
  /// In es, this message translates to:
  /// **'Solo favoritos'**
  String get mapFilterOnlyFavorites;

  /// No description provided for @myContributionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis contribuciones'**
  String get myContributionsTitle;

  /// No description provided for @myContributionsReload.
  ///
  /// In es, this message translates to:
  /// **'Recargar'**
  String get myContributionsReload;

  /// No description provided for @myContributionsSummary.
  ///
  /// In es, this message translates to:
  /// **'{suggestions} sugerencias · {feedbacks} feedbacks · {reports} reportes'**
  String myContributionsSummary(int suggestions, int feedbacks, int reports);

  /// No description provided for @myContributionsLabelSuggestions.
  ///
  /// In es, this message translates to:
  /// **'sugerencias'**
  String get myContributionsLabelSuggestions;

  /// No description provided for @myContributionsLabelCorrections.
  ///
  /// In es, this message translates to:
  /// **'correcciones'**
  String get myContributionsLabelCorrections;

  /// No description provided for @myContributionsLabelReports.
  ///
  /// In es, this message translates to:
  /// **'reportes'**
  String get myContributionsLabelReports;

  /// No description provided for @myContributionsLabelPhotos.
  ///
  /// In es, this message translates to:
  /// **'fotos'**
  String get myContributionsLabelPhotos;

  /// No description provided for @myContributionsTabSuggestions.
  ///
  /// In es, this message translates to:
  /// **'Sugerencias'**
  String get myContributionsTabSuggestions;

  /// No description provided for @myContributionsTabFeedback.
  ///
  /// In es, this message translates to:
  /// **'Feedback'**
  String get myContributionsTabFeedback;

  /// No description provided for @myContributionsTabReports.
  ///
  /// In es, this message translates to:
  /// **'Reportes'**
  String get myContributionsTabReports;

  /// No description provided for @myContributionsEmptyFeedback.
  ///
  /// In es, this message translates to:
  /// **'Sin feedback'**
  String get myContributionsEmptyFeedback;

  /// No description provided for @myContributionsEmptyFeedbackSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu feedback enviado aparecerá aquí'**
  String get myContributionsEmptyFeedbackSubtitle;

  /// No description provided for @myContributionsEmptyReports.
  ///
  /// In es, this message translates to:
  /// **'Sin reportes'**
  String get myContributionsEmptyReports;

  /// No description provided for @myContributionsEmptyReportsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tus reportes de incidencias aparecerán aquí'**
  String get myContributionsEmptyReportsSubtitle;

  /// No description provided for @myContributionsLocalDraft.
  ///
  /// In es, this message translates to:
  /// **'Borrador local'**
  String get myContributionsLocalDraft;

  /// No description provided for @myContributionsNoDescription.
  ///
  /// In es, this message translates to:
  /// **'Sin descripción'**
  String get myContributionsNoDescription;

  /// No description provided for @reputationCurrentRank.
  ///
  /// In es, this message translates to:
  /// **'Actual'**
  String get reputationCurrentRank;

  /// Splash screen tagline below app title
  ///
  /// In es, this message translates to:
  /// **'TU TRANSPORTE PÚBLICO'**
  String get appTagline;

  /// Home tab section: nearby stops
  ///
  /// In es, this message translates to:
  /// **'PARADAS CERCA DE TI'**
  String get homeSectionNearbyStops;

  /// Home tab section: my lines (favorites)
  ///
  /// In es, this message translates to:
  /// **'MIS LÍNEAS'**
  String get homeSectionMyLines;

  /// Home tab section: alerts
  ///
  /// In es, this message translates to:
  /// **'AVISOS'**
  String get homeSectionAlerts;

  /// Home tab habitual trip header
  ///
  /// In es, this message translates to:
  /// **'TU PRÓXIMO BUS'**
  String get homeSectionNextBus;

  /// Home tab city picker tooltip
  ///
  /// In es, this message translates to:
  /// **'Cambiar ciudad'**
  String get homeChangeCityTooltip;

  /// Home tab default city name fallback
  ///
  /// In es, this message translates to:
  /// **'Jerez de la Frontera'**
  String get homeDefaultCity;

  /// No description provided for @accessibilityThemeSystemSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Sigue la configuración del dispositivo'**
  String get accessibilityThemeSystemSubtitle;

  /// No description provided for @accessibilityThemeLightSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Fondo luminoso, alto contraste diurno'**
  String get accessibilityThemeLightSubtitle;

  /// No description provided for @accessibilityThemeDarkSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Fondo oscuro, menor consumo en OLED'**
  String get accessibilityThemeDarkSubtitle;

  /// No description provided for @accessibilityLanguageSystemSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Sigue el idioma del dispositivo'**
  String get accessibilityLanguageSystemSubtitle;

  /// No description provided for @accessibilityLanguageEsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Forzar idioma en español'**
  String get accessibilityLanguageEsSubtitle;

  /// No description provided for @accessibilityLanguageEnSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Force English language'**
  String get accessibilityLanguageEnSubtitle;

  /// No description provided for @accessibilitySystemPrefAnimations.
  ///
  /// In es, this message translates to:
  /// **'Animaciones'**
  String get accessibilitySystemPrefAnimations;

  /// No description provided for @accessibilitySystemPrefTextSize.
  ///
  /// In es, this message translates to:
  /// **'Tamaño de texto'**
  String get accessibilitySystemPrefTextSize;

  /// No description provided for @accessibilitySystemPrefBoldText.
  ///
  /// In es, this message translates to:
  /// **'Texto en negrita'**
  String get accessibilitySystemPrefBoldText;

  /// No description provided for @accessibilitySystemPrefActivated.
  ///
  /// In es, this message translates to:
  /// **'Activado'**
  String get accessibilitySystemPrefActivated;

  /// No description provided for @accessibilitySystemPrefDeactivated.
  ///
  /// In es, this message translates to:
  /// **'Desactivado'**
  String get accessibilitySystemPrefDeactivated;

  /// No description provided for @accessibilitySystemPrefReduced.
  ///
  /// In es, this message translates to:
  /// **'Reducidas'**
  String get accessibilitySystemPrefReduced;

  /// No description provided for @accessibilitySystemPrefEnabled.
  ///
  /// In es, this message translates to:
  /// **'Habilitadas'**
  String get accessibilitySystemPrefEnabled;

  /// Accessibility system preferences footnote
  ///
  /// In es, this message translates to:
  /// **'Estos ajustes se leen del sistema operativo. Cámbialos desde los ajustes del dispositivo para que la app responda.'**
  String get accessibilitySystemPrefFootnote;

  /// Error when operator_admin has no operator_id in their profile
  ///
  /// In es, this message translates to:
  /// **'No se encontró el operador asociado a tu cuenta. Contacta con soporte.'**
  String get operatorAdminMissingOperator;

  /// Error genérico al cargar admin/users
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la lista de usuarios. Inténtalo de nuevo.'**
  String get adminUsersLoadError;

  /// Banner indicating offline region is limited to Jerez in demo version
  ///
  /// In es, this message translates to:
  /// **'Versión demo: solo se puede descargar la región de Jerez de la Frontera. Selección libre de región disponible en próximas versiones.'**
  String get offlineRegionDemoLimitation;

  /// SnackBar message when a route editor draft is saved locally
  ///
  /// In es, this message translates to:
  /// **'Borrador guardado correctamente'**
  String get editorDraftSaved;

  /// Título de la pestaña de tarjeta NFC
  ///
  /// In es, this message translates to:
  /// **'TARJETA NFC'**
  String get cardNfcTitle;

  /// Mensaje cuando NFC no está disponible
  ///
  /// In es, this message translates to:
  /// **'NFC NO DISPONIBLE'**
  String get cardNfcUnavailable;

  /// Explicación de uso de NFC
  ///
  /// In es, this message translates to:
  /// **'La lectura de tarjetas de transporte requiere un dispositivo con NFC. Acerca la tarjeta a la parte trasera del móvil.'**
  String get cardNfcExplanation;

  /// Botón para ocultar horarios
  ///
  /// In es, this message translates to:
  /// **'Ocultar ▴'**
  String get scheduleHideAll;

  /// Botón para mostrar todos los horarios
  ///
  /// In es, this message translates to:
  /// **'Ver todos ▾'**
  String get scheduleShowAll;

  /// Placeholder para código de activación
  ///
  /// In es, this message translates to:
  /// **'XXX-XXXX-XX'**
  String get activateDriverCodeHint;

  /// Título para sugerencia de mejora de ruta
  ///
  /// In es, this message translates to:
  /// **'MEJORAR INFORMACIÓN'**
  String get routeFeedbackImproveInfo;

  /// Etiqueta Línea en feedback
  ///
  /// In es, this message translates to:
  /// **'Línea:'**
  String get routeFeedbackLine;

  /// Etiqueta Parada en feedback
  ///
  /// In es, this message translates to:
  /// **'Parada:'**
  String get routeFeedbackStop;

  /// Etiqueta Tipo de mejora en feedback
  ///
  /// In es, this message translates to:
  /// **'Tipo de mejora'**
  String get routeFeedbackImproveType;

  /// Botón para recargar datos offline
  ///
  /// In es, this message translates to:
  /// **'Recargar desde assets'**
  String get offlineDataReloadButton;

  /// Explicación de la fuente de datos offline
  ///
  /// In es, this message translates to:
  /// **'Esta app usa un bundle JSON local con datos de COMUJESA (Jerez).'**
  String get offlineDataExplanation;

  /// Banner de prototipo en importación IA
  ///
  /// In es, this message translates to:
  /// **'PROTOTIPO'**
  String get aiScheduleImportPrototypeBanner;

  /// Mensaje de confirmación al pulsar atrás para salir
  ///
  /// In es, this message translates to:
  /// **'Pulsa de nuevo para salir'**
  String get appExitConfirmMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
