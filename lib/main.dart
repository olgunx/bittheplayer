import 'package:flutter/material.dart';
import 'network/game_db.dart';
import 'ui/role_selection_screen.dart';
import 'ui/theme.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the database
  await GameDatabase.instance.init();
  
  runApp(const BitThePlayerApp());
}

class BitThePlayerApp extends StatelessWidget {
  const BitThePlayerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bit The Player',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: GameTheme.darkTheme,
      home: const RoleSelectionScreen(),
    );
  }
}
