# Runbook: Push Notification Failure

> **Severity:** P2 · **Owner:** Platform · **Version:** 1.0

## Symptoms

- Users not receiving push notifications for incident resolution / route changes
- `send_notification` Edge Function returns errors
- FCM dashboard shows delivery failures
- `firebase_messaging` token refresh errors in Sentry

## Immediate actions (first 5 minutes)

1. **Check Edge Function health:**
   - Supabase Dashboard → Edge Functions → `send_notification`
   - Look for invocation errors, cold start timeouts
2. **Check FCM status:** https://status.firebase.google.com
3. **Verify server key:** Supabase Dashboard → Project Settings → API → `service_role` key
4. **Check `flutter_local_notifications`:** any platform channel errors in Sentry

## If Edge Function is failing

1. Check logs in Supabase Dashboard → Edge Functions → `send_notification` → Invocations
2. Common causes:
   - FCM server key expired or revoked → regenerate in Firebase Console
   - `fcm_token` NULL in `user_profiles` → users haven't granted notification permission
   - Rate limiting from FCM → check batch size (max 500 tokens per call)
3. Redeploy Edge Function if logic error:
   ```bash
   supabase functions deploy send_notification
   ```

## If FCM is down

1. No client-side action — notifications will be delivered when FCM recovers
2. Monitor FCM status page for ETA
3. Consider in-app banner for time-sensitive notifications

## If client tokens are invalid

1. FCM tokens expire on app reinstall or long inactivity
2. `FirebaseMessaging.onTokenRefresh` should update the token in Supabase
3. Verify the listener is registered in `firebase_setup.dart`

## Rollback

- Push notifications are fire-and-forget; no data loss on failure
- In-app notification inbox (`AppNotification`) is independent of push
- If Edge Function is broken, deploy previous working version:
  ```bash
  supabase functions deploy send_notification --source-ref <previous-commit>
  ```
