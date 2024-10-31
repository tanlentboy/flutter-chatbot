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
      themeMode: ThemeMode.system,
      home: const ChatPage(),
      darkTheme: darkTheme,
      theme: lightTheme,
      title: "ChatBot",
    );
  }
}
