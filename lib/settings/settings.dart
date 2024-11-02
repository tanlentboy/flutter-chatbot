// This file is part of ChatBot.
//
// ChatBot is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ChatBot is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ChatBot. If not, see <https://www.gnu.org/licenses/>.

import "bot.dart";
import "api.dart";
import "../config.dart";

import "package:flutter/material.dart";

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Settings"),
          bottom: TabBar(
            tabs: [
              Tab(text: "Bot"),
              Tab(text: "APIs"),
              Tab(text: "Other"),
            ],
          ),
        ),
        body: SettingsShared(
          setState: setState,
          child: TabBarView(
            children: [
              Container(padding: EdgeInsets.all(16), child: BotWidget()),
              Container(padding: EdgeInsets.all(16), child: APIWidget()),
              Center(child: Text("Other")),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsShared extends InheritedWidget {
  final void Function(VoidCallback) setState;
  final Map<String, ApiConfig> apis = Config.apis;

  SettingsShared({
    super.key,
    required super.child,
    required this.setState,
  });

  static SettingsShared of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SettingsShared>()!;
  }

  @override
  bool updateShouldNotify(SettingsShared oldWidget) {
    return oldWidget.apis != apis;
  }
}
