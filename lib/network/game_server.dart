import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:network_info_plus/network_info_plus.dart';
import 'game_db.dart';
import 'game_protocol.dart';
import 'web_client_source.dart';

class GameServer {
  HttpServer? _httpServer;
  RawDatagramSocket? _udpSocket;
  
  // Game Configuration
  int bidDurationSeconds = 15;
  int initialBudget = 100;
  int totalRounds = 5;
  
  // Game State
  String serverState = 'lobby'; // lobby, bidding, round_result, game_over
  List<Player> players = [];
  final Map<String, WebSocket> _playerSockets = {};
  
  int currentRound = 0;
  String currentFootballer = '';
  int highestBid = 0;
  String highestBidderId = '';
  String highestBidderName = '';
  Timer? _roundTimer;
  int timeLeft = 0;
  
  final List<String> _footballersPool = [
    'Lionel Messi', 'Cristiano Ronaldo', 'Kylian Mbappé', 'Erling Haaland',
    'Jude Bellingham', 'Vinícius Júnior', 'Kevin De Bruyne', 'Mohamed Salah',
    'Harry Kane', 'Neymar Jr', 'Luka Modrić', 'Robert Lewandowski',
    'Bukayo Saka', 'Antoine Griezmann', 'Rodri', 'Jamal Musiala',
    'Phil Foden', 'Florian Wirtz', 'Luis Díaz', 'Declan Rice'
  ];
  final List<String> _usedFootballers = [];
  String? _lastSelectedPosition;

  // Stream controller to notify the Host UI of server logs/events
  final _logController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;

  final _playerListController = StreamController<List<Player>>.broadcast();
  Stream<List<Player>> get playerListStream => _playerListController.stream;

  void _log(String message) {
    print("[Server] $message");
    _logController.add(message);
  }

  // Get local IP address
  Future<String?> getLocalIpAddress() async {
    // Bypass network queries in tests to avoid pending timers
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return "127.0.0.1";
    }

    try {
      // 1. Try NetworkInfo (standard for mobile WiFi IP) with a 1-second timeout
      final info = NetworkInfo();
      final wifiIp = await info.getWifiIP().timeout(
        const Duration(seconds: 1),
        onTimeout: () => null,
      );
      if (wifiIp != null && wifiIp.isNotEmpty && wifiIp != "0.0.0.0") {
        return wifiIp;
      }
    } catch (e) {
      _log("NetworkInfo resolution failed: $e");
    }

    try {
      // 2. Fallback to network interfaces loop
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      _log("Error resolving local IP interfaces: $e");
    }
    return null;
  }

  // Start the server (both WebSocket and UDP discovery)
  Future<bool> start({int port = 4000}) async {
    try {
      await GameDatabase.instance.init();
      final ip = await getLocalIpAddress() ?? '0.0.0.0';
      
      // 1. Start HTTP & WebSocket Server
      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _log("Server started on $ip:$port");

      _httpServer!.listen((HttpRequest request) {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          WebSocketTransformer.upgrade(request).then((WebSocket socket) {
            _handleWebSocketConnection(socket);
          });
        } else {
          final path = request.uri.path;
          if (path == '/' || path == '/index.html') {
            request.response
              ..headers.contentType = ContentType.html
              ..statusCode = HttpStatus.ok
              ..write(webClientHtml)
              ..close();
          } else {
            request.response
              ..statusCode = HttpStatus.notFound
              ..write('Not Found')
              ..close();
          }
        }
      });

      // 2. Start UDP Discovery Listener
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8888);
      _udpSocket!.broadcastEnabled = true;
      _log("UDP Discovery service listening on port 8888");

      _udpSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? dg = _udpSocket!.receive();
          if (dg != null) {
            final message = utf8.decode(dg.data);
            if (message.startsWith("DISCOVER_BITTHEPLAYER_SERVER")) {
              _log("Received discovery request from ${dg.address.address}:${dg.port}");
              
              // Respond with server info: IP, Port, and host nickname
              final response = "BITTHEPLAYER_SERVER_INFO:$ip:$port:Host";
              _udpSocket!.send(utf8.encode(response), dg.address, dg.port);
            }
          }
        }
      });

      return true;
    } catch (e) {
      _log("Failed to start server: $e");
      return false;
    }
  }

  // Stop the server
  Future<void> stop() async {
    _roundTimer?.cancel();
    await _httpServer?.close(force: true);
    _udpSocket?.close();
    
    for (var socket in _playerSockets.values) {
      socket.close();
    }
    _playerSockets.clear();
    players.clear();
    _playerListController.add([]);
    _log("Server stopped.");
  }

  // Broadcast a message to all connected clients
  void broadcast(GameMessage message) {
    final raw = message.toJson();
    for (var socket in _playerSockets.values) {
      socket.add(raw);
    }
  }

  // Send a message to a specific client
  void sendTo(String playerId, GameMessage message) {
    final socket = _playerSockets[playerId];
    if (socket != null) {
      socket.add(message.toJson());
    }
  }

  // Handle new WebSocket connection
  void _handleWebSocketConnection(WebSocket socket) {
    String? connectedPlayerId;
    
    socket.listen(
      (rawData) {
        try {
          final msg = GameMessage.fromJson(rawData as String);
          _handleMessage(msg, socket, (id) {
            connectedPlayerId = id;
          });
        } catch (e) {
          _log("Error parsing message: $e");
        }
      },
      onDone: () {
        if (connectedPlayerId != null) {
          _log("Player $connectedPlayerId disconnected");
          _playerSockets.remove(connectedPlayerId);
          players.removeWhere((p) => p.id == connectedPlayerId);
          _playerListController.add(List.from(players));
          
          // Broadcast updated lobby
          broadcast(GameMessage(
            type: 'lobby_update',
            data: {'players': players.map((p) => p.toMap()).toList()},
          ));
        }
      },
      onError: (err) {
        _log("Socket error: $err");
      }
    );
  }

  // Route messages
  void _handleMessage(GameMessage msg, WebSocket socket, Function(String) onIdentifyPlayer) {
    switch (msg.type) {
      case 'client_join':
        final id = msg.data['id'] as String;
        final name = msg.data['name'] as String;
        onIdentifyPlayer(id);
        
        _playerSockets[id] = socket;
        
        // Add to players list if not exists
        if (!players.any((p) => p.id == id)) {
          final newPlayer = Player(
            id: id,
            name: name,
            budget: initialBudget,
          );
          players.add(newPlayer);
          _log("Player joined: $name ($id)");
        }
        
        _playerListController.add(List.from(players));

        // Reply confirming join
        sendTo(id, GameMessage(
          type: 'join_success',
          data: {'playerId': id, 'serverState': serverState},
        ));

        // Send current game details if in progress, or lobby details
        if (serverState == 'lobby') {
          broadcast(GameMessage(
            type: 'lobby_update',
            data: {'players': players.map((p) => p.toMap()).toList()},
          ));
        } else {
          // If they join during the game, send current state
          sendTo(id, GameMessage(
            type: 'lobby_update',
            data: {'players': players.map((p) => p.toMap()).toList()},
          ));
          _sendCurrentGameStateTo(id);
        }
        break;

      case 'start_game':
        if (serverState == 'lobby') {
          // Master client can trigger start
          bidDurationSeconds = msg.data['duration'] as int? ?? bidDurationSeconds;
          initialBudget = msg.data['budget'] as int? ?? initialBudget;
          totalRounds = msg.data['roundsCount'] as int? ?? totalRounds;
          
          _log("Starting game: duration=$bidDurationSeconds, budget=$initialBudget, rounds=$totalRounds");
          
          // Reset players state
          for (var p in players) {
            p.budget = initialBudget;
            p.wonFootballers = [];
          }
          _playerListController.add(List.from(players));

          serverState = 'playing';
          currentRound = 0;
          _usedFootballers.clear();
          _lastSelectedPosition = null;
          
          _startNextRound();
        }
        break;

      case 'place_bid':
        final playerId = msg.data['playerId'] as String;
        final playerName = msg.data['playerName'] as String;
        final bidAmount = msg.data['amount'] as int;

        _log("Bid request: $playerName bid $bidAmount (Current highest: $highestBid)");

        if (serverState == 'bidding') {
          final player = players.firstWhere((p) => p.id == playerId);
          if (bidAmount > highestBid && bidAmount <= player.budget) {
            highestBid = bidAmount;
            dynamic extensionLog = "";
            
            // Overtime extension: +3 seconds if timeLeft <= 5
            if (timeLeft <= 5) {
              timeLeft += 3;
              extensionLog = " (Overtime +3s!)";
            }
            
            highestBidderId = playerId;
            highestBidderName = playerName;

            _log("New highest bid: $highestBid by $highestBidderName$extensionLog");

            broadcast(GameMessage(
              type: 'bid_update',
              data: {
                'highestBid': highestBid,
                'highestBidderId': highestBidderId,
                'highestBidderName': highestBidderName,
              },
            ));

            if (extensionLog.isNotEmpty) {
              broadcast(GameMessage(
                type: 'timer_tick',
                data: {'timeLeft': timeLeft},
              ));
            }
          } else {
            // Send bid rejected message to that user
            sendTo(playerId, GameMessage(
              type: 'bid_rejected',
              data: {
                'reason': bidAmount <= highestBid 
                    ? 'Bid must be higher than current highest bid ($highestBid)'
                    : 'Insufficient budget ($bidAmount > ${player.budget})'
              },
            ));
          }
        }
        break;

      case 'next_round':
        // Host proceeds to next round
        if (serverState == 'round_result') {
          _startNextRound();
        }
        break;

      case 'reset_game':
        // Host resets the game back to lobby
        _log("Game reset to lobby by host.");
        serverState = 'lobby';
        _roundTimer?.cancel();
        
        broadcast(GameMessage(
          type: 'game_reset_to_lobby',
          data: {},
        ));
        broadcast(GameMessage(
          type: 'lobby_update',
          data: {'players': players.map((p) => p.toMap()).toList()},
        ));
        break;
    }
  }

  void _sendCurrentGameStateTo(String id) {
    if (serverState == 'bidding') {
      final entry = GameDatabase.instance.entries[currentFootballer];
      sendTo(id, GameMessage(
        type: 'new_round',
        data: {
          'roundNumber': currentRound,
          'totalRounds': totalRounds,
          'footballer': currentFootballer,
          'position': entry?.position ?? 'Striker',
          'timeLeft': timeLeft,
          'highestBid': highestBid,
          'highestBidderId': highestBidderId,
          'highestBidderName': highestBidderName,
        },
      ));
    } else if (serverState == 'round_result') {
      final entry = GameDatabase.instance.entries[currentFootballer];
      sendTo(id, GameMessage(
        type: 'round_result',
        data: {
          'winnerId': highestBidderId,
          'winnerName': highestBidderName,
          'winningBid': highestBid,
          'footballer': currentFootballer,
          'position': entry?.position ?? 'Striker',
          'scoreboard': players.map((p) => p.toMap()).toList(),
          'roundNumber': currentRound,
          'totalRounds': totalRounds,
          'realValues': _getRealValuesMap(),
          'positions': _getPositionsMap(),
        },
      ));
    }
  }

  void _startNextRound() {
    _roundTimer?.cancel();
    
    currentRound++;
    if (currentRound > totalRounds) {
      _endGame();
      return;
    }

    // Select random footballer from database that hasn't been used yet
    final allDbNames = GameDatabase.instance.entries.keys.toList();
    var remainingFootballers = allDbNames.where((name) => !_usedFootballers.contains(name)).toList();
    if (remainingFootballers.isEmpty) {
      _usedFootballers.clear(); // Recirculate if pool is exhausted
      remainingFootballers = allDbNames;
    }
    
    final random = Random();
    String selectedFootballer = '';
    
    if (remainingFootballers.isNotEmpty) {
      final filterByPosition = remainingFootballers.where((name) {
        final entry = GameDatabase.instance.entries[name];
        if (entry == null) return false;
        return _lastSelectedPosition == null || entry.position != _lastSelectedPosition;
      }).toList();
      
      if (filterByPosition.isNotEmpty) {
        selectedFootballer = filterByPosition[random.nextInt(filterByPosition.length)];
      } else {
        selectedFootballer = remainingFootballers[random.nextInt(remainingFootballers.length)];
      }
    } else {
      selectedFootballer = _footballersPool[random.nextInt(_footballersPool.length)];
    }
    
    currentFootballer = selectedFootballer;
    _usedFootballers.add(currentFootballer);
    
    final chosenEntry = GameDatabase.instance.entries[currentFootballer];
    if (chosenEntry != null) {
      _lastSelectedPosition = chosenEntry.position;
    }

    // Reset bidding parameters
    highestBid = 0;
    highestBidderId = '';
    highestBidderName = '';
    timeLeft = bidDurationSeconds;
    serverState = 'bidding';

    _log("Starting round $currentRound/$totalRounds for footballer: $currentFootballer (${chosenEntry?.position ?? 'Striker'})");

    // Broadcast new round
    broadcast(GameMessage(
      type: 'new_round',
      data: {
        'roundNumber': currentRound,
        'totalRounds': totalRounds,
        'footballer': currentFootballer,
        'position': chosenEntry?.position ?? 'Striker',
        'timeLeft': timeLeft,
        'highestBid': highestBid,
        'highestBidderId': highestBidderId,
        'highestBidderName': highestBidderName,
      },
    ));

    // Start timer countdown
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      timeLeft--;
      
      broadcast(GameMessage(
        type: 'timer_tick',
        data: {'timeLeft': timeLeft},
      ));

      if (timeLeft <= 0) {
        _endRound();
      }
    });
  }

  void _endRound() {
    _roundTimer?.cancel();
    serverState = 'round_result';

    String winnerName = 'No One';
    String winnerId = '';
    
    if (highestBid > 0 && highestBidderId.isNotEmpty) {
      // Find winner
      try {
        final winnerIndex = players.indexWhere((p) => p.id == highestBidderId);
        if (winnerIndex != -1) {
          final winner = players[winnerIndex];
          winner.budget -= highestBid;
          winner.wonFootballers.add(currentFootballer);
          winnerId = winner.id;
          winnerName = winner.name;
          _log("Winner of $currentFootballer: $winnerName with $highestBid");
          
          // Record the winning bid in database
          GameDatabase.instance.recordWinningBid(currentFootballer, highestBid);
        }
      } catch (e) {
        _log("Error process winner: $e");
      }
    } else {
      _log("No bids placed for $currentFootballer");
    }

    _playerListController.add(List.from(players));

    final entry = GameDatabase.instance.entries[currentFootballer];
    
    // Broadcast round result
    broadcast(GameMessage(
      type: 'round_result',
      data: {
        'winnerId': winnerId,
        'winnerName': winnerName,
        'winningBid': highestBid,
        'footballer': currentFootballer,
        'position': entry?.position ?? 'Striker',
        'scoreboard': players.map((p) => p.toMap()).toList(),
        'roundNumber': currentRound,
        'totalRounds': totalRounds,
        'realValues': _getRealValuesMap(),
        'positions': _getPositionsMap(),
      },
    ));
  }

  void _endGame() {
    serverState = 'game_over';
    _log("Game over! Broadcasting final results.");

    // Broadcast game over
    broadcast(GameMessage(
      type: 'game_over',
      data: {
        'scoreboard': players.map((p) => p.toMap()).toList(),
        'realValues': _getRealValuesMap(),
        'positions': _getPositionsMap(),
      },
    ));
  }

  Map<String, int> _getRealValuesMap() {
    final map = <String, int>{};
    GameDatabase.instance.entries.forEach((name, entry) {
      map[name] = GameDatabase.instance.getRealValue(name);
    });
    // Ensure any currently won footballers or active footballers are included
    for (var p in players) {
      for (var f in p.wonFootballers) {
        map.putIfAbsent(f, () => GameDatabase.instance.getRealValue(f));
      }
    }
    map.putIfAbsent(currentFootballer, () => GameDatabase.instance.getRealValue(currentFootballer));
    return map;
  }

  Map<String, String> _getPositionsMap() {
    final map = <String, String>{};
    GameDatabase.instance.entries.forEach((name, entry) {
      map[name] = entry.position;
    });
    // Ensure any currently won footballers or active footballers are included
    for (var p in players) {
      for (var f in p.wonFootballers) {
        map.putIfAbsent(f, () => GameDatabase.instance.entries[f]?.position ?? 'Striker');
      }
    }
    map.putIfAbsent(currentFootballer, () => GameDatabase.instance.entries[currentFootballer]?.position ?? 'Striker');
    return map;
  }
}
