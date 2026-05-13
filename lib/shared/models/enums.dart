// ─────────────────────────────────────────────────────────────
//  Transitly – Domain Enums
// ─────────────────────────────────────────────────────────────

enum ServiceType {
  urban,
  metropolitan,
  interurban,
  longDistance,
  special,
  school,
  onDemand;

  String get label => switch (this) {
        urban => 'Urbano',
        metropolitan => 'Metropolitano',
        interurban => 'Interurbano',
        longDistance => 'Larga distancia',
        special => 'Especial',
        school => 'Escolar',
        onDemand => 'Bajo demanda',
      };

  static ServiceType fromString(String v) =>
      ServiceType.values.firstWhere((e) => e.name == v, orElse: () => urban);
}

enum RouteStatus {
  draft,
  pendingVerification,
  verified,
  official,
  suspended;

  String get label => switch (this) {
        draft => 'Borrador',
        pendingVerification => 'Pendiente de verificación',
        verified => 'Verificada',
        official => 'Oficial',
        suspended => 'Suspendida',
      };

  static RouteStatus fromString(String v) =>
      RouteStatus.values.firstWhere((e) => e.name == v, orElse: () => draft);
}

enum RouteDirection {
  outbound,
  return_,
  both;

  String get label => switch (this) {
        outbound => 'Ida',
        return_ => 'Vuelta',
        both => 'Ambos',
      };

  static RouteDirection fromString(String v) => switch (v) {
        'return' => return_,
        _ => RouteDirection.values
            .firstWhere((e) => e.name == v, orElse: () => outbound),
      };
}

enum DayType {
  weekday,
  saturday,
  sundayHoliday,
  special;

  String get label => switch (this) {
        weekday => 'Laborable',
        saturday => 'Sábado',
        sundayHoliday => 'Domingo/Festivo',
        special => 'Especial',
      };

  static DayType fromString(String v) => switch (v) {
        'sunday_holiday' => sundayHoliday,
        'sundayHoliday' => sundayHoliday,
        _ =>
          DayType.values.firstWhere((e) => e.name == v, orElse: () => weekday),
      };
}

enum TripStatus {
  onTime,
  delay,
  cancelled,
  completed;

  String get label => switch (this) {
        onTime => 'A tiempo',
        delay => 'Retrasado',
        cancelled => 'Cancelado',
        completed => 'Completado',
      };

  static TripStatus fromString(String v) => switch (v) {
        'inRoute' => onTime,
        _ => TripStatus.values
            .firstWhere((e) => e.name == v, orElse: () => onTime),
      };
}

enum BusCapacity {
  empty,
  seatsAvailable,
  halfFull,
  full,
  overcrowded;

  String get label => switch (this) {
        empty => 'Vacío',
        seatsAvailable => 'Asientos libres',
        halfFull => 'Medio lleno',
        full => 'Lleno',
        overcrowded => 'Saturado',
      };

  static BusCapacity fromString(String v) => BusCapacity.values
      .firstWhere((e) => e.name == v, orElse: () => seatsAvailable);
}

enum IncidentType {
  busNoShow,
  delay,
  busFull,
  detour,
  dangerousDriving,
  stopBlocked,
  shelterDamaged,
  signageMissing,
  scheduleWrong,
  accessibilityIssue,
  punctual,
  driverKind,
  stopClean;

  String get label => switch (this) {
        busNoShow => 'Bus no pasó',
        delay => 'Retraso',
        busFull => 'Bus lleno',
        detour => 'Desvío',
        dangerousDriving => 'Conducción peligrosa',
        stopBlocked => 'Parada bloqueada',
        shelterDamaged => 'Marquesina dañada',
        signageMissing => 'Señalización ausente',
        scheduleWrong => 'Horario incorrecto',
        accessibilityIssue => 'Problema accesibilidad',
        punctual => 'Puntualidad destacada',
        driverKind => 'Conductor amable',
        stopClean => 'Parada limpia',
      };

  static IncidentType fromString(String v) => switch (v) {
        'noShow' => busNoShow,
        _ => IncidentType.values
            .firstWhere((e) => e.name == v, orElse: () => delay),
      };
}

enum IncidentCategory {
  service,
  infrastructure,
  positive;

  String get label => switch (this) {
        service => 'Servicio',
        infrastructure => 'Infraestructura',
        positive => 'Positivo',
      };

  static IncidentCategory fromString(String v) => IncidentCategory.values
      .firstWhere((e) => e.name == v, orElse: () => service);
}

enum AlertSeverity {
  info,
  warning,
  critical;

  String get label => switch (this) {
        info => 'Información',
        warning => 'Aviso',
        critical => 'Crítico',
      };

  static AlertSeverity fromString(String v) => AlertSeverity.values
      .firstWhere((e) => e.name == v, orElse: () => info);
}

enum ReputationLevel {
  new_,
  contributor,
  trusted,
  expert;

  String get label => switch (this) {
        new_ => 'Nuevo',
        contributor => 'Colaborador',
        trusted => 'De confianza',
        expert => 'Experto',
      };

  static ReputationLevel fromString(String v) => switch (v) {
        'new' => new_,
        _ => ReputationLevel.values
            .firstWhere((e) => e.name == v, orElse: () => new_),
      };
}

enum SuggestionStatus {
  idea,
  inReview,
  enriched,
  accepted,
  converted,
  rejected,
  duplicate;

  String get label => switch (this) {
        idea => 'Idea',
        inReview => 'En revisión',
        enriched => 'Enriquecida',
        accepted => 'Aceptada',
        converted => 'Convertida',
        rejected => 'Rechazada',
        duplicate => 'Duplicada',
      };

  static SuggestionStatus fromString(String v) => SuggestionStatus.values
      .firstWhere((e) => e.name == v, orElse: () => idea);
}

enum FeedbackType {
  routePath,
  stopMissing,
  stopRemoved,
  stopName,
  stopLocation,
  stopOrder,
  scheduleOutdated,
  scheduleMissing,
  scheduleAdded,
  generalInfo,
  suggestion,
  positive;

  String get label => switch (this) {
        routePath => 'Recorrido',
        stopMissing => 'Parada inexistente',
        stopRemoved => 'Parada eliminada',
        stopName => 'Nombre de parada',
        stopLocation => 'Ubicación de parada',
        stopOrder => 'Orden de paradas',
        scheduleOutdated => 'Horario desactualizado',
        scheduleMissing => 'Horario faltante',
        scheduleAdded => 'Horario añadido',
        generalInfo => 'Información general',
        suggestion => 'Sugerencia',
        positive => 'Positivo',
      };

  static FeedbackType fromString(String v) => switch (v) {
        'scheduleError' => scheduleOutdated,
        'stopMoved' => stopLocation,
        _ => FeedbackType.values
            .firstWhere((e) => e.name == v, orElse: () => generalInfo),
      };
}

enum FeedbackStatus {
  submitted,
  inReview,
  accepted,
  applied,
  rejected,
  duplicate;

  String get label => switch (this) {
        submitted => 'Enviado',
        inReview => 'En revisión',
        accepted => 'Aceptado',
        applied => 'Aplicado',
        rejected => 'Rechazado',
        duplicate => 'Duplicado',
      };

  static FeedbackStatus fromString(String v) => switch (v) {
        'open' => submitted,
        _ => FeedbackStatus.values
            .firstWhere((e) => e.name == v, orElse: () => submitted),
      };
}

enum Priority {
  low,
  medium,
  high,
  urgent;

  String get label => switch (this) {
        low => 'Baja',
        medium => 'Media',
        high => 'Alta',
        urgent => 'Urgente',
      };

  static Priority fromString(String v) =>
      Priority.values.firstWhere((e) => e.name == v, orElse: () => medium);
}

enum ChangeType {
  pathUpdated,
  stopAdded,
  stopRemoved,
  stopRenamed,
  stopMoved,
  scheduleUpdated,
  scheduleAdded,
  scheduleRemoved,
  infoUpdated,
  statusChanged,
  created,
  verified,
  officialized;

  String get label => switch (this) {
        pathUpdated => 'Recorrido actualizado',
        stopAdded => 'Parada añadida',
        stopRemoved => 'Parada eliminada',
        stopRenamed => 'Parada renombrada',
        stopMoved => 'Parada reubicada',
        scheduleUpdated => 'Horario actualizado',
        scheduleAdded => 'Horario añadido',
        scheduleRemoved => 'Horario eliminado',
        infoUpdated => 'Información actualizada',
        statusChanged => 'Estado cambiado',
        created => 'Creada',
        verified => 'Verificada',
        officialized => 'Oficializada',
      };

  static ChangeType fromString(String v) => ChangeType.values
      .firstWhere((e) => e.name == v, orElse: () => infoUpdated);
}

enum AchievementCategory {
  usage,
  exploration,
  contribution,
  sustainability;

  String get label => switch (this) {
        usage => 'Uso',
        exploration => 'Exploración',
        contribution => 'Contribución',
        sustainability => 'Sostenibilidad',
      };

  static AchievementCategory fromString(String v) => switch (v) {
        'trips' => usage,
        'community' => contribution,
        'special' => exploration,
        _ => AchievementCategory.values
            .firstWhere((e) => e.name == v, orElse: () => usage),
      };
}

/// Origen de una ruta: oficial (operador) o comunitaria (usuario).
enum RouteSource { official, community }

/// Fuente del dato de posición de un bus.
enum BusPositionSource { gtfsRealtime, driver, estimated }
