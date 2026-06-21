import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'game_protocol.dart';

class GameClient extends ChangeNotifier {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  // Connection Status
  String connectionStatus = 'disconnected'; // disconnected, connecting, connected
  String? connectionError;
  
  // Player Profile
  late String playerId;
  String playerName = '';
  
  // Game State
  String serverState = 'lobby'; // lobby, bidding, round_result, game_over
  List<Player> players = [];
  
  // Active Bidding State
  int currentRound = 0;
  int totalRounds = 0;
  String currentFootballer = '';
  String currentFootballerPosition = '';
  int timeLeft = 0;
  int highestBid = 0;
  String highestBidderId = '';
  String highestBidderName = '';
  
  // Round Result State
  String roundWinnerName = '';
  String roundWinnerId = '';
  int roundWinningBid = 0;
  
  // Toast/Error message for invalid bids
  String? bidRejectedReason;
  Timer? _rejectedReasonTimer;

  // Real values of footballers from database
  Map<String, int> realValues = {};

  // Playing positions of footballers
  Map<String, String> footballerPositions = {};

  GameClient() {
    playerId = const Uuid().v4();
  }

  // Connect to the host server
  Future<void> connect(String ip, int port, String nickname) async {
    playerName = nickname;
    connectionStatus = 'connecting';
    connectionError = null;
    notifyListeners();

    final uri = Uri.parse('ws://$ip:$port');
    try {
      _channel = WebSocketChannel.connect(uri);
      
      // Wait for the channel to initialize and start listening
      _subscription = _channel!.stream.listen(
        (rawData) {
          _handleIncomingMessage(rawData as String);
        },
        onDone: () {
          _handleDisconnect();
        },
        onError: (err) {
          connectionError = "Connection error: $err";
          _handleDisconnect();
        },
      );
      
      connectionStatus = 'connected';
      _sendJoinMessage();
      notifyListeners();
    } catch (e) {
      connectionStatus = 'disconnected';
      connectionError = "Failed to connect: $e";
      notifyListeners();
    }
  }

  // Disconnect from server
  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _handleDisconnect();
  }

  void _handleDisconnect() {
    connectionStatus = 'disconnected';
    serverState = 'lobby';
    players.clear();
    _subscription = null;
    _channel = null;
    notifyListeners();
  }

  // Send Join Request
  void _sendJoinMessage() {
    _send(GameMessage(
      type: 'client_join',
      data: {'id': playerId, 'name': playerName},
    ));
  }

  // Submit Bid
  void placeBid(int amount) {
    bidRejectedReason = null;
    _send(GameMessage(
      type: 'place_bid',
      data: {
        'playerId': playerId,
        'playerName': playerName,
        'amount': amount,
      },
    ));
  }

  // Host Action: Start Game
  void startGame({required int duration, required int budget, required int roundsCount}) {
    _send(GameMessage(
      type: 'start_game',
      data: {
        'duration': duration,
        'budget': budget,
        'roundsCount': roundsCount,
      },
    ));
  }

  // Host Action: Next Round
  void nextRound() {
    _send(GameMessage(
      type: 'next_round',
      data: {},
    ));
  }

  // Host Action: Reset Game to Lobby
  void resetGame() {
    _send(GameMessage(
      type: 'reset_game',
      data: {},
    ));
  }

  // Helper send
  void _send(GameMessage msg) {
    if (_channel != null && connectionStatus == 'connected') {
      _channel!.sink.add(msg.toJson());
    }
  }

  // Handle message from server
  void _handleIncomingMessage(String rawData) {
    final msg = GameMessage.fromJson(rawData);
    
    switch (msg.type) {
      case 'join_success':
        serverState = msg.data['serverState'] as String? ?? 'lobby';
        notifyListeners();
        break;

      case 'lobby_update':
        final rawPlayers = msg.data['players'] as List;
        players = rawPlayers.map((p) => Player.fromMap(p as Map<String, dynamic>)).toList();
        notifyListeners();
        break;

      case 'new_round':
        serverState = 'bidding';
        currentRound = msg.data['roundNumber'] as int;
        totalRounds = msg.data['totalRounds'] as int;
        currentFootballer = msg.data['footballer'] as String;
        currentFootballerPosition = msg.data['position'] as String? ?? 'Striker';
        timeLeft = msg.data['timeLeft'] as int;
        highestBid = msg.data['highestBid'] as int;
        highestBidderId = msg.data['highestBidderId'] as String? ?? '';
        highestBidderName = msg.data['highestBidderName'] as String? ?? '';
        bidRejectedReason = null;
        notifyListeners();
        break;

      case 'timer_tick':
        timeLeft = msg.data['timeLeft'] as int;
        notifyListeners();
        break;

      case 'bid_update':
        highestBid = msg.data['highestBid'] as int;
        highestBidderId = msg.data['highestBidderId'] as String;
        highestBidderName = msg.data['highestBidderName'] as String;
        notifyListeners();
        break;

      case 'bid_rejected':
        bidRejectedReason = msg.data['reason'] as String;
        _rejectedReasonTimer?.cancel();
        _rejectedReasonTimer = Timer(const Duration(seconds: 2), () {
          bidRejectedReason = null;
          notifyListeners();
        });
        notifyListeners();
        break;

      case 'round_result':
        serverState = 'round_result';
        roundWinnerId = msg.data['winnerId'] as String? ?? '';
        roundWinnerName = msg.data['winnerName'] as String? ?? 'No One';
        roundWinningBid = msg.data['winningBid'] as int? ?? 0;
        currentFootballer = msg.data['footballer'] as String? ?? '';
        
        final rawPlayers = msg.data['scoreboard'] as List;
        players = rawPlayers.map((p) => Player.fromMap(p as Map<String, dynamic>)).toList();
        
        if (msg.data['realValues'] != null) {
          final Map<String, dynamic> rawVals = msg.data['realValues'] as Map<String, dynamic>;
          realValues = rawVals.map((k, v) => MapEntry(k, v as int));
        }
        if (msg.data['positions'] != null) {
          final Map<String, dynamic> rawPos = msg.data['positions'] as Map<String, dynamic>;
          footballerPositions = rawPos.map((k, v) => MapEntry(k, v as String));
        }
        notifyListeners();
        break;

      case 'game_over':
        serverState = 'game_over';
        final rawPlayers = msg.data['scoreboard'] as List;
        players = rawPlayers.map((p) => Player.fromMap(p as Map<String, dynamic>)).toList();
        if (msg.data['realValues'] != null) {
          final Map<String, dynamic> rawVals = msg.data['realValues'] as Map<String, dynamic>;
          realValues = rawVals.map((k, v) => MapEntry(k, v as int));
        }
        if (msg.data['positions'] != null) {
          final Map<String, dynamic> rawPos = msg.data['positions'] as Map<String, dynamic>;
          footballerPositions = rawPos.map((k, v) => MapEntry(k, v as String));
        }
        notifyListeners();
        break;

      case 'game_reset_to_lobby':
        serverState = 'lobby';
        currentRound = 0;
        highestBid = 0;
        highestBidderId = '';
        highestBidderName = '';
        currentFootballerPosition = '';
        realValues.clear();
        footballerPositions.clear();
        notifyListeners();
        break;
    }
  }

  @override
  void dispose() {
    _rejectedReasonTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
