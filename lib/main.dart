import "config.dart";
import "chat/chat.dart";
import "package:flutter/material.dart";

void main() async {
  runApp(const App());
  await Config.initialize();
}

class App extends StatelessWidget {
  const App({super.key});
  static const color = Colors.deepPurple;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: color,
    );

    return MaterialApp(
      title: "ChatBot",
      theme: ThemeData.dark().copyWith(
        colorScheme: colorScheme,
        appBarTheme: AppBarTheme(color: color),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: colorScheme.surface,
        ),
      ),
      home: const ChatPage(),
    );
  }
}
