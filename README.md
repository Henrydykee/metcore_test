# Filed Notes

Offline-first notes app built with Flutter. Works fully without internet; syncs with a remote server when connectivity is available.

## Setup Instructions

### Prerequisites

- Flutter SDK (>= 3.6.0)
- Node.js (for local API server)
- iOS Simulator / Android Emulator or device

### 1. Clone and install Flutter dependencies

```bash
cd /path/to/sample_project
flutter pub get
```

### 2. Start the local API server (optional, for sync)

The app uses a REST API for remote sync. A mock server is provided:

```bash
cd local_server
npm install
npm run build
npm start
```

Or run in dev mode with auto-reload:

```bash
npm run dev
```

The server runs at `http://localhost:8080` with API base path `/v1`. The app is preconfigured to use `http://localhost:8080/v1`.


For iOS Simulator, `localhost` works. For Android Emulator, use `10.0.2.2:8080`. For a physical device, use your machine's LAN IP (e.g. `192.168.1.x:8080`).

### 4. Run the app

```bash
flutter run
```

Or for a specific device:

```bash
flutter run -d iphone
flutter run -d chrome
```

### 5. Run tests

```bash
flutter test
```

Generate mocks (when adding new dependencies to tests):

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Architecture Overview

The app follows a layered architecture:

```
lib/
├── main.dart                 # App entry, DI wiring
├── app_theme.dart            # Theming
├── core/                     # Shared infrastructure
│   ├── data/
│   │   ├── network/          # Dio-based HTTP client, interceptors
│   │   ├── enums/            # Shared enums (Env, etc.)
│   │   └── models/           # Response models
│   ├── di/                   # GetIt dependency injection
│   ├── platform/             # Env config, secure storage
│   └── utils/                # Logger, error helpers, guarded API calls
└── features/
    └── notes/
        ├── data/             # Datasources, DTOs, models, repository impl
        ├── domain/           # Entities, enums, repository interface
        └── presentation/     # Riverpod providers, screens, widgets
```

### Data flow

- **Repository** (`NotesRepositoryImpl`): Coordinates local and remote datasources; implements sync logic.
- **Local datasource** (`NotesLocalDatasource`): Hive key-value store for notes (offline storage).
- **Remote datasource** (`NotesRemoteDatasource`): REST API client for the notes server.
- **Providers**: Riverpod exposes repository data to the UI (list, detail, search, filter).

---

## Offline and Sync Strategy

### Offline-first model

1. **Local**: All reads and writes go through the repository, which uses Hive as the source of truth.
2. **Sync**: When a remote datasource is available, sync happens during user actions (get list, create, update, delete).
3. **Graceful degradation**: Network failures are caught and logged; the app continues using local data.

### Sync triggers

| Action        | Direction      | When it happens                         |
|---------------|----------------|-----------------------------------------|
| Open list     | Local → Remote | Push pending notes to server first      |
| Fetch list    | Remote → Local | On open or pull-to-refresh (after push) |
| Create note   | Local → Remote | Immediately after local save            |
| Update note   | Local → Remote | Immediately after local save            |
| Delete note   | Local → Remote | Immediately after local delete          |

**On launch / refresh:** When the notes list is loaded, pending (orange) notes are pushed to the server first, then the list is fetched from the server and merged locally. This ensures offline changes sync as soon as the app goes online.

### Sync status

Each note has a `SyncStatus`:

- **Synced** (green): Local and remote are aligned.
- **Pending** (orange): Changes exist only locally; will sync when possible.
- **Failed**: Reserved for future retry/error handling.

### Flow summary

- **getNotes**: Fetch from remote → merge into Hive → remove orphaned pending duplicates → return local list.
- **createNote**: Save locally with client UUID (pending) → POST to server → on success, store server response and remove local client-UUID copy.
- **updateNote**: Update locally (pending) → PATCH to server → on success, overwrite local with server response.
- **deleteNote**: Delete locally → DELETE on server (best-effort).

---

## Conflict-Handling Approach

### Current strategy: last-write-wins (LWW)

- **Remote over local**: On `getNotes`, remote data overwrites local by ID. Server is treated as the authority when syncing down.
- **Local over remote (on write)**: Create/update sends local state to the server. If the server accepts it, the server response overwrites the local copy.
- **No merge UI**: There is no conflict-resolution UI. Conflicting edits from another device will overwrite the local version on the next fetch.

### Duplicate prevention

- **Create flow**: After a successful sync, the original local note (client-generated UUID) is deleted so it does not appear as a duplicate of the server version (server-generated UUID).
- **Orphan cleanup**: On `getNotes`, pending local notes that match remote notes by title, body, and tags are removed to avoid duplicates.

### Limitations

- **Single device assumed**: Optimistic local edits are not reconciled with concurrent edits on other devices.
- **No merge on conflict**: Last write wins; no three-way merge.
- **Delete on failure**: Failed remote deletes are not retried; the note stays on the server.

---

## Key Trade-offs and Next Steps

### Trade-offs

| Trade-off            | Choice             | Rationale                                 |
|----------------------|--------------------|-------------------------------------------|
| Sync timing          | On user action     | Simpler; no background jobs               |
| Conflict resolution  | Last-write-wins    | Simpler; suitable for single-user notes   |
| Create ID handling   | Server assigns ID  | Server owns IDs; client deletes its copy  |
| Network failures     | Silent, continue   | App stays usable offline                  |

### Possible next steps

1. **Background sync**: Periodically push pending changes and fetch updates when the app is in foreground/background.
2. **Retry queue**: Queue failed create/update/delete operations and retry when connectivity returns.
3. **Conflict resolution**: Introduce `updatedAt`/version fields and a merge strategy or conflict UI when remote changes conflict with local edits.
4. **Multi-device support**: Tie notes to a user account and sync across devices.
5. **Connectivity awareness**: Use `connectivity_plus` to detect online/offline and adapt UI or sync behavior.
6. **Sync indicators**: Show sync status (e.g. “Syncing…”, “Last synced …”) and surface failed syncs.

---

## API Reference (Local Server)

- `GET /v1/notes` — List all notes  
- `GET /v1/notes/:id` — Get a note by ID  
- `POST /v1/notes` — Create a note (body: `title`, `body`, `tags`)  
- `PATCH /v1/notes/:id` — Update a note  
- `DELETE /v1/notes/:id` — Delete a note  

See `local_server/README.md` for examples.
