import 'package:flutter/material.dart';
import '../network/game_protocol.dart';
import '../network/instances.dart';
import 'lobby_screen.dart';
import 'results_screen.dart';
import 'theme.dart';

class GameScreen extends StatefulWidget {
  final bool isHost;

  const GameScreen({Key? key, required this.isHost}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TextEditingController _customBidController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late VoidCallback _clientListener;

  @override
  void initState() {
    super.initState();
    
    _clientListener = () {
      if (gameClient.serverState == 'game_over') {
        if (mounted) {
          gameClient.removeListener(_clientListener);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsScreen(isHost: widget.isHost),
            ),
          );
        }
      } else if (gameClient.serverState == 'lobby') {
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
    _customBidController.dispose();
    super.dispose();
  }

  void _submitBid(int amount) {
    if (amount <= gameClient.highestBid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Your bid must be higher than current highest bid (\$${gameClient.highestBid}M)"),
          backgroundColor: GameTheme.error,
        ),
      );
      return;
    }
    
    final selfPlayer = gameClient.players.firstWhere((p) => p.id == gameClient.playerId);
    if (amount > selfPlayer.budget) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Insufficient budget! You only have \$${selfPlayer.budget}M"),
          backgroundColor: GameTheme.error,
        ),
      );
      return;
    }

    gameClient.placeBid(amount);
    _customBidController.clear();
    FocusScope.of(context).unfocus();
  }

  void _nextRound() {
    gameClient.nextRound();
  }

  void _resetGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Game?"),
        content: const Text("This will terminate the active game and return all players to the lobby."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              gameClient.resetGame();
            },
            style: ElevatedButton.styleFrom(backgroundColor: GameTheme.error),
            child: const Text("RESET"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildScoreboardDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isHost
            ? IconButton(
                icon: const Icon(Icons.refresh, color: GameTheme.textSecondary),
                tooltip: "Reset game",
                onPressed: _resetGame,
              )
            : Container(),
        title: AnimatedBuilder(
          animation: gameClient,
          builder: (context, _) => Text(
            "ROUND ${gameClient.currentRound} / ${gameClient.totalRounds}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: GameTheme.textPrimary),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard, color: GameTheme.primary),
            tooltip: "View Standings",
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: GameTheme.darkGradient,
        ),
        child: AnimatedBuilder(
          animation: gameClient,
          builder: (context, _) {
            // Find current player object
            final selfPlayer = gameClient.players.firstWhere(
              (p) => p.id == gameClient.playerId,
              orElse: () => Player(id: '', name: 'Guest', budget: 0),
            );

            final isBiddingActive = gameClient.serverState == 'bidding';
            final isLeading = gameClient.highestBidderId == gameClient.playerId;
            final hasHighestBid = gameClient.highestBid > 0;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Player Stats Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("YOUR BUDGET", style: TextStyle(color: GameTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            Text("\$${selfPlayer.budget}M", style: const TextStyle(color: GameTheme.gold, fontSize: 24, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        // Winning / Outbid Badge
                        if (isBiddingActive && hasHighestBid)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isLeading ? GameTheme.primary.withOpacity(0.15) : GameTheme.error.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isLeading ? GameTheme.primary : GameTheme.error, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Icon(isLeading ? Icons.check_circle : Icons.warning_amber_rounded, size: 14, color: isLeading ? GameTheme.primary : GameTheme.error),
                                const SizedBox(width: 6),
                                Text(
                                  isLeading ? "YOU LEAD" : "OUTBID",
                                  style: TextStyle(
                                    color: isLeading ? GameTheme.primary : GameTheme.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Main Footballer Card Area
                    Expanded(
                      flex: 4,
                      child: _buildFootballerCard(isBiddingActive),
                    ),
                    const SizedBox(height: 16),

                    // Bid Display Panel
                    _buildBidDisplayPanel(hasHighestBid),
                    const SizedBox(height: 16),

                    // Bid Input & Action Controls
                    Expanded(
                      flex: 3,
                      child: _buildControlsSection(selfPlayer, isBiddingActive),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFootballerCard(bool isBiddingActive) {
    final name = gameClient.currentFootballer;
    final timeLeft = gameClient.timeLeft;
    
    // Pulse timer or change color when running out
    final isCriticalTime = timeLeft <= 5 && isBiddingActive;
    final timerColor = isCriticalTime ? GameTheme.error : GameTheme.primary;

    return GlassCard(
      fillColor: GameTheme.surface.withOpacity(0.2),
      padding: const EdgeInsets.all(24),
      borderColor: isCriticalTime ? GameTheme.error.withOpacity(0.5) : const Color(0x1F94A3B8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Timer Widget
          if (isBiddingActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: timerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: timerColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, color: timerColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "0:${timeLeft.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      color: timerColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: GameTheme.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GameTheme.secondary.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gavel, color: GameTheme.secondary, size: 16),
                  SizedBox(width: 6),
                  Text(
                    "ROUND OVER",
                    style: TextStyle(
                      color: GameTheme.secondary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          // Football Silhouette / Icon placeholder
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GameTheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_run, // Running footballer feel
              size: 70,
              color: GameTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          // Footballer Name
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: GameTheme.textPrimary,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  offset: Offset(0, 4),
                  blurRadius: 6,
                )
              ]
            ),
          ),
          const SizedBox(height: 8),
          if (gameClient.currentFootballerPosition.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: GameTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: GameTheme.primary, width: 1),
              ),
              child: Text(
                gameClient.currentFootballerPosition.toUpperCase(),
                style: const TextStyle(
                  color: GameTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBidDisplayPanel(bool hasHighestBid) {
    return GlassCard(
      fillColor: GameTheme.surface.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "CURRENT BID",
                style: TextStyle(
                  color: GameTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Highest Offer",
                style: TextStyle(color: GameTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hasHighestBid ? "\$${gameClient.highestBid}M" : "\$0M",
                style: const TextStyle(
                  color: GameTheme.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(color: GameTheme.primary, blurRadius: 15)
                  ]
                ),
              ),
              Text(
                hasHighestBid 
                    ? "by ${gameClient.highestBidderName}" 
                    : "No offers yet",
                style: const TextStyle(
                  color: GameTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlsSection(Player selfPlayer, bool isBiddingActive) {
    if (isBiddingActive) {
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Quick bidding buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [1, 5, 10, 20].map((increment) {
              final bidCandidate = gameClient.highestBid + increment;
              final isAffordable = bidCandidate <= selfPlayer.budget;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: (isAffordable && isBiddingActive) 
                        ? () => _submitBid(bidCandidate) 
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GameTheme.surfaceLight,
                      disabledBackgroundColor: GameTheme.surfaceLight.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      "+\$${increment}M",
                      style: TextStyle(
                        color: isAffordable ? GameTheme.primary : GameTheme.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Custom Bid Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customBidController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: "Enter Custom Bid",
                    prefixText: "\$",
                    suffixText: "M",
                  ),
                  onSubmitted: (val) {
                    final amount = int.tryParse(val) ?? 0;
                    _submitBid(amount);
                  },
                ),
              ),
              const SizedBox(width: 12),
              GradientButton(
                text: "BID",
                width: 100,
                onPressed: () {
                  final amount = int.tryParse(_customBidController.text) ?? 0;
                  _submitBid(amount);
                },
              ),
            ],
          ),
          
          // Bid validation error display
          if (gameClient.bidRejectedReason != null) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                gameClient.bidRejectedReason!,
                style: const TextStyle(
                  color: GameTheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ]
        ],
      );
    } else {
      // Round Result state UI
      final isWinnerMe = gameClient.roundWinnerId == gameClient.playerId;
      final hasWinner = gameClient.roundWinnerId.isNotEmpty;

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Winner Announcement Card
          GlassCard(
            fillColor: isWinnerMe 
                ? GameTheme.primary.withOpacity(0.1) 
                : GameTheme.secondary.withOpacity(0.05),
            borderColor: isWinnerMe 
                ? GameTheme.primary.withOpacity(0.4) 
                : GameTheme.secondary.withOpacity(0.2),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  hasWinner 
                      ? (isWinnerMe ? "🏆 YOU WON THE BID!" : "ROUND WINNER")
                      : "UNSOLD PLAYER",
                  style: TextStyle(
                    color: hasWinner 
                        ? (isWinnerMe ? GameTheme.primary : GameTheme.secondary) 
                        : GameTheme.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasWinner
                      ? "${gameClient.roundWinnerName} bought ${gameClient.currentFootballer} (${gameClient.currentFootballerPosition}) for \$${gameClient.roundWinningBid}M"
                      : "No bids were placed on ${gameClient.currentFootballer}.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (hasWinner && gameClient.realValues.containsKey(gameClient.currentFootballer)) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Real Value: \$${gameClient.realValues[gameClient.currentFootballer]}M",
                    style: const TextStyle(
                      color: GameTheme.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Next Round or Waiting state button
          if (widget.isHost)
            GradientButton(
              text: "START NEXT ROUND",
              icon: Icons.navigate_next,
              onPressed: _nextRound,
            )
          else
            GlassCard(
              fillColor: GameTheme.surface.withOpacity(0.4),
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(GameTheme.secondary)),
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Waiting for Host to start next round...",
                      style: TextStyle(color: GameTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
        ],
      );
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

  // Right Drawer representing the Scoreboard
  Widget _buildScoreboardDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          color: GameTheme.background,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "LEADERBOARD & WALLETS",
                  style: TextStyle(
                    color: GameTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Divider(color: Color(0x3394A3B8), height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: gameClient.players.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final player = gameClient.players[index];
                    final isSelf = player.id == gameClient.playerId;
                    
                    return GlassCard(
                      fillColor: isSelf 
                          ? GameTheme.primary.withOpacity(0.08) 
                          : GameTheme.surface.withOpacity(0.5),
                      borderColor: isSelf 
                          ? GameTheme.primary.withOpacity(0.3) 
                          : const Color(0x1A94A3B8),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                player.name + (isSelf ? " (You)" : ""),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelf ? GameTheme.primary : GameTheme.textPrimary,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "\$${player.budget}M Wallet",
                                    style: const TextStyle(
                                      color: GameTheme.gold,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (gameClient.realValues.isNotEmpty && player.wonFootballers.isNotEmpty)
                                     Text(
                                       "Valuation: \$${_formatValuation(_getPlayerTeamValue(player))}M",
                                       style: const TextStyle(
                                         color: GameTheme.accent,
                                         fontWeight: FontWeight.bold,
                                         fontSize: 11,
                                       ),
                                     ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Won Players list
                          if (player.wonFootballers.isEmpty)
                            const Text(
                              "No footballers won yet",
                              style: TextStyle(color: GameTheme.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                            )
                          else
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: player.wonFootballers.map((f) {
                                final val = gameClient.realValues[f];
                                final pos = gameClient.footballerPositions[f] ?? 'Striker';
                                final tagText = val != null ? "$f ($pos - \$${val}M)" : "$f ($pos)";
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: GameTheme.secondary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: GameTheme.secondary.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    tagText,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                );
                              }).toList(),
                            )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom decoration helpers
class ItemSize {
  static const FontStyle italic = FontStyle.italic;
}
