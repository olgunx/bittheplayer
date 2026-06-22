import 'package:flutter/material.dart';
import '../network/game_protocol.dart';
import '../network/instances.dart';
import 'lobby_screen.dart';
import 'theme.dart';

class ResultsScreen extends StatefulWidget {
  final bool isHost;

  const ResultsScreen({Key? key, required this.isHost}) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late VoidCallback _clientListener;

  @override
  void initState() {
    super.initState();
    
    // Auto return to lobby if host resets game
    _clientListener = () {
      if (gameClient.serverState == 'lobby') {
        if (mounted) {
          gameClient.removeListener(_clientListener);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LobbyScreen(isHost: widget.isHost),
            ),
          );
        }
      }
    };
    gameClient.addListener(_clientListener);
  }

  @override
  void dispose() {
    gameClient.removeListener(_clientListener);
    super.dispose();
  }

  void _returnToLobby() {
    gameClient.resetGame();
  }

  void _leaveGame() async {
    gameClient.disconnect();
    if (widget.isHost) {
      await gameServer.stop();
    }
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  num _getPlayerTeamValue(Player player) {
    num sum = 0;
    int strikerCount = 0;
    int midfielderCount = 0;
    int defenderCount = 0;
    for (var f in player.wonFootballers) {
      final val = gameClient.realValues[f] ?? 50;
      final pos = gameClient.footballerPositions[f] ?? 'Striker';
      
      if (pos == 'Striker') {
        strikerCount++;
        if (strikerCount > 1) {
          sum += val * 0.5;
        } else {
          sum += val;
        }
      } else if (pos == 'Center Mid' || pos == 'Winger') {
        midfielderCount++;
        if (midfielderCount > 2) {
          sum += val * 0.5;
        } else {
          sum += val;
        }
      } else if (pos == 'Center Back' || pos == 'Full Back') {
        defenderCount++;
        if (defenderCount > 2) {
          sum += val * 0.5;
        } else {
          sum += val;
        }
      } else {
        sum += val;
      }
    }
    return sum;
  }

  String _formatValuation(num value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toString();
  }

  List<Player> _getRankedPlayers() {
    final list = List<Player>.from(gameClient.players);
    // Sort logic:
    // 1st criteria: total Real Value of footballers won (descending)
    // 2nd criteria: remaining budget (descending)
    list.sort((a, b) {
      final aVal = _getPlayerTeamValue(a);
      final bVal = _getPlayerTeamValue(b);
      final valComparison = bVal.compareTo(aVal);
      if (valComparison != 0) return valComparison;
      return b.budget.compareTo(a.budget);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final rankedPlayers = _getRankedPlayers();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GameTheme.darkGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Animated Crown Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: GameTheme.gold.withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      size: 70,
                      color: GameTheme.gold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "GAME OVER",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                const Text(
                  "Final Standings & Achievements",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: GameTheme.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 32),

                // Leaderboard List
                Expanded(
                  child: ListView.separated(
                    itemCount: rankedPlayers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final player = rankedPlayers[index];
                      final isSelf = player.id == gameClient.playerId;
                      final rank = index + 1;
                      
                      // Highlight top 3
                      Color rankColor;
                      IconData rankIcon;
                      switch (rank) {
                        case 1:
                          rankColor = GameTheme.gold;
                          rankIcon = Icons.workspace_premium;
                          break;
                        case 2:
                          rankColor = const Color(0xFFC0C0C0); // Silver
                          rankIcon = Icons.workspace_premium;
                          break;
                        case 3:
                          rankColor = const Color(0xFFCD7F32); // Bronze
                          rankIcon = Icons.workspace_premium;
                          break;
                        default:
                          rankColor = GameTheme.textSecondary;
                          rankIcon = Icons.star_border;
                      }

                      return GlassCard(
                        fillColor: isSelf 
                            ? GameTheme.primary.withOpacity(0.08) 
                            : GameTheme.surface.withOpacity(0.4),
                        borderColor: isSelf 
                            ? GameTheme.primary.withOpacity(0.4) 
                            : const Color(0x1F94A3B8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Rank icon/number
                                Icon(rankIcon, color: rankColor, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  "#$rank",
                                  style: TextStyle(
                                    color: rankColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Player Name
                                Expanded(
                                  child: Text(
                                    player.name + (isSelf ? " (You)" : ""),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isSelf ? GameTheme.primary : Colors.white,
                                    ),
                                  ),
                                ),
                                // Player score (footballers count)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                     Text(
                                       "\$${_formatValuation(_getPlayerTeamValue(player))}M Value",
                                       style: const TextStyle(
                                         color: GameTheme.accent,
                                         fontWeight: FontWeight.bold,
                                         fontSize: 14,
                                       ),
                                     ),
                                    Text(
                                      "Wallet: \$${player.budget}M (${player.wonFootballers.length} Players)",
                                      style: const TextStyle(
                                        color: GameTheme.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            
                            // Footballers details
                            if (player.wonFootballers.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: player.wonFootballers.map((f) {
                                  final pos = gameClient.footballerPositions[f] ?? 'Striker';
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: GameTheme.secondary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: GameTheme.secondary.withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      "$f ($pos - \$${gameClient.realValues[f] ?? 50}M)",
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                                    ),
                                  );
                                }).toList(),
                              )
                            ]
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Footer Buttons
                if (widget.isHost)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _leaveGame,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: GameTheme.error),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            "LEAVE GAME",
                            style: TextStyle(color: GameTheme.error, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GradientButton(
                          text: "PLAY AGAIN",
                          icon: Icons.replay,
                          onPressed: _returnToLobby,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlassCard(
                        fillColor: GameTheme.surface.withOpacity(0.4),
                        padding: const EdgeInsets.all(14),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(GameTheme.primary)),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Waiting for Host to restart match...",
                              style: TextStyle(color: GameTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GradientButton(
                        text: "LEAVE GAME",
                        gradient: GameTheme.secondaryGradient,
                        onPressed: _leaveGame,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
