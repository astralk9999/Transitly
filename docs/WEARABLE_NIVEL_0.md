# Wearable — Nivel 0 · Transitly

> Documentación para notificaciones en dispositivos wearable (Android Wear OS y watchOS).
> Nivel 0 = sin integración nativa más allá de lo que el sistema operativo proporciona automáticamente.

---

## Principio general

Transitly envía notificaciones push a través de Firebase Cloud Messaging (FCM) en Android
y APNs en iOS. Ambos sistemas delegan las notificaciones a los wearables emparejados
de forma automática, sin necesidad de código específico en la app.

---

## Android Wear OS

### Funcionamiento automático

Las notificaciones configuradas con un `NotificationChannel` de importancia **HIGH**
(maxPriority) se muestran automáticamente en el reloj Wear OS emparejado al teléfono.
No se requiere un módulo Wear OS independiente.

- **Requisito:** Android Wear OS 3.0+ emparejado vía Wear OS app.
- **Canal usado:** `transitly_alerts` (configurado en `lib/data/push/push_service.dart`).
- **Qué aparece:** título, cuerpo, y acciones (si están configuradas).
- **Qué NO aparece:** imágenes rich, botones inline, layouts personalizados.

### Verificación rápida

1. Emparejar el reloj Wear OS con el teléfono Android.
2. Activar `"Buses cerca"` en Perfil → Notificaciones.
3. Simular una notificación (desde Supabase Dashboard → tabla `notifications` insert).
4. Verificar que la notificación aparece en el reloj en <5 s.

### Notificaciones silenciosas (Quiet Hours)

Las notificaciones enviadas durante el horario silencioso configurado en la app siguen
llegando al dispositivo, pero sin sonido ni vibración. Esto aplica tanto al teléfono como
al reloj, ya que el sistema operativo respeta la prioridad del canal.

---

## watchOS (Apple Watch)

### Funcionamiento automático

iOS reenvía automáticamente las notificaciones push al Apple Watch emparejado.
No se requiere un target watchOS independiente ni código adicional.

- **Requisito:** watchOS 9.0+ emparejado al iPhone.
- **Qué aparece:** título, cuerpo, categoría de notificación.
- **Qué NO aparece:** complicaciones, acciones interactivas desde el watch (requiere Nivel 1+).

### Verificación rápida

1. Emparejar el Apple Watch con el iPhone.
2. Activar `"Mis rutas"` en Perfil → Notificaciones.
3. Solicitar una ruta compartida desde otro usuario.
4. Verificar que la notificación aparece en el Apple Watch.

---

## Instrucciones para probar notificaciones

### Opción A — Desde Supabase Dashboard

```sql
INSERT INTO notifications (user_id, type, title, body, read)
VALUES (
  '<tu_user_id>',
  'bus_approaching_favorite',
  'Bus L1 acercándose',
  'El bus de la línea L1 está a 3 paradas de tu favorita.',
  false
);
```

### Opción B — Desde el simulador (Android)

```bash
# Terminal: enviar notificación vía FCM usando el token del dispositivo
# Obtener token desde: Supabase → tabla device_tokens
# Usar Firebase Console → Cloud Messaging → Send test message
```

### Opción C — Desde el simulador (iOS)

Las notificaciones push NO funcionan en el simulador de iOS. Probar en dispositivo físico.

---

## Screenshots

> **Placeholders.** Reemplazar con capturas reales antes del release.

| Plataforma | Captura | Estado |
|------------|---------|--------|
| Wear OS — Notificación entrante | `docs/assets/wearos_notif.png` | ⏳ Pendiente |
| Wear OS — Centro notificaciones | `docs/assets/wearos_center.png` | ⏳ Pendiente |
| watchOS — Notificación entrante | `docs/assets/watchos_notif.png` | ⏳ Pendiente |
| watchOS — Centro notificaciones | `docs/assets/watchos_center.png` | ⏳ Pendiente |

---

## Roadmap de niveles wearable

| Nivel | Descripción | Estado |
|-------|-------------|--------|
| **0** | Notificaciones automáticas vía sistema operativo | ✅ Actual |
| **1** | App companion básica (vista de notificaciones, sin interacción) | ⏳ Futuro |
| **2** | Complicaciones + acciones interactivas (responder, marcar leído) | ⏳ Futuro |
