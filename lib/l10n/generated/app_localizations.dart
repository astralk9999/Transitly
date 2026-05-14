import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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

  /// Admin operators unknown error
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

  /// Accessible buses source tag: official
  ///
  /// In es, this message translates to:
  /// **'Oficial'**
  String get accessibleBusesSourceOfficial;

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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
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
