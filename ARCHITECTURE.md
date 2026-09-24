# Architecture

WidgetBoard is a real-time social Flutter app where two people (or a small
group) can communicate via home-screen widgets, chat, media sharing, and
mini-games. Communication happens through a single server-side WebSocket
(Socket.IO) signaling process.

## High-level data flow

```
+----------+              +-------------------+              +----------+
|  Phone A |  WS (Socket.IO)  |                |  WS  |  Phone B |
|          |  --------       |  Signal Server   |     -------- |          |
|  Flutter |  register,      |  (Node.js)       |  |  register,
|  client  |  search,        |                  |  |  search,
|          |  add_friend,    |  - join/leave    |  |  add_friend,
|          |  create_room,   |    rooms         |  |  create_room,
|          |  game_action,   |  - relay events   |  |  game_action,
|          |  message        |  - bridge         |  |  message
+----------+  widget_write    |    widget_write   |  widget_write +----------+
                              +-------------------+
                                    |
                                    | SharedPrefs (widget notes)
                                    v
                            +-----------------+
                            | AppWidget       |
                            | (Android only)  |
                            +-----------------+
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
| Last widget note  | `SharedPreferences` key `last_note` | `WidgetBoardProvider.kt` |
| Incoming messages | (in-memory list, not yet persisted) | `ChatsPage`          |
