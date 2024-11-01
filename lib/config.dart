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

const _baseColor = Colors.indigo;

const _defaultConfig = {
  "model": "Qwen/Qwen2-VL-72B-Instruct",
  "system": "",
  "apiUrl": "https://api.siliconflow.cn/v1/chat/completions",
  "apiKey": "",
};

class Config {
  static String model = "";
  static String system = "";
  static String apiUrl = "";
  static String apiKey = "";
  static int maxTokens = 1024;
  static num temperature = 0.7;

  static late final File _file;
  static late final String _filePath;
  static late final Directory _directory;
  static const String _fileName = "config.json";

  static bool get isOk {
    return model.isEmpty || apiUrl.isEmpty || apiKey.isEmpty;
  }

  static bool get isNotOk {
    return model.isNotEmpty && apiUrl.isNotEmpty && apiKey.isNotEmpty;
  }

  static initialize() async {
    _directory = await getApplicationDocumentsDirectory();
    _filePath = "${_directory.path}${Platform.pathSeparator}$_fileName";

    _file = File(_filePath);
    if (await _file.exists()) {
      final data = await _file.readAsString();
      _updateFrom(jsonDecode(data));
    } else {
      await _file.writeAsString(jsonEncode(_defaultConfig));
      _updateFrom(_defaultConfig);
    }
  }

  static void _updateFrom(Map<String, dynamic> map) {
    model = map["model"] ?? _defaultConfig["model"];
    system = map["system"] ?? _defaultConfig["system"];
    apiUrl = map["apiUrl"] ?? _defaultConfig["apiUrl"];
    apiKey = map["apiKey"] ?? _defaultConfig["apiKey"];
  }

  static Future<void> save() async {
    final configMap = <String, String>{
      "model": model,
      "system": system,
      "apiUrl": apiUrl,
      "apiKey": apiKey,
    };
    await _file.writeAsString(jsonEncode(configMap));
  }

  static final _modelCtrl = TextEditingController();
  static final _systemCtrl = TextEditingController();
  static final _apiUrlCtrl = TextEditingController();
  static final _apiKeyCtrl = TextEditingController();

  static Future<void> show(BuildContext context) async {
    _modelCtrl.text = model;
    _systemCtrl.text = system;
    _apiUrlCtrl.text = apiUrl;
    _apiKeyCtrl.text = apiKey;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Settings"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _textField(labelText: "Model", controller: _modelCtrl),
                SizedBox(height: 16),
                _textField(labelText: "System", controller: _systemCtrl),
                SizedBox(height: 16),
                _textField(labelText: "API Url", controller: _apiUrlCtrl),
                SizedBox(height: 16),
                _textField(labelText: "API Key", controller: _apiKeyCtrl),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text("Save"),
              onPressed: () {
                model = _modelCtrl.text;
                system = _systemCtrl.text;
                apiUrl = _apiUrlCtrl.text;
                apiKey = _apiKeyCtrl.text;
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (result != null && result) await save();
  }
}

TextField _textField(
    {required String labelText, required TextEditingController controller}) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: labelText,
      contentPadding: const EdgeInsets.all(12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

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
