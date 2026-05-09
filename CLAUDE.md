# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Build
flutter build apk          # Android APK
flutter build ios          # iOS

# Test & lint
flutter test
flutter analyze
```

No Makefile or custom scripts — standard Flutter CLI only.

## Architecture

**LOCAL FAMILY** is a Flutter family calendar app targeting Android/iOS. The UI is in French.

### State management

Provider (`^6.1.1`) with two root `ChangeNotifier`s injected via `MultiProvider` in `main.dart`:

- `FamAuthProvider` (`lib/providers/auth_provider.dart`) — authentication state, current user, family, role
- `EventProviderFirebase` (`lib/providers/event_provider_firebase.dart`) — calendar events, filtering, real-time sync

Screens consume state via `Consumer`/`Consumer2`. Providers are initialized with `WidgetsBinding.addPostFrameCallback` inside `initState()`.

### Service layer

Three services in `lib/services/`:

- `AuthService` — Firebase Auth (email/password) + Firestore user profile creation
- `FirestoreService` — All Firestore reads/writes (events, families, users, requests)
- `LocalStorageService` — SharedPreferences for local settings/caching

### App flow

```
FirebaseApp init → FamAgendaApp (MultiProvider)
  → AuthWrapper (StreamBuilder on authStateChanges)
    → authenticated + approved  → FirebaseFinalHomeScreen (calendar)
    → authenticated + pending   → PendingApprovalScreen
    → unauthenticated           → LoginScreen
```

### Family & role model

Users belong to a `Family`. Roles drive what actions are permitted:

| Role | Capabilities |
|------|-------------|
| `admin` | Full control, approves join requests |
| `parent` | Create events, invite members |
| `teenager` | Create events |
| `child` | Read-only + own events |
| `guest` | Read-only |

**Join flow:** User signs up with an invite code → creates a `FamilyRequest` (not immediately a member) → admin approves/rejects → user gains `familyId`.

### Data models (`lib/models/`)

Manual `toMap()`/`fromMap()` serialization — no code generation. Key types: `Event`, `FamUser`, `Family`, `FamilySettings`, `LocalEventModel`, `LocalPhotoModel`, `LocalNoteModel`.

Event types: `medical`, `school`, `sport`, `personal`, `family`, `work`, `birthday`, `vacation`.

### Multiple `main_*.dart` files

The project has several entry points (`main_local.dart`, `main_complete.dart`, `main_test.dart`, `main_firebase_final.dart`) reflecting ongoing experimentation between a fully-local backend and Firebase. **`main.dart` is the active entry point** — it uses Firebase.

### Firebase backend

Despite the "100% local" brand positioning, the current app uses:
- Firebase Auth (email/password)
- Cloud Firestore (events, users, families, requests)
- Firebase Messaging (push notifications)

Security rules are in `firestore.rules`. A local-only variant exists but is not the default.

### Key packages

- `table_calendar ^3.0.9` — calendar UI widget
- `provider ^6.1.1` — state management
- `firebase_core / firebase_auth / cloud_firestore / firebase_messaging` — backend
- `shared_preferences ^2.2.2` + `path_provider ^2.1.2` — local storage
- `intl ^0.19.0` — date formatting (French locale)
- `uuid ^4.3.3` — ID generation
