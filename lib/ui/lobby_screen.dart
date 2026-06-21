import 'dart:async';
import 'package:flutter/material.dart';
import '../network/instances.dart';
import 'game_screen.dart';
import 'theme.dart';

class LobbyScreen extends StatefulWidget {
  final bool isHost;

  const LobbyScreen({Key? key, required this.isHost}) : super(key: key);

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  // Host settings controllers/values
  double _duration = 15; // seconds
  double _budget = 100; // coins
  double _rounds = 5; // number of rounds
  
  String _localIp = "Resolving IP...";
  late VoidCallback _clientListener;

  @override
  void initState() {
    super.initState();
    _resolveIp();
    
    // Listen to game client state changes
    _clientListener = () {
      if (gameClient.serverState == 'bidding' || gameClient.serverState == 'playing') {
        if (mounted) {
          // Remove listener before navigating to avoid trigger loops
          gameClient.removeListener(_clientListener);
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GameScreen(isHost: widget.isHost),
            ),
          );
        }
      }
    };
    
    gameClient.addListener(_clientListener);
  }

  Future<void> _resolveIp() async {
    final ip = await gameServer.getLocalIpAddress();
    if (mounted) {
      setState(() {
        _localIp = ip ?? "Unknown Network";
      });
    }
  }

  @override
  void dispose() {
    // Safely remove listener
    gameClient.removeListener(_clientListener);
    super.dispose();
  }

  void _leaveLobby() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isHost ? "Stop Hosting?" : "Leave Lobby?"),
        content: Text(widget.isHost 
            ? "This will disconnect all players and close the server." 
            : "You will return to the server selection screen."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              
              gameClient.disconnect();
              if (widget.isHost) {
                await gameServer.stop();
              }
              
              if (mounted) {
                Navigator.pop(context); // return to RoleSelectionScreen
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: GameTheme.error),
            child: const Text("LEAVE"),
          ),
        ],
      ),
    );
  }

  void _startGame() {
    if (gameClient.players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot start game with 0 players!")),
      );
      return;
    }
    
    gameClient.startGame(
      duration: _duration.toInt(),
      budget: _budget.toInt(),
      roundsCount: _rounds.toInt(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _leaveLobby();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: GameTheme.textPrimary),
            onPressed: _leaveLobby,
          ),
          title: Text(
            widget.isHost ? "Host Lobby" : "Player Lobby",
            style: const TextStyle(fontWeight: FontWeight.bold, color: GameTheme.textPrimary),
          ),
          centerTitle: true,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: GameTheme.darkGradient,
          ),
          child: AnimatedBuilder(
            animation: gameClient,
            builder: (context, _) {
              final players = gameClient.players;
              final isConnected = gameClient.connectionStatus == 'connected';

              if (!isConnected) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Reconnecting to server..."),
                    ],
                  ),
                );
              }

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Connection IP info
                      GlassCard(
                        fillColor: GameTheme.surface.withOpacity(0.5),
                        child: Column(
                          children: [
                            const Text(
                              "SERVER CONNECTION DETAIL",
                              style: TextStyle(
                                color: GameTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              widget.isHost ? "$_localIp:4000" : "Connected to Host",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: GameTheme.primary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier', // monospace look
                              ),
                            ),
                            if (widget.isHost) ...[
                              const SizedBox(height: 6),
                              const Text(
                                "Share this IP with other players on your local network.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: GameTheme.textMuted, fontSize: 11),
                              ),
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Host Game Settings Section
                      if (widget.isHost) ...[
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                "GAME RULES (HOST ONLY)",
                                style: TextStyle(
                                  color: GameTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Duration Slider
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Bidding Duration", style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text("${_duration.toInt()} seconds", style: const TextStyle(color: GameTheme.accent, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Slider(
                                value: _duration,
                                min: 5,
                                max: 60,
                                divisions: 11,
                                activeColor: GameTheme.primary,
                                inactiveColor: GameTheme.textMuted.withOpacity(0.3),
                                onChanged: (val) => setState(() => _duration = val),
                              ),

                              // Budget Slider
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Starting Budget", style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text("\$${_budget.toInt()}M", style: const TextStyle(color: GameTheme.accent, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Slider(
                                value: _budget,
                                min: 10,
                                max: 500,
                                divisions: 49,
                                activeColor: GameTheme.primary,
                                inactiveColor: GameTheme.textMuted.withOpacity(0.3),
                                onChanged: (val) => setState(() => _budget = val),
                              ),

                              // Rounds Slider
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Total Auction Rounds", style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text("${_rounds.toInt()} footballers", style: const TextStyle(color: GameTheme.accent, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Slider(
                                value: _rounds,
                                min: 1,
                                max: 20,
                                divisions: 19,
                                activeColor: GameTheme.primary,
                                inactiveColor: GameTheme.textMuted.withOpacity(0.3),
                                onChanged: (val) => setState(() => _rounds = val),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Connected Players header
                      Row(
                        children: [
                          const Icon(Icons.people, color: GameTheme.textSecondary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "PLAYERS IN LOBBY (${players.length})",
                            style: const TextStyle(
                              color: GameTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Players List
                      Expanded(
                        child: players.isEmpty
                            ? const Center(
                                child: Text(
                                  "Waiting for players to join...",
                                  style: TextStyle(color: GameTheme.textMuted),
                                ),
                              )
                            : ListView.separated(
                                itemCount: players.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final player = players[index];
                                  final isSelf = player.id == gameClient.playerId;
                                  return GlassCard(
                                    fillColor: isSelf 
                                        ? GameTheme.primary.withOpacity(0.1) 
                                        : GameTheme.surface.withOpacity(0.3),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    borderColor: isSelf 
                                        ? GameTheme.primary.withOpacity(0.5) 
                                        : const Color(0x1F94A3B8),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: isSelf ? GameTheme.primary : GameTheme.secondary,
                                          child: Text(
                                            player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            player.name + (isSelf ? " (You)" : ""),
                                            style: TextStyle(
                                              fontWeight: isSelf ? FontWeight.bold : FontWeight.normal,
                                              color: isSelf ? Colors.white : GameTheme.textPrimary,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        if (index == 0) // First player in lobby list is usually the host
                                          const Chip(
                                            label: Text("HOST", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                                            backgroundColor: GameTheme.secondary,
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          )
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Action Button
                      if (widget.isHost)
                        GradientButton(
                          text: "START MATCH",
                          icon: Icons.play_arrow,
                          onPressed: players.isEmpty ? null : _startGame,
                        )
                      else
                        GlassCard(
                          fillColor: GameTheme.surface.withOpacity(0.5),
                          padding: const EdgeInsets.all(16),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(GameTheme.primary)),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  "Waiting for Host to start match...",
                                  style: TextStyle(color: GameTheme.textSecondary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
              },
          ),
        ),
      ),
    );
  }
}
