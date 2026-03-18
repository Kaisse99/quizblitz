# ⚡ QuizBlitz

![Swift](https://img.shields.io/badge/Swift-6.2-orange?logo=swift)
![Node.js](https://img.shields.io/badge/Node.js-22.12-green?logo=node.js)
![Express](https://img.shields.io/badge/Express-5.2-lightgrey?logo=express)
![Socket.IO](https://img.shields.io/badge/Socket.IO-4.8-black?logo=socket.io)
![Socket.IO Swift](https://img.shields.io/badge/Socket.IO--Swift-16.1.1-black?logo=socket.io)
![MongoDB](https://img.shields.io/badge/Mongoose-9.3-brightgreen?logo=mongodb)
![Platform](https://img.shields.io/badge/iOS-26.2+-blue?logo=apple)

A real-time multiplayer quiz game built with Swift/SwiftUI (iOS) and Node.js, 
communicating over WebSockets via Socket.IO, with MongoDB for data persistence.

---

## Why I built this

This was a learning experiment to understand WebSocket communication from scratch. 
A multiplayer quiz game is a natural fit for the protocol — it requires pushing 
simultaneous state changes to all connected clients, broadcasting questions instantly, 
delivering per-player answer results, and keeping a live player count in sync across 
multiple devices in real time.

---

## System Architecture
```
iOS Client (Swift / SwiftUI / MVVM)
            |
            |  WebSocket via Socket.IO
            |
Node.js Server (Express + Socket.IO)
            |
            |  Mongoose ODM
            |
MongoDB Atlas
```

---

## Demo

### Joining the game
![Join Demo](demo/demoJoin.gif)

### Gameplay — full game from lobby to leaderboard
![Gameplay Demo](demo/demoGameplay.gif)

### Edge cases — duplicate username and joining an active session
![Edge Cases Demo](demo/demoEdgeCases.gif)

### Connection loss handling — server crash mid-game
![Server Crash Demo](demo/demoServercrash.gif)

### Load test — 9 simulated concurrent players via Node.js script
![Load Test Console](demo/demoTest9Console.gif)

---

## Features

- Real-time multiplayer up to 8 players per session
- Live lobby with countdown timer and player list showing X / 8
- Socket.IO rooms — events from one game never bleed into another
- 10 second countdown timer per question with centisecond precision
- Answer revealed instantly on submission without waiting for timer
- Game advances early when all players have answered
- Live answered counter visible to all players during a question
- Tie detection with shared rank display on leaderboard
- Persistent player stats across sessions stored in MongoDB
- Watchdog timer detects server disconnect mid-game and shows recovery dialog
- Duplicate username prevention per session
- 9th player rejected with a clear error when lobby is full
- Load tested with 9 simulated concurrent Socket.IO clients

---

## Known Limitations

- One active game session globally at a time
- No authentication — username is taken at face value
- No rejoin mechanic if a player disconnects mid-game
- Questions must be seeded manually via `seed.js` or added directly in MongoDB Atlas

These are intentional scope decisions. The focus was learning WebSocket communication 
patterns, not building a production product.

---

## Running It Yourself

### Prerequisites

- Node.js 18+
- Xcode 15+
- Free MongoDB Atlas account — [create one here](https://www.mongodb.com/cloud/atlas/register)
- Socket.IO Swift package via Xcode SPM: `https://github.com/socketio/socket.io-client-swift`

---

### 1. Set up MongoDB Atlas

1. Create a free account at [cloud.mongodb.com](https://cloud.mongodb.com)
2. Create a free tier cluster (M0 — no credit card required)
3. **Database Access** → add a user with a username and password
4. **Network Access** → Add IP Address → Allow Access From Anywhere `0.0.0.0/0`
5. **Connect** → **Drivers** → copy the connection string

Connection string format:
```
mongodb+srv://USERNAME:PASSWORD@cluster.mongodb.net/quizDB
```

---

### 2. Run the server
```bash
cd live-quiz-game
npm install
cp .env.example .env
```

Open `.env` and paste your connection string:
```
MONGODB_URI=mongodb+srv://USERNAME:PASSWORD@cluster.mongodb.net/quizDB
PORT=3000
```

Seed the database with sample questions:
```bash
node seed.js
```

Start the server:
```bash
node server.js
```

Expected output:
```
MongoDB Connected
Server running on http://localhost:3000
```

---

### 3. Run the iOS client

1. Open `QuizAppClient/QuizAppClient.xcodeproj` in Xcode
2. Open `Utilities/Constants.swift`
3. Set the server URL:
```swift
// Simulator
static let serverURL = "http://localhost:3000"

// Physical device — find your IP in System Settings → Wi-Fi → Details
static let serverURL = "http://YOUR_LOCAL_IP:3000"
```

4. Run on Simulator or a physical device on the same Wi-Fi network

---

### 4. Test multiplayer

Open a second Simulator via **Xcode → Open Developer Tool → Simulator** and run 
the app on both simultaneously.

To run the automated load test with 9 simulated players:
```bash
node live-quiz-game/test/loadTest.js
```

Player 9 will be rejected. Players 1-8 will complete a full game and print 
results to the console.

---

## Author

**Mykyta** — iOS & Full-Stack Developer  
[GitHub](https://github.com/Kaisse99)
