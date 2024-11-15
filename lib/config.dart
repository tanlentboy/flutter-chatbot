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

import "chat/current.dart";

import "dart:io";
import "dart:convert";
import "package:flutter/material.dart";
import "package:path_provider/path_provider.dart";
import "package:flutter_highlighter/themes/atom-one-dark.dart";
import "package:flutter_highlighter/themes/atom-one-light.dart";

class CoreConfig {
  String? bot;
  String? api;
  String? model;

  CoreConfig({
    this.bot,
    this.api,
    this.model,
  });

  Map<String, String?> toJson() => {
        "bot": bot,
        "api": api,
        "model": model,
      };

  factory CoreConfig.fromJson(Map<String, dynamic> json) => CoreConfig(
        bot: json["bot"],
        api: json["api"],
        model: json["model"],
      );
}

class ChatConfig {
  String time;
  String title;
  String fileName;

  ChatConfig({
    required this.time,
    required this.title,
    required this.fileName,
  });

  Map<String, String> toJson() => {
        "time": time,
        "title": title,
        "fileName": fileName,
      };

  factory ChatConfig.fromJson(Map<String, dynamic> json) => ChatConfig(
        time: json["time"],
        title: json["title"],
        fileName: json["fileName"],
      );
}

class BotConfig {
  bool? stream;
  int? maxTokens;
  double? temperature;
  String? systemPrompts;

  BotConfig({
    this.stream,
    this.maxTokens,
    this.temperature,
    this.systemPrompts,
  });

  Map<String, dynamic> toJson() => {
        "stream": stream,
        "maxTokens": maxTokens,
        "temperature": temperature,
        "systemPrompts": systemPrompts,
      };

  factory BotConfig.fromJson(Map<String, dynamic> json) => BotConfig(
        stream: json["stream"],
        maxTokens: json["maxTokens"],
        temperature: json["temperature"],
        systemPrompts: json["systemPrompts"],
      );
}

class ApiConfig {
  String url;
  String key;
  List<String> models;

  ApiConfig({
    required this.url,
    required this.key,
    required this.models,
  });

  Map<String, Object> toJson() => {
        "url": url,
        "key": key,
        "models": models,
      };

  factory ApiConfig.fromJson(Map<String, dynamic> json) => ApiConfig(
        url: json["url"],
        key: json["key"],
        models: json["models"].cast<String>(),
      );
}

class Config {
  static late final CoreConfig core;
  static final List<ChatConfig> chats = [];
  static final Map<String, BotConfig> bots = {};
  static final Map<String, ApiConfig> apis = {};

  static late final File _file;
  static late final String _filePath;
  static late final Directory _directory;
  static const String _fileName = "settings.json";

  static Future<void> initialize() async {
    _directory = (await getExternalStorageDirectory())!;
    _filePath = "${_directory.path}${Platform.pathSeparator}$_fileName";

    _file = File(_filePath);
    if (await _file.exists()) {
      final data = await _file.readAsString();
      fromJson(jsonDecode(data));
    } else {
      core = CoreConfig();
      save();
    }

    CurrentChat.core = core;
  }

  static Future<void> save() async =>
      await _file.writeAsString(jsonEncode(toJson()));
  static String chatFilePath(String fileName) =>
      "${_directory.path}${Platform.pathSeparator}$fileName";

  static Map<String, dynamic> toJson() => {
        "core": core,
        "bots": bots,
        "apis": apis,
        "chats": chats,
      };

  static void fromJson(Map<String, dynamic> json) {
    final coreJson = json["core"] ?? {};
    final botsJson = json["bots"] ?? {};
    final apisJson = json["apis"] ?? {};
    final chatsJson = json["chats"] ?? [];

    core = CoreConfig.fromJson(coreJson);
    for (final chat in chatsJson) {
      chats.add(ChatConfig.fromJson(chat));
    }
    for (final pair in botsJson.entries) {
      bots[pair.key] = BotConfig.fromJson(pair.value);
    }
    for (final pair in apisJson.entries) {
      apis[pair.key] = ApiConfig.fromJson(pair.value);
    }
  }
}

const _baseColor = Colors.indigo;

final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  brightness: Brightness.dark,
  seedColor: _baseColor,
);

final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  brightness: Brightness.light,
  seedColor: _baseColor,
);

final darkTheme = ThemeData.dark(useMaterial3: true).copyWith(
  colorScheme: darkColorScheme,
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: darkColorScheme.surface,
  ),
  appBarTheme: AppBarTheme(color: darkColorScheme.primaryContainer),
);

final lightTheme = ThemeData.light(useMaterial3: true).copyWith(
  colorScheme: lightColorScheme,
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: lightColorScheme.surface,
  ),
  appBarTheme: AppBarTheme(color: lightColorScheme.primaryContainer),
);

final codeDarkTheme = Map.of(atomOneDarkTheme)
  ..["root"] =
      TextStyle(color: Color(0xffabb2bf), backgroundColor: Colors.transparent);

final codeLightTheme = Map.of(atomOneLightTheme)
  ..["root"] =
      TextStyle(color: Color(0xffabb2bf), backgroundColor: Colors.transparent);
