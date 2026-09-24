# WidgetBoard

A social Flutter 3 app where you can **write notes directly to friends' phone
home screen widgets**, chat with images & voice, and play mini-games together
in real-time.

> Inspired by [Widgetable](https://github.com/BayazidHabibSiddikee/Widgetable).

## Features

- **Server-based lobby**: Add friends by username, search, and create game rooms.
- **Home widget notes**: Send a quick "miss u 💛" or birthday message that
  appears directly on your friend's home screen — no need to open the app.
- **Chat**: Text messages, image sharing, **voice recording**.
- **Games**: 7 mini-games with leaderboards and real-time multiplayer.
- **Leaderboard**: Floating action button on the Games tab shows all-time highs.

## Setup

### 1. Install Flutter

```bash
# https://docs.flutter.dev/get-started/install
flutter --version   # >= 3.22
```

### 2. Get dependencies

```bash
cd ~/Documents/widgets_share      # or your project location
flutter pub get
```

### 3. Connect your server *(optional — see below)*

When the app starts you'll be prompted for:

- **Server URL** — the WebSocket host, e.g. `http://192.168.1.5:3000`
  - Default: `http://localhost:3000`
- **Username** — a unique display name (no spaces).

> If you don't have a server yet, you can still explore the games and the
> widget composer — the UI works fully offline.

### 4. Run

```bash
# Android device
flutter run -d <device-id>

# Linux desktop (for testing)
flutter run -d linux
```

## Project layout

```
lib/
 ├── app.dart                  # MaterialApp theme + entry
 ├── main.dart                 # MultiProvider (WS + Score)
 ├── features/                 # UI screens
 └── core/                     # services & theme
android/.../kotlin/WidgetBoardProvider.kt  # home-screen widget
test/widget_test.dart         # smoke test
```

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for the full design breakdown and
[`GAMES.md`](GAMES.md) for per-game rules and scoring logic.

## Games

| Game           | Icon | Description                          |
|----------------|------|--------------------------------------|
| Tic-Tac-Toe    | ⬛   | 3×3 grid, win detection, multiplayer |
| Racing         | 🚗   | SideScroller — avoid obstacles       |
| Ludo           | 🎲   | Board + dice roll animation         |
| Cards          | 🃏   | Higher-or-Lower with streak bonus    |
| Truth/Dare     | ❤️   | Spinner with truth/dare prompts      |
| Builder        | 🏗️   | Place 2×2 blocks, build high         |
| Angry Birds 2P | 🎯   | Build wall vs destroy bricks         |

## Adding the home widget

1. Long-press an empty area on your Android home screen.
2. Tap **Widgets**.
3. Scroll to **WidgetBoard** and tap the widget.
4. Place it anywhere — notes from friends will appear instantly.

> The app copies widget-setup instructions to your clipboard when you tap the
> ℹ️ help icon in the **Add Home Widget** tab.

## Dependencies

| Package            | Purpose                         |
|--------------------|---------------------------------|
| `provider`         | state management                |
| `socket_io_client` | real-time multiplayer signaling |
| `shared_preferences` | local leaderboard + widget notes |
| `image_picker`     | media sharing                  |
| `cached_network_image` | image grid + thumbnails    |
| `record` / `just_audio` | voice messages             |
| `intl`             | date/number formatting          |

## Running tests

```bash
flutter test
```

## License

MIT — see `LICENSE`.
