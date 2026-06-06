-- 026_reputation_notifications.sql — Notificaciones in-app por XP y rank-up
-- Cuando add_xp() se ejecuta, inserta automáticamente una notificación
-- al usuario para que vea su progreso desde la campanita.

ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'xp_earned';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'rank_up';
