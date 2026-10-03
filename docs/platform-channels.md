# Platform channel protocol

Contract between the Dart app (`lib/features/*/infrastructure/platform_*.dart`)
and the Kotlin host (`android/app/src/main/kotlin/it/marcelpetrick/raumfreund/`).
Both sides are tested against this document. Changing it requires changing
both sides in the same commit.

## Method channel `it.marcelpetrick.raumfreund/control`

All methods run on the Android main thread and answer exactly once.

| Method | Arguments | Success result | Errors (`code`) |
| --- | --- | --- | --- |
| `permissionStatus` | – | `"granted"` \| `"denied"` \| `"permanentlyDenied"` | – |
| `requestPermission` | – | same as above | `busy` (a request is already running) |
| `openAppSettings` | – | `null` | `unavailable` |
| `startLevels` | `{"sessionId": int}` | `null` once `AudioRecord` is recording | `permissionMissing`, `microphoneBusy`, `unavailable` |
| `stopLevels` | – | `null` (idempotent) | – |
| `playAlarm` | `{"sound": bool, "vibrate": bool}` | `null` **after** the tone/vibration has ended | `unavailable` |
| `setKeepScreenOn` | `{"enabled": bool}` | `null` | – |
| `appInfo` | – | `{"versionName": String, "versionCode": int}` | – |

Notes:

- `permanentlyDenied` is reported when the permission was requested before,
  is not granted and `shouldShowRequestPermissionRationale` is false. Before
  the first request the status is `denied`.
- `requestPermission` must not start recording; the Dart controller starts
  recording only after a grant **and** while the app is in the foreground.
  The activity's pause caused by the permission dialog is not a background
  change and must not cancel the request.
- `startLevels` with a new `sessionId` stops a running session first.
- `playAlarm` without a vibrator (or with `vibrate: false`) only plays the
  tone; with `sound: false` and no vibrator it completes immediately.

## Event channel `it.marcelpetrick.raumfreund/levels`

Each event is a map:

| Event | Payload |
| --- | --- |
| Reading | `{"sessionId": int, "dbfs": double}` – RMS of one ~100 ms window, `<= 0` |
| Failure | `{"sessionId": int, "error": "microphoneBusy" \| "recordingAborted" \| "unavailable"}` – the native session has ended |

The native side stops recording on its own when the activity is stopped
(real background) or destroyed, and then emits `recordingAborted` for the
running session. Events of an old session may still arrive after a new one has
started; the Dart side discards them by `sessionId`.
