# Architecture

WidgetBoard is a real-time social Flutter app where two people (or a small
group) can communicate via home-screen widgets, chat, media sharing, and
mini-games. Communication happens through a single server-side WebSocket
(Socket.IO) signaling process.

## High-level data flow

```
+-------------+  WS (Socket.IO)  +-------------------+  WS (Socket.IO)  +-------------+
|   Phone A   |  ------------->  |  Signal Server    |  ------------->  |   Phone B   |
|  Flutter    |  register,      |  (Node.js)        |  register,      |  Flutter    |
|  client     |  search,        |  - join/leave     |  search,        |  client     |
|            |  add_friend,    |    rooms          |  add_friend,    |            |
|            |  create_room,   |  - relay events   |  create_room,   |            |
|            |  game_action,   |  - bridge          |  game_action,   |            |
|            |  message,      |                    |  message,      |            |
+-------------+  widget_write  +-------------------+  widget_write    +-------------+
                               |
                               | SharedPrefs (widget notes)
                               v
                         +-------------------+
                         |   AppWidget       |
                         |   (Android only)  |
                         +-------------------+
```

## Layers

### 1. Presentation (`lib/features/**`)
- **`server_config/`** — entry point; collects server URL + username
- **`friends/`** — user search, friend-management, lobby → game room picker
- **`chat/`** — 1:1 chat list + thread, image picker, voice record/playback
- **`games/`** — seven mini-games (see `GAMES.md`)
- **`media/`** — image grid
- **`widget_add/`** — note composer → home-screen AppWidget

### 2. Core (`lib/core/**`)
- **`services/websocket_service.dart`** — Socket.IO client wrapper
- **`services/score_service.dart`** — local leaderboard (SharedPreferences)

### 3. Native bridge (`android/...`)
- **`WidgetBoardProvider.kt`** — reads notes from `SharedPreferences`
  and renders them on the Android home-screen widget.
- When a note arrives via WebSocket, the Flutter side writes to
  `SharedPreferences` → the native provider picks it up via
  `AppWidgetManager.updateAppWidget()`.

## Package structure

```
lib/
 ├── app.dart                  # MaterialApp entry
 ├── main.dart                 # Provider setup
 ├── features/
 │   ├── server_config/server_config_page.dart
 │   ├── friends/friends_page.dart
 │   ├── chat/
 │   │   ├── chat_page.dart
 │   │   └── voice_message.dart
 │   ├── games/                # ttc, racing, ludo, cards, truth_dare, builder, angry_birds
 │   ├── media/media_page.dart
 │   └── widget_add/add_widget_page.dart
 ├── core/
 │   ├── theme.dart
 │   └── services/
 │       ├── websocket_service.dart
 │       └── score_service.dart
 ├── platform/                 # placeholder for platform channels
 └── widgets/                  # shared reusable pieces
android/
 └── .../kotlin/.../WidgetBoardProvider.kt  # AppWidgetProvider
```

## State management

- **`provider`** at the root wraps both `WebSocketService` and
  `ScoreService` in `MultiProvider`.
- Games read `WebSocketService` via `context.read<WebSocketService>()`
  and submit scores via `context.read<ScoreService>()`.

## Networking

- All real-time traffic goes over **Socket.IO** (`socket_io_client`).
- Server events are namespaced by room: `join_room`, `leave_room`,
  `message`, `game_action`, `widget_write`.
- Friend/lobby events: `register`, `search_users`, `add_friend`,
  `accept_friend`, `create_room`.

## Persistence

| Concern           | Storage                  | Read by              |
|-------------------|--------------------------|----------------------|
| Server URL        | `SharedPreferences` key `server_url` | `ServerConfigPage`        |
| Username          | `SharedPreferences` key `username` | `ServerConfigPage` |
| High scores       | `SharedPreferences` key `scores_v1` | `ScoreService`     |
| Widget notes (sent) | `SharedPreferences` key `widget_notes_sent` | `AddWidgetPage` |
| Widget notes (received) | `SharedPreferences` key `widget_notes_json` | `WebSocketService`, `WidgetBoardProvider.kt` |
| Last widget timestamp | `SharedPreferences` key `last_note_ts` | `WidgetBoardProvider.kt` |
| Incoming messages | (in-memory list, not yet persisted) | `ChatsPage`          |

## Multi-User Widget Sharing

The home-screen widget is a **shared canvas** — every friend who sends you a note
appears on your widget alongside their own line, and vice versa.

### Data flow for shared notes

```
Friend A sends "miss u" → Socket.IO → Friend B's app receives widget_write event
                                    ↓
                            WebSocketService._onWidgetWrite()
                                    ↓
                            Appends NoteEntry to SharedPreferences
                            key "widget_notes_json" (JSON array)
                                    ↓
                            Android AppWidget onUpdate/onReceive reads
                            "widget_notes_json" → renders up to 5 lines
```

### Android widget rendering

`WidgetBoardProvider.kt` reads the JSON array from SharedPreferences and renders
up to 5 `RemoteViews` text rows (`noteRow0`–`noteRow4`). Each row shows:

```
<sender> — <body truncated at 40 chars>
```

A compact footer shows the last-update timestamp. Tapping the widget opens the
app via a `PendingIntent`.

### NoteEntry model

Located in `lib/core/models/note_entry.dart`. Fields: `sender`, `body`, `timestamp`.
Provides `formatForWidget()` for the compact display line and JSON serialize/deserialize
helpers for persistence.
