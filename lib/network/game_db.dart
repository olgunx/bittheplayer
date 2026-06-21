import 'dart:convert';
import 'dart:io';

class FootballerDbEntry {
  final String name;
  final String position;
  final int baseValue;
  int? customValue;
  List<int> bidsHistory;

  FootballerDbEntry({
    required this.name,
    required this.position,
    required this.baseValue,
    this.customValue,
    List<int>? bidsHistory,
  }) : bidsHistory = bidsHistory ?? [];

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'position': position,
      'baseValue': baseValue,
      'customValue': customValue,
      'bidsHistory': bidsHistory,
    };
  }

  factory FootballerDbEntry.fromMap(Map<String, dynamic> map) {
    return FootballerDbEntry(
      name: map['name'] as String,
      position: map['position'] as String? ?? 'Striker',
      baseValue: map['baseValue'] as int,
      customValue: map['customValue'] as int?,
      bidsHistory: List<int>.from(map['bidsHistory'] as List? ?? []),
    );
  }
}

class GameDatabase {
  static final GameDatabase instance = GameDatabase._();
  GameDatabase._();

  Map<String, FootballerDbEntry> entries = {};

  String get _dbPath {
    if (Platform.isAndroid) {
      return '/data/data/com.bittheplayer.bittheplayer/files/footballers_db.json';
    }
    return './footballers_db.json';
  }

  Future<void> init() async {
    try {
      final file = File(_dbPath);
      bool needInit = !await file.exists();
      if (!needInit) {
        await load();
        // If the database is missing our new default players (like Virgil van Dijk or Michael Olaitan), re-initialize it.
        if (!entries.containsKey('Virgil van Dijk') || !entries.containsKey('Michael Olaitan')) {
          needInit = true;
        }
      }

      if (needInit) {
        // Initialize with default footballers across 5 positions
        final defaults = {
          // Striker
          'Kylian Mbappé': {'pos': 'Striker', 'val': 92},
          'Erling Haaland': {'pos': 'Striker', 'val': 91},
          'Harry Kane': {'pos': 'Striker', 'val': 89},
          'Michael Olaitan': {'pos': 'Striker', 'val': 65},
          'Martin Braithwaite': {'pos': 'Striker', 'val': 72},
          // Winger
          'Vinícius Júnior': {'pos': 'Winger', 'val': 90},
          'Lionel Messi': {'pos': 'Winger', 'val': 90},
          'Cristiano Ronaldo': {'pos': 'Winger', 'val': 88},
          'Mohamed Salah': {'pos': 'Winger', 'val': 88},
          'Bukayo Saka': {'pos': 'Winger', 'val': 88},
          'Ademola Lookman': {'pos': 'Winger', 'val': 81},
          'Moses Simon': {'pos': 'Winger', 'val': 73},
          // Center Mid
          'Jude Bellingham': {'pos': 'Center Mid', 'val': 89},
          'Kevin De Bruyne': {'pos': 'Center Mid', 'val': 89},
          'Rodri': {'pos': 'Center Mid', 'val': 90},
          'Declan Rice': {'pos': 'Center Mid', 'val': 87},
          'Alex Iwobi': {'pos': 'Center Mid', 'val': 74},
          'Wilfred Ndidi': {'pos': 'Center Mid', 'val': 78},
          // Center Back
          'Virgil van Dijk': {'pos': 'Center Back', 'val': 90},
          'Rúben Dias': {'pos': 'Center Back', 'val': 89},
          'William Troost-Ekong': {'pos': 'Center Back', 'val': 72},
          'Kenneth Omeruo': {'pos': 'Center Back', 'val': 70},
          // Full Back
          'Achraf Hakimi': {'pos': 'Full Back', 'val': 84},
          'Alphonso Davies': {'pos': 'Full Back', 'val': 84},
          'Trent Alexander-Arnold': {'pos': 'Full Back', 'val': 85},
          'Ola Aina': {'pos': 'Full Back', 'val': 73},
          'Bright Osayi-Samuel': {'pos': 'Full Back', 'val': 72},
        };

        entries.clear();
        defaults.forEach((name, data) {
          entries[name] = FootballerDbEntry(
            name: name,
            position: data['pos'] as String,
            baseValue: data['val'] as int,
          );
        });

        await save();
      }
    } catch (e) {
      print("[Database] Init error: $e");
    }
  }

  Future<void> load() async {
    try {
      final file = File(_dbPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> list = jsonDecode(content) as List;
        entries.clear();
        for (var item in list) {
          final entry = FootballerDbEntry.fromMap(item as Map<String, dynamic>);
          entries[entry.name] = entry;
        }
      }
    } catch (e) {
      print("[Database] Load error: $e");
    }
  }

  Future<void> save() async {
    try {
      final file = File(_dbPath);
      // Ensure parent directory exists
      await file.parent.create(recursive: true);
      
      final list = entries.values.map((e) => e.toMap()).toList();
      final content = jsonEncode(list);
      await file.writeAsString(content);
    } catch (e) {
      print("[Database] Save error: $e");
    }
  }

  int getRealValue(String name) {
    final entry = entries[name];
    if (entry == null) return 50; // Fallback default for unknown players
    
    if (entry.customValue != null) {
      return entry.customValue!;
    }
    
    if (entry.bidsHistory.isNotEmpty) {
      final sum = entry.bidsHistory.reduce((a, b) => a + b);
      return (sum / entry.bidsHistory.length).round();
    }
    
    return entry.baseValue;
  }

  Future<void> recordWinningBid(String name, int bid) async {
    if (bid <= 0) return;
    
    final entry = entries[name];
    if (entry != null) {
      entry.bidsHistory.add(bid);
      await save();
    }
  }

  Future<void> updateCustomValue(String name, int? value) async {
    final entry = entries[name];
    if (entry != null) {
      entry.customValue = value;
      await save();
    }
  }

  Future<void> addFootballer(String name, String position, int baseValue) async {
    if (!entries.containsKey(name)) {
      entries[name] = FootballerDbEntry(name: name, position: position, baseValue: baseValue);
      await save();
    }
  }
}
