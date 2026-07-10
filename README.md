# Medic Triage – Paramedic Intake Application

> **Assessment Submission** — An offline-first, resilient paramedic triage intake application built with **Flutter (Dart)**. Zero data loss is guaranteed even when cellular connectivity is completely absent.

---

## 📱 Application Overview

Medic Triage enables field paramedics to log critical patient data instantly. Records are persisted locally the moment the form is submitted, then automatically synchronized to a remote server the instant connectivity is restored — without any manual intervention from the user.

---

## 🏗️ Architectural Choices

The codebase follows a **feature-first, clean-architecture** structure with strict layer boundaries:

```text
lib/
├── core/
│   ├── constants/       # Global design tokens (AppTheme)
│   └── services/        # Infrastructure singletons
│       ├── connectivity_service.dart  # Wraps connectivity_plus
│       └── sync_service.dart          # Background queue processor
└── features/
    ├── authentication/
    │   └── screens/
    │       └── splash_screen.dart     # Animated splash + real network status
    └── triage/
        ├── models/
        │   └── triage_record.dart     # Domain model + Hive TypeAdapter
        ├── providers/
        │   └── triage_provider.dart   # ChangeNotifier state management
        ├── repositories/
        │   ├── local_repository.dart  # Hive CRUD abstraction
        │   ├── remote_repository.dart # Simulated upload (2 s delay, 30% failure)
        │   └── triage_repository.dart # Offline-first orchestration
        └── screens + widgets/         # Pure UI layer
```

### Layer Responsibilities

| Layer | Responsibility |
|---|---|
| **UI** (Widgets) | Purely presentational. Reads from `Provider`, never touches storage directly. |
| **Provider** | Owns UI loading/error states. Coordinates `Repository` and `SyncService`. |
| **Repository** | Offline-first submission logic — decides whether to upload or save locally. |
| **LocalRepository** | Wraps `Hive` box with typed CRUD methods. |
| **RemoteRepository** | Simulates a REST upload with configurable delay and failure rate. |
| **ConnectivityService** | Emits a `Stream<bool>` from `connectivity_plus` events. |
| **SyncService** | Subscribes to `ConnectivityService` stream; auto-drains the unsynced queue. |

### Key Design Decisions

1. **Hive over SQLite** — Key-value access is O(1) and synchronous reads make the UI feel instant. Records are keyed by UUID so `put(id, record)` is naturally idempotent (duplicate submissions cannot corrupt the dataset).

2. **Provider for state management** — `ChangeNotifier` with `MultiProvider` at the app root gives clean dependency injection, easy mock substitution in tests, and zero boilerplate compared to BLoC for a single-screen app.

3. **Repository Pattern** — The UI only ever calls `TriageRepository`. It doesn't know whether data came from Hive or a remote server. This single seam makes the offline logic completely unit-testable with fake implementations.

4. **No `connectivity_plus` alone for "real internet"** — `connectivity_plus` detects connection *type* (WiFi, mobile) but not actual internet reachability (e.g., captive portals). The `RemoteRepository` therefore acts as the true reachability check — if `uploadTriage()` throws, the record is saved offline regardless of what the connection type reports.

---

## 🔄 Offline-First Sync Queue

The application stores data **locally first, always** — the remote upload is an optimistic best-effort attempt.

```
Paramedic submits form
        │
        ▼
Is device online? ──No──► Save locally (isSynced = false)
        │                        │
       Yes                       │
        │                        ▼
Try remote upload          Network restored / App resumed
        │                        │
   Success ──► Save locally      ├── ConnectivityService stream fires
              (isSynced = true)  └── SyncService.syncPendingRecords()
                                          │
   Failure ──► Save locally               ▼
              (isSynced = false)   Fetch all records where isSynced = false
                                          │
                                  Upload each sequentially (re-checks online
                                  before each record to handle mid-sync drops)
                                          │
                                  Mark each uploaded record isSynced = true
                                          │
                                  Notify TriageProvider → UI refreshes badges
```

### Sync Mechanics in Detail

| Mechanism | Implementation |
|---|---|
| **Local persistence** | `Hive.openBox<TriageRecord>('triage_records')` opened at startup. |
| **Sync flag** | `TriageRecord.isSynced` boolean. `false` = pending upload, `true` = confirmed uploaded. |
| **Auto-trigger on reconnect** | `SyncService.init()` subscribes to `ConnectivityService.isOnlineStream`. Any `true` emission triggers `syncPendingRecords()`. |
| **App lifecycle trigger** | `WidgetsBindingObserver.didChangeAppLifecycleState` calls `triggerSync()` when app is resumed from background. |
| **Re-entrancy guard** | `_isSyncing` boolean prevents overlapping sync runs. |
| **Per-record online re-check** | Before uploading each record, connectivity is re-verified so a mid-sync network drop is handled gracefully. |
| **Partial failure resilience** | If one record upload fails, the loop `continues` to attempt remaining records. |
| **UI notification** | `SyncService.onSyncCompleted(count)` callback triggers a floating SnackBar showing how many records were synced. |

---

## 📋 Form & Validation

| Field | Type | Validation |
|---|---|---|
| Patient Name | `String` | Required, cannot be blank |
| Condition Description | `String` | Required, cannot be blank |
| Priority Level | `int` 1–5 | Must be selected; **P1 & P2** are full-width hazard-styled buttons |
| Transport Status | `Enum` (Pending / In-Transit) | Always has a default value (`pending`) |

The **Submit** button is **disabled and visually greyed out** until all required fields are populated AND a priority is selected. Validation runs both at the button level (`_isFormReady` getter) and inside `_submitForm()` via `Form.validate()` to catch edge cases.

Priority colours follow the international triage colour scale:
- **P1 Critical** — Deep hazard red `#9E0B0B`
- **P2 High Risk** — Hazard orange `#FF6D00`
- **P3 Moderate** — Amber
- **P4 Stable** — Blue
- **P5 Low Risk** — Green

---

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK **≥ 3.x** (latest stable recommended)
- Android SDK (API 21+) / Xcode (iOS 12+) for device/emulator testing
- Git

### 1. Clone the Repository
```bash
git clone https://github.com/Davisdavy/emkfoundation_triage.git
cd emkfoundation_triage
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Regenerate Launcher Icons (optional)
```bash
dart run flutter_launcher_icons
```

### 4. Run the App
```bash
flutter run
```

### 5. Run Tests
```bash
flutter test
```

---

## 🧪 Test Coverage

The suite uses **lightweight fake implementations** (no reflection-based mocking) to keep tests deterministic and fast.

| # | Test | What it verifies |
|---|---|---|
| 1 | Offline submission | Record saved locally, `isSynced = false`, zero remote calls |
| 2 | Online submission (success) | Record uploaded, saved locally as `isSynced = true` |
| 3 | Online submission (remote failure) | Fallback to local, `isSynced = false`, one upload attempt |
| 4 | Sync queue — manual trigger | 2 pending records uploaded and marked synced; `onSyncCompleted` fires with count = 2 |
| 5 | Stream-triggered auto-sync | Setting connectivity to `true` in `FakeConnectivityService` automatically triggers sync without any explicit call |
| 6 | Duplicate record prevention | Submitting the same UUID twice results in exactly one local record (Hive `put` by key is idempotent) |
| 7 | TriageProvider loading state | `isLoading` transitions `false → true → false` around a submission; outcome and record count correct |
| 8 | Widget test — form renders | Submit button is initially disabled; priority selector and form fields are present |

Run all 8 tests:
```bash
flutter test --reporter compact
```

---

## 📦 Dependencies

| Package | Version | Purpose |
|---|---|---|
| `hive` / `hive_flutter` | `^2.2.3` | Local persistence |
| `provider` | `^6.1.2` | State management & DI |
| `connectivity_plus` | `^6.1.4` | Network status monitoring |
| `uuid` | `^4.5.1` | UUID generation for record IDs |
| `flutter_launcher_icons` | `^0.14.3` | Custom app icon generation |

---

## 🎥 Demo Video

Here is a screen recording demonstrating the full offline-first workflow and automatic background synchronization:

![Medic Triage Demo](assets/demo.mp4)


### Steps to reproduce the flow manually:

1. Launch the app and submit a record while **offline** (toggle airplane mode)
2. Observe the "Saved locally" snackbar and the **Pending** sync badge on the record card
3. Restore connectivity — within ~1 second the record badge automatically updates to **Synced** and a notification snackbar appears
4. The triage list refreshes without any user action


---

## 🔒 Permissions

```xml
<!-- Android — required for connectivity checks and simulated remote upload -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

---

## 📐 Architecture Diagram

```
┌──────────────────────────────────────────────────┐
│                      UI Layer                    │
│   SplashScreen ──► TriageScreen (Form + List)    │
│   PrioritySelector │ TriageCard │ StatusChip      │
└───────────────────────┬──────────────────────────┘
                        │ reads/writes via Provider
┌───────────────────────▼──────────────────────────┐
│               State Management                   │
│   TriageProvider (ChangeNotifier)                │
│   • isLoading / records / errorMessage           │
└──────┬────────────────────────────┬──────────────┘
       │ submitRecord()             │ syncPendingRecords()
┌──────▼──────────────┐    ┌───────▼────────────────┐
│  TriageRepository   │    │      SyncService        │
│  (offline-first)    │    │  • Listens to stream    │
└──────┬──────────────┘    │  • _isSyncing guard     │
       │                   └───────────────────────-─┘
  ┌────┴────┐
  │         │
┌─▼──────┐ ┌▼────────────────┐   ┌─────────────────────┐
│  Hive  │ │  RemoteRepo     │◄──│  ConnectivityService │
│  (local│ │  (simulated     │   │  (connectivity_plus) │
│  Hive  │ │   REST upload)  │   └─────────────────────┘
└────────┘ └─────────────────┘
```
