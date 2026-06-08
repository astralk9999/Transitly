-- 044_handle_new_user_robust.sql — registro de usuario a prueba de fallos.
-- Un error en este trigger AFTER INSERT revierte toda la creacion del usuario
-- en auth.users (el signup falla del todo). Lo hacemos idempotente con
-- ON CONFLICT DO NOTHING y, para usuarios OAuth (Google), tomamos el
-- display_name de name/full_name del meta ademas de display_name.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.profiles (id, display_name, email_verified)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'display_name',
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      split_part(NEW.email, '@', 1)
    ),
    NEW.email_confirmed_at IS NOT NULL
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_preferences (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$function$;
