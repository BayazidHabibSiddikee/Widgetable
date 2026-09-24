# Games

WidgetBoard ships with **seven** mini-games. Each is playable in
single-player mode (against a simple AI or local logic) and has hooks for
real-time multiplayer via `WebSocketService.gameAction`.

All games report scores to the global `ScoreService` leaderboard, which is
surfaced via the 🏆 FAB on the Games tab.

---

## 1. Tic-Tac-Toe (`ttc_game.dart`)

### Rules
- 3×3 grid, players X and O alternate turns.
- Get 3 in a row (horizontally, vertically, or diagonally) to win.
- Stalemate → draw.

### Multiplayer protocol
```dart
// client joins
ws.gameAction('ttc-room', { 'action': 'join' });
ws.gameAction('ttc-room', { 'action': 'move', 'index': 4, 'player': 'x' });
```

### Score
- Winner gets **10 pts** per win.
- Tie increments neither score.
- Game auto-resets on win or tie.

---

## 2. Racing (`racing_game.dart`)

### Rules
- Side-scrolling car; drag left/right or use arrow FABs to dodge obstacles.
- Speed increases every 5 seconds.
- Hit an obstacle → game over.

### Multiplayer protocol
```dart
ws.gameAction('racing-room', { 'action': 'move', 'x': -1.0..1.0 });
```

### Score
- **+1 pt** per frame survived.
- Score displayed live in the AppBar.

---

## 3. Ludo (`ludo_game.dart`)

### Rules
- Simplified 4-corner board — roll dice to move tokens.
- Roll a **6** to unlock a token.
- Land on an opponent's space to send them back (not implemented in stub).

### Multiplayer protocol
```dart
ws.gameAction('ludo-room', { 'action': 'roll', 'token_id': 0 });
```

### Score
- Each dice roll = **1 pt**.
- Round counter shown in the AppBar.

---

## 4. Cards (`cards_game.dart`)

### Rules
- "Higher or Lower": guess whether the next card beats the current.
- Streak multiplier: 3+ correct → 2x points, 5+ → 3x.

### Multiplayer protocol
```dart
ws.gameAction('cards-room', { 'action': 'guess', 'higher': true });
```

### Score
- Correct: +10 × streak multiplier.
- Tie: no change, streak reset.
- Wrong: streak reset to 0.

---

## 5. Truth or Dare (`truth_dare.dart`)

### Rules
- Spin the wheel; get a truth prompt or a dare.

### Multiplayer protocol
```dart
ws.gameAction('truth-room', { 'action': 'spin' });
// server may emit: { 'action': 'picked_truth', 'prompt': "..." }
```

### Score
- Each spin completed = **5 pts**.
- Streak grows with consecutive prompts.

---

## 6. Builder (`builder_game.dart`)

### Rules
- 8×12 grid, place 2×2 colored blocks.
- Blocks settle via simplified gravity (unsupported = collapse).
- Goal: build the tallest stable tower.

### Multiplayer protocol
```dart
ws.gameAction('builder-room', { 'action': 'place', 'col': 3, 'color': <int> });
```

### Score
- **+1 pt** per block successfully placed + supported.
- Color cycles per score count.

---

## 7. Angry Birds 2-Player (`angry_birds.dart`)

### Rules
- **Player A (Builder)**: places a wall of 6×8 bricks.
- **Player B (Attacker)**: taps bricks to destroy them.
- Goal: the attacker tries to make the wall collapse.

### Multiplayer protocol
```dart
// Attacker destroys a brick
ws.gameAction('angry-room', { 'action': 'destroy', 'idx': 23 });
```

### Score
- Attacker: **+1 pt** per brick destroyed.
- Builder is notified live so the bricks disappear in sync.

---

## Leaderboard

Scores are stored via `ScoreService` (SharedPreferences) and shown in the
bottom-sheet leaderboard accessible from the 🏆 FAB on the Games tab.

Format key: `"<Game>:<username>"` → `"<points>"`.

---

## Adding a new game

1. Create a file under `lib/features/games/<new_game>/`.
2. Implement `StatefulWidget` and accept a `WebSocketService` reference.
3. Import `ScoreService` and call `submitScore("<Game>", username, pts)`.
4. Add an entry to the `_games` list in `games_home.dart`.
