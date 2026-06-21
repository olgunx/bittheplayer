import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../network/discovery.dart';
import '../network/instances.dart';
import '../network/server_info.dart';
import 'database_manager_screen.dart';
import 'lobby_screen.dart';
import 'theme.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '4000');
  
  final List<ServerInfo> _discoveredServers = [];
  StreamSubscription<ServerInfo>? _discoverySubscription;
  bool _isScanning = false;
  bool _isManualOpen = false;
  String _myIp = "Resolving IP...";

  @override
  void initState() {
    super.initState();
    // Default nickname
    _nameController.text = "Player_${(100 + (DateTime.now().millisecond % 900))}";
    _resolveMyIp();
    _startScanning();
  }

  Future<void> _resolveMyIp() async {
    final ip = await gameServer.getLocalIpAddress();
    if (mounted) {
      setState(() {
        _myIp = ip ?? "No network connected";
      });
    }
  }

  @override
  void dispose() {
    _stopScanning(isDisposing: true);
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _startScanning() {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _discoveredServers.clear();
    });

    _discoverySubscription = NetworkDiscovery.discover().listen(
      (server) {
        if (!_discoveredServers.contains(server)) {
          setState(() {
            _discoveredServers.add(server);
          });
        }
      },
      onError: (err) {
        print("[UI] Discovery error: $err");
      },
    );
  }

  void _stopScanning({bool isDisposing = false}) {
    _discoverySubscription?.cancel();
    _discoverySubscription = null;
    if (!isDisposing && mounted) {
      setState(() {
        _isScanning = false;
      });
    } else {
      _isScanning = false;
    }
  }

  Future<void> _hostGame() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a nickname first!")),
      );
      return;
    }

    _stopScanning();
    
    // Start local server (only works on native platforms, not on Web)
    bool serverStarted = true;
    if (!kIsWeb) {
      serverStarted = await gameServer.start();
    }

    if (serverStarted) {
      // Connect local client
      final ip = kIsWeb ? 'localhost' : '127.0.0.1';
      await gameClient.connect(ip, 4000, name);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyScreen(isHost: !kIsWeb),
          ),
        ).then((_) => _startScanning());
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to start host server.")),
        );
        _startScanning();
      }
    }
  }

  Future<void> _joinGame(String ip, int port) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a nickname first!")),
      );
      return;
    }

    _stopScanning();
    
    // Show connecting loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    await gameClient.connect(ip, port, name);
    
    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      if (gameClient.connectionStatus == 'connected') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LobbyScreen(isHost: false),
          ),
        ).then((_) => _startScanning());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(gameClient.connectionError ?? "Connection failed.")),
        );
        _startScanning();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: !kIsWeb
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.storage, color: GameTheme.primary),
                  tooltip: "Database Manager",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DatabaseManagerScreen(),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: GameTheme.darkGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Glowing Logo & Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: GameTheme.primary.withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 10,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.sports_soccer,
                      size: 80,
                      color: GameTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "BIT THE PLAYER",
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  "Local Network Footballer Auction",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: GameTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 40),

                // Name Input Section
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "YOUR NICKNAME",
                        style: TextStyle(
                          color: GameTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person, color: GameTheme.primary),
                          hintText: "Enter Nickname",
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Host button
                if (!kIsWeb) ...[
                  GradientButton(
                    text: "HOST A NEW GAME",
                    icon: Icons.gavel,
                    onPressed: _hostGame,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your Server IP: $_myIp",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GameTheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
                if (kIsWeb)
                  const Text(
                    "Note: Web browsers can only join games, hosting requires native client.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: GameTheme.textMuted, fontSize: 12),
                  ),
                const SizedBox(height: 32),

                // Discover header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "DISCOVERED MATCHES",
                      style: TextStyle(
                        color: GameTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                    if (_isScanning)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(GameTheme.primary),
                        ),
                      )
                  ],
                ),
                const SizedBox(height: 12),

                // Discovered servers list
                if (_discoveredServers.isEmpty)
                  GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.wifi_find, size: 40, color: GameTheme.textMuted.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            "Scanning local network for servers...",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: GameTheme.textMuted),
                          ),
                          if (kIsWeb) ...[
                            const SizedBox(height: 8),
                            const Text(
                              "UDP discovery is disabled in web browsers. Use manual entry below.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: GameTheme.textMuted, fontSize: 11),
                            ),
                          ]
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _discoveredServers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final server = _discoveredServers[index];
                      return GlassCard(
                        fillColor: GameTheme.surface.withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: GameTheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.sports_esports, color: GameTheme.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${server.hostName}'s Lobby",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    "${server.ip}:${server.port}",
                                    style: const TextStyle(color: GameTheme.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            GradientButton(
                              text: "JOIN",
                              width: 80,
                              height: 38,
                              onPressed: () => _joinGame(server.ip, server.port),
                            )
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 24),

                // Manual connect section
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isManualOpen = !_isManualOpen;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isManualOpen ? "Hide Manual Connection" : "Show Manual Connection",
                          style: const TextStyle(
                            color: GameTheme.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Icon(
                          _isManualOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: GameTheme.secondary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isManualOpen) ...[
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "HOST IP ADDRESS",
                          style: TextStyle(
                            color: GameTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _ipController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            hintText: "e.g., 192.168.1.100",
                            prefixIcon: Icon(Icons.lan, color: GameTheme.textMuted),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "PORT",
                          style: TextStyle(
                            color: GameTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _portController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: "4000",
                            prefixIcon: Icon(Icons.settings_ethernet, color: GameTheme.textMuted),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GradientButton(
                          text: "CONNECT MANUALLY",
                          gradient: GameTheme.secondaryGradient,
                          onPressed: () {
                            final ip = _ipController.text.trim();
                            final portStr = _portController.text.trim();
                            final port = int.tryParse(portStr) ?? 4000;
                            if (ip.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please enter a valid IP address")),
                              );
                              return;
                            }
                            _joinGame(ip, port);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
