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

import "dart:io";
import "dart:convert";
import "package:flutter/material.dart";
import "package:path_provider/path_provider.dart";
import "package:flutter_highlighter/themes/atom-one-dark.dart";
import "package:flutter_highlighter/themes/atom-one-light.dart";

class BotConfig {
  String? api;
  String? model;
  int? maxTokens;
  num? temperature;
  String? systemPrompts;
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
}

class Config {
  static final BotConfig bot = BotConfig();
  static final Map<String, ApiConfig> apis = {};

  static String? get apiUrl {
    if (bot.api == null) return null;
    return apis[bot.api]!.url;
  }

  static String? get apiKey {
    if (bot.api == null) return null;
    return apis[bot.api]!.key;
  }

  static bool get isOk {
    return bot.model != null && apiUrl != null && apiKey != null;
  }

  static bool get isNotOk {
    return bot.model == null || apiUrl == null || apiKey == null;
  }

  static void fromJson(Map<String, dynamic> json) {
    final botJson = json["bot"] as Map<String, dynamic>;
    final apisJson = json["apis"] as Map<String, dynamic>;

    bot.api = botJson["api"];
    bot.model = botJson["model"];
    bot.maxTokens = botJson["maxTokens"];
    bot.temperature = botJson["temperature"];
    bot.systemPrompts = botJson["systemPrompts"];

    for (final pair in apisJson.entries) {
      final api = pair.value as Map<String, dynamic>;
      final models = api["models"] as List<dynamic>;
      apis[pair.key] = ApiConfig(
        url: api["url"],
        key: api["key"],
        models: models.cast<String>(),
      );
    }
  }

  static Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    json["bot"] = {
      "api": bot.api,
      "model": bot.model,
      "maxTokens": bot.maxTokens,
      "temperature": bot.temperature,
      "systemPrompts": bot.systemPrompts,
    };

    final map = {};
    json["apis"] = map;

    for (final pair in apis.entries) {
      final api = pair.value;
      map[pair.key] = {
        "url": api.url,
        "key": api.key,
        "models": api.models,
      };
    }

    return json;
  }

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
      save();
    }
  }

  static Future<void> save() async {
    await _file.writeAsString(jsonEncode(toJson()));
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
