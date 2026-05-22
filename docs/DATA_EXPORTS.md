# Data Exports — Transitly

> **GDPR Art. 20 · Data Portability** · Version: 1.0 · Owner: Platform

## Schema

The `data_exports` table (`001_init.sql` line 446) tracks every export request:

| Column | Type | Description |
|--------|------|-------------|
| `id` | `UUID` | Primary key |
| `user_id` | `UUID` → `profiles(id)` | Owner (cascade delete) |
| `status` | `TEXT` | `queued` → `processing` → `completed` / `failed` |
| `file_url` | `TEXT` | Storage URL once the ZIP is ready |
| `requested_at` | `TIMESTAMPTZ` | Defaults to `NOW()` |
| `completed_at` | `TIMESTAMPTZ` | Set by the Edge Function on success |

Indexes: `idx_data_exports_user_status` on `(user_id, status)` (`016_data_exports.sql`).

The companion table `data_deletion_requests` handles GDPR Art. 17 (right to erasure), documented separately in `docs/RIGHT_TO_BE_FORGOTTEN.md`.

## What data can be exported

The export includes all personal data tied to the requesting user:

| Entity | Tables / sources |
|--------|-----------------|
| Profile | `profiles` (display name, avatar URL, email, email verified status) |
| Preferences | `user_preferences` (theme, locale, accessibility settings) |
| Privacy consents | `privacy_consents` (analytics, marketing, crash reporting grants) |
| Incident reports | `incidents` authored by the user |
| Route feedback | `route_feedback` authored by the user |
| Saved stops / routes | `user_saved_stops`, `user_saved_routes` |
| Offline regions | `offline_regions` metadata (not tile data) |
| Notifications received | `app_notifications` for the user |

Data owned by the operator (bus positions, schedules, routes) is NOT included — it belongs to the operator, not the user. Only user-authored or user-scoped rows are exported.

## How to trigger an export

Users trigger exports from the **Privacy screen** (`lib/features/privacy/privacy_screen.dart`):

1. Navigate to Profile → Privacy → Data Management.
2. Tap **"Request Data Export"**.
3. The app inserts a row with `status = 'queued'` into `data_exports`:

```dart
await client.from('data_exports').insert({
  'user_id': authState.user.id,
  'status': 'queued',
});
```

An optional shortcut exists: authenticated users can call `SELECT request_data_export();` directly (016_data_exports.sql line 19), though the UI path above is the intended flow.

4. A Supabase **Edge Function** (scheduled via `pg_cron` or Supabase Cron) polls `data_exports` for rows with `status = 'queued'`. It:
   - Sets `status = 'processing'`.
   - Queries all user data from the tables listed above.
   - Packages the result as a **ZIP archive** containing `data.json` (structured JSON) plus any binary files (avatar, attached photos).
   - Uploads the ZIP to the `data-exports` Storage bucket under path `<user_id>/<export_id>.zip`.
   - Sets `status = 'completed'` and `file_url` to the Storage URL.

5. The user receives the `file_url` (via the Privacy screen polling the table, or via push notification). The file can be downloaded from Storage (RLS ensures only the owner can select it).

## Format of the export

```
<export_id>.zip
├── data.json           # All tabular data as a structured JSON object
│   ├── profile
│   ├── preferences
│   ├── privacy_consents[]
│   ├── incidents[]
│   ├── route_feedback[]
│   ├── saved_stops[]
│   ├── saved_routes[]
│   ├── offline_regions[]
│   └── notifications[]
└── files/              # Binary assets referenced by data.json
    ├── avatar.png
    ├── incident_<id>.jpg
    └── ...
```

The `data.json` structure uses the same field names as the PostgreSQL rows, making it machine-readable and suitable for import into another service (GDPR Art. 20 requires a "structured, commonly used" format).

## Retention of export files

| Aspect | Policy |
|--------|--------|
| **Bucket** | `data-exports` (private, not public) |
| **Max file size** | 100 MB per file (`004_storage.sql` line 39) |
| **Allowed formats** | `application/zip`, `application/json` |
| **Retention period** | **30 days** from `completed_at` |
| **Auto-purge** | Edge Function cron deletes expired exports (row + storage object) |
| **Owner access** | Only the user who requested the export can SELECT/DELETE via RLS (`004_storage.sql` lines 154–169) |
| **Admin access** | Operators with `is_admin() = true` can SELECT for support purposes |

After 30 days, the export file and its database row are permanently removed. The user must request a new export if needed after that period.

## Security

- RLS on `data_exports` (`002_rls.sql` line 686): users can only SELECT/INSERT their own rows.
- RLS on `data-exports` storage bucket: path must start with `<auth.uid()>/`.
- The Edge Function runs with `service_role` to assemble data across tables, but the output is scoped to the requesting `user_id`.
- No raw database access is given to the user — only the processed ZIP file.

## Related documents

- `docs/RIGHT_TO_BE_FORGOTTEN.md` — GDPR Art. 17 deletion procedure
- `docs/DATA_RETENTION.md` — retention policy for all data types
- `supabase/migrations/001_init.sql` — table definitions
- `supabase/migrations/004_storage.sql` — bucket and storage policies
- `supabase/migrations/016_data_exports.sql` — helper functions and indexes
