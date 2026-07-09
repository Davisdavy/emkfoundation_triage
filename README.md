# Paramedic Triage Intake App

An offline-first emergency medical triage application built with Flutter that allows paramedics to quickly capture patient information in the field. The application guarantees no triage record is lost by utilizing local persistence and synchronizing automatically when connectivity is restored.

---

## Architecture

The project features a strict separation of concerns, divided into features and services:

```text
UI
↓
Provider
↓
Repository
↓
Local Repository (Hive)
↓
Remote Repository (Mock API)

Connectivity Service
↓
Sync Service
↓
Repository
```

### Key Components

1. **Provider State Management**: Manages state transitions, loading indicators, and form validation states safely away from widgets.
2. **Repository Pattern**: Co-ordinates offline-first reads and writes through `TriageRepository`, acting as the single source of truth for the UI.
3. **Hive Local Database**: High-performance local storage used to save patient records immediately and persistently.
4. **Sync Service**: Runs in the background and processes the queue of unsynced records one by one once connectivity returns.
5. **Connectivity Monitoring**: Powered by `connectivity_plus` to monitor network connectivity shifts dynamically.

---

## Offline Sync Flow

```text
Submit
↓
Offline?
↓
Yes
↓
Save Locally (isSynced = false)
↓
Wait For Connectivity
↓
Auto Sync
↓
Mark Synced (isSynced = true)
```

---

## Setup Instructions

Ensure you have Flutter installed on your machine.

1. **Get Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the App**:
   ```bash
   flutter run
   ```

---

## Testing

Run unit tests and UI tests with:
```bash
flutter test
```
