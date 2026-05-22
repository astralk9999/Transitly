# C4 Diagrams — Transitly

> **Version:** 1.0 · **Notation:** C4 Model (https://c4model.com)

---

## C4-1: System Context

```mermaid
C4Context
    title System Context diagram — Transitly

    Person(user, "Passenger / Driver", "Public transport user in Spain")
    Person(admin, "Administrator", "Transit agency staff")

    System(transitly, "Transitly", "Multi-operator public transport companion with offline-first architecture, NFC balance reading, and community features")

    System_Ext(supabase, "Supabase", "Backend: PostgREST, GoTrue, Realtime, Edge Functions, Storage")
    System_Ext(firebase, "Firebase", "Push notifications (FCM)")
    System_Ext(sentry, "Sentry", "Crash reporting and performance monitoring")
    System_Ext(posthog, "PostHog", "Product analytics (opt-in)")
    System_Ext(maptiler, "MapTiler", "Map tiles (raster/vector)")

    Rel(user, transitly, "Views routes, reports incidents, scans NFC")
    Rel(admin, transitly, "Manages operators, moderates content")
    Rel(transitly, supabase, "REST + Realtime + Auth")
    Rel(transitly, firebase, "Receives push notifications")
    Rel(transitly, sentry, "Reports crashes and spans")
    Rel(transitly, posthog, "Sends product events (consented)")
    Rel(transitly, maptiler, "Loads map tiles")
```

---

## C4-2: Container Diagram

```mermaid
C4Container
    title Container diagram — Transitly

    Person(user, "User")

    Container_Boundary(mobile, "Mobile App") {
        Container(flutter, "Flutter App", "Dart/Flutter 3.x", "UI, state management (Riverpod), offline cache (Hive), NFC reader")
        ContainerDb(hive, "Hive Cache", "Key-value store", "Routes, stops, schedules, preferences, offline queue")
    }

    Container_Boundary(cloud, "Supabase Cloud") {
        Container(postgrest, "PostgREST", "REST API", "Auto-generated CRUD from PostgreSQL schema")
        ContainerDb(postgres, "PostgreSQL 15", "Database", "13 migrations, RLS policies")
        Container(gotrue, "GoTrue", "Auth server", "Email/password, magic link, JWT")
        Container(realtime, "Realtime", "WebSocket server", "Broadcast + presence for bus locations")
        Container(edge, "Edge Functions", "Deno/TypeScript", "send_notification, import_gtfs")
        Container(storage, "Storage", "S3-compatible", "User avatars, GTFS files")
    }

    System_Ext(firebase, "FCM", "Push delivery")
    System_Ext(sentry, "Sentry", "Observability")
    System_Ext(posthog, "PostHog", "Analytics")
    System_Ext(maptiler, "MapTiler", "Tiles")

    Rel(flutter, postgrest, "REST queries/mutations, JSON")
    Rel(flutter, gotrue, "Auth (sign in/up, token refresh)")
    Rel(flutter, realtime, "WebSocket subscriptions")
    Rel(flutter, storage, "File upload/download")
    Rel(flutter, hive, "Read/write cache")

    Rel(edge, firebase, "Send push via FCM HTTP v1 API")
    Rel(edge, postgres, "Query user tokens")

    Rel(flutter, sentry, "Crash reports + spans")
    Rel(flutter, posthog, "Product events")
    Rel(flutter, maptiler, "Tile requests")
```

---

## C4-3: Component Diagram (Data Layer)

```mermaid
C4Component
    title Component diagram — Data Layer

    Container_Boundary(data_layer, "lib/data/") {
        Component(repos, "12 Repositories", "abstract + remote + local + mock + provider", "Data access pattern (SWR)")
        Component(cache, "Hive Init + Adapters", "Boxes: routes, stops, schedules, operators, prefs, alerts, pendingActions, authSessionMeta", "Local persistence")
        Component(sync, "Offline Sync", "PendingActionsQueue + OfflineSyncService", "FIFO queue with exponential backoff")
        Component(channel_mgr, "RealtimeChannelManager", "Multiplexed WebSocket channels", "Shared subscription manager")
    }

    Container_Boundary(supabase_api, "Supabase") {
        ComponentDb(tables, "Tables", "operators, routes, stops, schedules, incidents, route_feedback, route_suggestions, feature_requests, notifications, user_preferences, offline_regions, bus_positions")
    }

    Rel(repos, tables, "REST queries via SupabaseClient")
    Rel(repos, cache, "Stale-while-revalidate")
    Rel(repos, sync, "Enqueue writes when offline")
    Rel(repos, channel_mgr, "Subscribe to Realtime channels")
    Rel(channel_mgr, tables, "WebSocket subscription")
```

---

## C4-4: Component Diagram (Features)

```mermaid
C4Component
    title Component diagram — Features

    Container_Boundary(features, "lib/features/") {
        Component(home, "Home", "HomeTab, SearchTab, ProfileTab")
        Component(map, "Map", "MapTab, map filters, route polylines")
        Component(auth, "Auth", "Sign in, sign up, magic link, recover")
        Component(driver, "Driver", "Dashboard, live tracking, start route")
        Component(community, "Community", "Incidents, suggestions, feedback, voting")
        Component(admin, "Admin", "Operator CRUD, moderator inbox, user management")
        Component(nfc, "NFC", "Card scan, balance read")
        Component(editor, "Editor", "Community route wizard")
        Component(profile, "Profile", "Settings, accessibility, privacy")
    }

    Container_Boundary(shared, "lib/shared/") {
        Component(providers, "Global Providers", "Riverpod: theme, locale, user, NFC, connectivity")
        Component(models, "Models", "@freezed: Route, Stop, User, Incident, etc.")
        Component(widgets, "Shared Widgets", "Pressable, GlassCard, TransitButton, StaggerList, ...")
    }

    Rel(home, providers, "ref.watch")
    Rel(map, providers, "ref.watch")
    Rel(admin, providers, "ref.read")
    Rel(community, providers, "ref.watch")

    Rel(providers, repos, "Data access")
```

---

## Legend

| Symbol | Meaning |
|--------|---------|
| `C4Context` | System context (users + external systems) |
| `C4Container` | Deployable units (app, database, edge functions) |
| `C4Component` | Logical components (repositories, providers, features) |
