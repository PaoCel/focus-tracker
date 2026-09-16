# Focus Tracker

App iOS (SwiftUI, iOS 17+) per tracciare il tempo di **Focus / Break / Off Track**
durante una sessione di tutoring, con Live Activity interattiva su Lock Screen e
Dynamic Island. Nessun backend, nessun entitlement: due file JSON in Documents.

## Struttura
- `FocusTracker/` app (start, sessione attiva, riepilogo, storico)
- `Shared/` modelli, store, Live Activity manager, App Intents (compilato in entrambi i target)
- `FocusTrackerWidget/` estensione con la Live Activity
- `project.yml` progetto XcodeGen: dopo ogni modifica `xcodegen generate`

Bundle: `com.paolocelestini.focustracker` (widget `.widget`), team `787YK9YUB3`.
Focus % = Focus ÷ (Focus + Off Track); le pause non contano.

## Release su TestFlight
1. Bump `MARKETING_VERSION` e `CURRENT_PROJECT_VERSION` in `project.yml`, commit.
2. `scripts/release.sh`: archive Release, upload, attesa esito su ASC, gruppo interno.

Prerequisito una tantum: il record app su App Store Connect (`scripts/asc.py app`
dice se manca). Chiave API in `~/.appstoreconnect/` (fuori dal repo).

## Sviluppo
Simulatore: `xcodebuild -project FocusTracker.xcodeproj -scheme FocusTracker -destination 'platform=iOS Simulator,name=iPhone 17' build`.
I pulsanti della Live Activity richiedono iOS 17 (LiveActivityIntent eseguito nel processo dell'app).
