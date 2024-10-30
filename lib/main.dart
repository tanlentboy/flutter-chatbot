import "config.dart";
import "chat/chat.dart";
import "package:flutter/material.dart";

void main() async {
  runApp(const App());
  await Config.initialize();
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "ChatBot",
      theme: ThemeData.dark().copyWith(
        colorScheme: colorScheme,
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: colorScheme.surface,
        ),
        appBarTheme: AppBarTheme(color: colorScheme.primaryContainer),
      ),
      home: const ChatPage(),
    );
  }
}
