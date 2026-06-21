# Bit The Player ⚽🔨

Bit The Player is a **local-network, real-time multiplayer footballer auction game** built using Flutter. It is designed to run with **no PC server required**—one Android/Linux device acts as the server and native host, while other players (including iOS/Safari or secondary Android devices) connect seamlessly via their mobile web browsers.

---

## 🌟 Key Features & Gameplay Mechanics

### 1. Persistent Footballer database (`game_db.dart`)
- Persistent JSON-based database storing player ratings and bidding history.
- Footballer **Real Value** calculation logic:
  1. **Admin Override**: Uses a manually set `customValue` if specified by the host.
  2. **Bidding History**: Uses the average of all recorded past winning bids on that footballer.
  3. **Base Rating**: Falls back to the default rating `baseValue` if no history or override exists.
- The **Real Value** determines the winner of the game (the player whose won footballers have the highest cumulative Real Value wins).
- Real values are kept hidden from players during bidding to maintain tactical suspense and are only revealed on the final scoreboard.

### 2. Playing Position Alternation
- Supports five distinct positions: **Striker**, **Winger**, **Center Mid**, **Center Back**, and **Full Back** (no Goalkeepers).
- **Alternation Constraint**: The server alternates the position of the footballer up for auction each round, ensuring players build balanced squads and preventing back-to-back rounds of the same position.

### 3. Sniping Protection (Overtime Extensions)
- Rounds have a standard duration (e.g. 15 seconds).
- If a player places a bid when the remaining time is **5 seconds or less**, the timer automatically extends by **3 seconds**.
- Overtime extensions do not stack recursively if the time is already pushed back above 5 seconds.

### 4. Admin Database Manager Screen
- Native host can access the Database Manager via a storage icon in the top-right corner of the role selection screen.
- Allows the host to:
  - Add new footballers with custom positions and base values.
  - Set custom overrides (Real Value) or clear them back to dynamic averages.
  - Inspect history averages and bid lists.

---

## 🔌 Architecture & Network Communication

The application combines a Flutter client with a lightweight Dart HTTP/WebSocket server.

```
                  ┌──────────────────────────────┐
                  │      Android/Linux Host      │
                  │  (Acts as Server & Player)   │
                  └──────────────┬───────────────┘
                                 │ (Local WebSockets)
             ┌───────────────────┴───────────────────┐
             ▼                                       ▼
    ┌─────────────────┐                     ┌─────────────────┐
    │  Android Client │                     │   Web Clients   │
    │ (Native App)    │                     │ (Safari/Chrome) │
    └─────────────────┘                     └─────────────────┘
```

### 1. Server Components (`game_server.dart`)
- **HTTP Server**: Serves a single-page reactive web app (HTML5/CSS3/Vanilla JS) at `http://<IP>:4000` for browser clients.
- **WebSocket Server**: Handles incoming bids, lobby entries, game configurations, and broadcasts state updates to all clients in real-time.
- **UDP Broadcast socket**: Listens on port `8888` and responds to discovery packets, letting secondary native clients auto-discover the host on the local WiFi network.

### 2. Auto-Discovery (`discovery_native.dart`)
- Secondary native apps listen and broadcast on the local subnet to automatically discover and list lobbies without requiring manual IP entry.
- Web browser clients can connect manually using the host IP address displayed on the server app's main screen.

---

## 🛠️ Getting Started & Deployment

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable)
- Devices connected to the same local WiFi network (WLAN)

### Running Locally
To run the server and client app in debug mode on a connected Android phone or desktop:
```bash
flutter run
```

### Building the Android APK
To compile a standalone debug APK for sideloading onto mobile devices:
```bash
flutter build apk --debug
```
The output file will be saved at:  
`build/app/outputs/flutter-apk/app-debug.apk`

---

## 🎮 How to Play

1. **Host a Game**:
   - Open the app on the host device.
   - Enter your nickname and click **HOST A NEW GAME**.
   - Your local IP address (e.g. `192.168.1.105`) will be displayed under the button.
2. **Join from Browsers (iOS / Safari / Chrome)**:
   - On iOS or other devices, open Safari/Chrome.
   - Navigate to `http://<host-ip>:4000` (e.g. `http://192.168.1.105:4000`).
   - Enter a nickname and join the lobby.
3. **Join from Native Apps**:
   - Open the app on secondary phones.
   - The app will automatically scan the local network and display the host's lobby. Click **JOIN**.
4. **Draft Phase**:
   - The host selects the match rules (duration, budget, round count) and starts the game.
   - Bid on footballers of alternating positions using quick increments (`+5M`, `+10M`, etc.) or custom entries.
5. **Scoreboard & Game Over**:
   - Once all rounds finish, the game reveals the footballers' real database values. Standings are ranked by total team value.
