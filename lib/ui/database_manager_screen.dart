import 'package:flutter/material.dart';
import '../network/game_db.dart';
import 'theme.dart';

class DatabaseManagerScreen extends StatefulWidget {
  const DatabaseManagerScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseManagerScreen> createState() => _DatabaseManagerScreenState();
}

class _DatabaseManagerScreenState extends State<DatabaseManagerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GameDatabase _db = GameDatabase.instance;
  List<FootballerDbEntry> _filteredEntries = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _refreshList();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _refreshList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshList() {
    final all = _db.entries.values.toList();
    // Sort alphabetically by default
    all.sort((a, b) => a.name.compareTo(b.name));
    
    if (_searchQuery.isEmpty) {
      _filteredEntries = all;
    } else {
      _filteredEntries = all
          .where((e) => e.name.toLowerCase().contains(_searchQuery))
          .toList();
    }
  }

  Future<void> _showEditDialog(FootballerDbEntry entry) async {
    final controller = TextEditingController(
      text: entry.customValue?.toString() ?? '',
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit ${entry.name} Value"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Position: ${entry.position}", style: const TextStyle(color: GameTheme.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("Base Value: \$${entry.baseValue}M", style: const TextStyle(color: GameTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(
              entry.bidsHistory.isEmpty
                  ? "Bidding History: No previous bids"
                  : "Bidding History: ${entry.bidsHistory.join(', ')} (Avg: \$${_db.getRealValue(entry.name)}M)",
              style: const TextStyle(color: GameTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              "CUSTOM OVERRIDE VALUE (MILLIONS)",
              style: TextStyle(color: GameTheme.primary, fontWeight: FontWeight.bold, fontSize: 11),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "e.g., 100",
                prefixText: "\$",
                suffixText: "M",
              ),
            ),
          ],
        ),
        actions: [
          if (entry.customValue != null)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _db.updateCustomValue(entry.name, null);
                setState(() {
                  _refreshList();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Cleared custom override for ${entry.name}")),
                );
              },
              child: const Text("CLEAR OVERRIDE", style: TextStyle(color: GameTheme.error)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = int.tryParse(controller.text.trim());
              if (val == null || val <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a valid positive number")),
                );
                return;
              }
              Navigator.pop(context);
              await _db.updateCustomValue(entry.name, val);
              setState(() {
                _refreshList();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Set custom value of ${entry.name} to \$${val}M")),
              );
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }

  final List<String> _positions = const [
    'Full Back',
    'Center Back',
    'Winger',
    'Center Mid',
    'Striker',
  ];

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    final ratingController = TextEditingController(text: '80');
    String selectedPosition = 'Striker';

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Add New Footballer"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("FOOTBALLER NAME", style: TextStyle(color: GameTheme.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: "e.g., Erling Haaland",
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("POSITION", style: TextStyle(color: GameTheme.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedPosition,
                      dropdownColor: GameTheme.surface,
                      items: _positions.map((pos) {
                        return DropdownMenuItem<String>(
                          value: pos,
                          child: Text(pos, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setStateDialog(() {
                            selectedPosition = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text("BASE VALUE RATING (MILLIONS)", style: TextStyle(color: GameTheme.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ratingController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: "80",
                        prefixText: "\$",
                        suffixText: "M",
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final baseVal = int.tryParse(ratingController.text.trim()) ?? 80;
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a valid name")),
                      );
                      return;
                    }
                    if (_db.entries.containsKey(name)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("$name already exists in database")),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    await _db.addFootballer(name, selectedPosition, baseVal);
                    setState(() {
                      _refreshList();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Added $name ($selectedPosition) with Base value \$${baseVal}M")),
                    );
                  },
                  child: const Text("ADD"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Database Manager",
          style: TextStyle(fontWeight: FontWeight.bold, color: GameTheme.textPrimary),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: GameTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: GameTheme.darkGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: "Search Footballers...",
                    prefixIcon: Icon(Icons.search, color: GameTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 16),

                // List of footballers
                Expanded(
                  child: _filteredEntries.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty ? "Database is empty." : "No matching footballers.",
                            style: const TextStyle(color: GameTheme.textMuted),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _filteredEntries.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final entry = _filteredEntries[index];
                            final realVal = _db.getRealValue(entry.name);
                            final hasOverride = entry.customValue != null;
                            final hasHistory = entry.bidsHistory.isNotEmpty;

                            return GestureDetector(
                              onTap: () => _showEditDialog(entry),
                              child: GlassCard(
                                fillColor: hasOverride
                                    ? GameTheme.primary.withOpacity(0.05)
                                    : GameTheme.surface.withOpacity(0.4),
                                borderColor: hasOverride
                                    ? GameTheme.primary.withOpacity(0.3)
                                    : const Color(0x1F94A3B8),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                entry.name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: GameTheme.secondary.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  entry.position,
                                                  style: const TextStyle(color: GameTheme.secondary, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          // Details row
                                          Row(
                                            children: [
                                              Text("Base: \$${entry.baseValue}M", style: const TextStyle(color: GameTheme.textMuted, fontSize: 12)),
                                              if (hasHistory) ...[
                                                const SizedBox(width: 10),
                                                Text(
                                                  "Avg Bid: \$${(entry.bidsHistory.reduce((a,b)=>a+b)/entry.bidsHistory.length).round()}M",
                                                  style: const TextStyle(color: GameTheme.textMuted, fontSize: 12),
                                                ),
                                              ]
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: hasOverride 
                                                ? GameTheme.primary.withOpacity(0.15) 
                                                : GameTheme.secondary.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: hasOverride ? GameTheme.primary : GameTheme.secondary,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            "\$${realVal}M",
                                            style: TextStyle(
                                              color: hasOverride ? GameTheme.primary : GameTheme.secondary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        if (hasOverride)
                                          const Padding(
                                            padding: EdgeInsets.only(top: 4, right: 2),
                                            child: Text(
                                              "Override Set",
                                              style: TextStyle(color: GameTheme.primary, fontSize: 9, fontWeight: FontWeight.bold),
                                            ),
                                          )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
