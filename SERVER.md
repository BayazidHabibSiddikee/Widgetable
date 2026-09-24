# Signaling Server (Socket.IO)

WidgetBoard requires a single Socket.IO server per deployment. The server
relays real-time events between paired clients — friend management, lobby
room creation, chat messages, game actions, and widget-note delivery.

## Stack

| Layer        | Tech                                   |
|--------------|----------------------------------------|
| Runtime      | Node.js (>= 18)                        |
| Library      | [`socket.io`](https://socket.io/) 4.x   |
| Optional     | `cors` for browser-origin headers      |

## Install & run (local)

```bash
npm init -y
npm install socket.io cors

node server.js
```

Then point your app at `http://<your-local-ip>:3000`.

## Minimal reference server

`server.js`:

```js
const http = require('http');
const cors = require('cors');
const { Server } = require('socket.io');

const server = http.createServer(cors());
const io = new Server(server, {
  cors: { origin: '*' },
});

// username  -> socket.id
const users = new Map();
// roomId     -> Set<socket.id>
const rooms = new Map();

io.on('connection', (socket) => {
  console.log('Connected:', socket.id);

  socket.on('register', ({ username }) => {
    users.set(username, socket.id);
    socket.username = username;
    // Echo the registered username back to confirm it is available.
    socket.emit('registered', { username });
  });

  socket.on('search_users', ({ query }) => {
    const matches = [...users.keys()].filter(
      (u) => u.toLowerCase().includes(query.toLowerCase()) && u !== socket.username
    );
    socket.emit('search_results', matches);
  });

  socket.on('add_friend', ({ to_username }) => {
    const targetId = users.get(to_username);
    if (targetId) {
      io.to(targetId).emit('friend_request', { from: socket.username });
    }
  });

  socket.on('accept_friend', ({ from }) => {
    const targetId = users.get(from);
    if (targetId) {
      io.to(targetId).emit('friend_accepted', { from: socket.username });
      // Optimistically treat them as "friends" by allowing room creation.
    }
  });

  socket.on('create_room', ({ game, friend }) => {
    const roomId = `${socket.username}__${friend}__${game}`;
    if (!rooms.has(roomId)) {
      rooms.set(roomId, new Set());
    }
    const room = rooms.get(roomId);
    room.add(socket.id);
    socket.join(roomId);
    const friendSocket = users.get(friend);
    if (friendSocket) {
      io.to(friendSocket).emit('room_created', { room: roomId, game, friend: socket.username });
    } else {
      // If the friend is offline, the creator simply joins the room alone
      // and the friend picks it up when they come online.
      io.to(socket.id).emit('room_created', { room: roomId, game, friend: socket.username });
    }
  });

  socket.on('join_room', ({ room, username }) => {
    socket.join(room);
    socket.to(room).emit('user_joined', { username });
  });

  socket.on('leave_room', ({ room }) => {
    socket.leave(room);
  });

  socket.on('message', (payload) => {
    const room = payload.room;
    socket.to(room).emit('incoming_message', payload);
  });

  socket.on('game_action', ({ room, ...payload }) => {
    socket.to(room).emit('game_action', payload);
  });

  socket.on('widget_write', ({ to, body }) => {
    const targetId = users.get(to);
    if (targetId) {
      io.to(targetId).emit('widget_write', { from: socket.username, body });
    }
  });

  socket.on('disconnect', () => {
    users.delete(socket.username);
    console.log('Disconnected:', socket.id);
  });
});

server.listen(3000, '0.0.0.0', () => {
  console.log('WidgetBoard signaling server on :3000');
});
```

## Socket.IO event contract

### Client → Server

| Event             | Payload                                  | Purpose                          |
|-------------------|------------------------------------------|----------------------------------|
| `register`        | `{ username }`                           | Declare your username on connect |
| `search_users`    | `{ query }`                              | Find other users by partial name |
| `add_friend`      | `{ to_username }`                        | Send a friend request            |
| `accept_friend`   | `{ from }`                               | Accept a friend request          |
| `create_room`     | `{ game, friend }`                       | Create a game room               |
| `join_room`       | `{ room, username }`                     | Join an existing room            |
| `leave_room`      | `{ room }`                               | Leave a room                     |
| `message`         | `{ room, text, media_url? }` (JSON-stringified) | Send a chat message      |
| `game_action`     | `{ room, ... }`                          | Send a game-specific action      |
| `widget_write`    | `{ to, body }`                           | Send a home-widget note          |

### Server → Client

| Event             | Payload (array\|object)                | Purpose                           |
|-------------------|------------------------------------------|-----------------------------------|
| `registered`      | `{ username }`                           | Confirmation of registration      |
| `search_results`  | `string[]`                               | List of matched usernames         |
| `friend_request`  | `{ from }`                               | Incoming friend request           |
| `friend_accepted` | `{ from }`                               | A friend request was accepted     |
| `room_created`    | `{ room, game, friend }`                 | Your room was created             |
| `user_joined`     | `{ username }`                           | Someone joined your room          |
| `incoming_message`| `{ room, text, media_url?, sender? }`    | A new chat message                |
| `game_action`     | `{ ... }`                                | A game-specific event             |
| `widget_write`    | `{ from, body }`                         | A new home-widget note            |

## Notes

- Usernames must be **unique per server instance**.
- Rooms auto-close when the last participant leaves (optional cleanup).
- The server holds no database — state is ephemeral. For persistence
  (user accounts, message history), integrate Redis or MongoDB in front
  of the Socket.IO handlers.
