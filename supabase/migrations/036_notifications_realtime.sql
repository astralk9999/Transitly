-- 036_notifications_realtime.sql — entrega en vivo de notificaciones.
--
-- La tabla `notifications` no estaba en la publicación de Realtime, así
-- que el canal del cliente nunca recibía los INSERT: ni push nativo ni
-- refresco del inbox in-app hasta reabrir la app. La añadimos.
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER TABLE notifications REPLICA IDENTITY FULL;
