import "dart:io";
import "dart:convert";
import "package:flutter/material.dart";
import 'package:path_provider/path_provider.dart';

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

  static late final File _file;
  static late final String _filePath;
  static late final Directory _directory;
  static const _fileName = "config.json";

  static initialize() async {
    _directory = await getApplicationDocumentsDirectory();
    _filePath = "${_directory.path}${Platform.pathSeparator}$_fileName";

    _file = File(_filePath);
    if (_file.existsSync()) {
      final data = _file.readAsStringSync();
      _updateFrom(jsonDecode(data));
    } else {
      _file.writeAsStringSync(jsonEncode(_defaultConfig));
      _updateFrom(_defaultConfig);
    }
  }

  static void _updateFrom(Map<String, dynamic> map) {
    model = map["model"] ?? "";
    system = map["system"] ?? "";
    apiUrl = map["apiUrl"] ?? "";
    apiKey = map["apiKey"] ?? "";
  }

  static bool get isEmpty {
    return model.isEmpty || apiUrl.isEmpty || apiKey.isEmpty;
  }

  static bool get isNotEmpty {
    return model.isNotEmpty && apiUrl.isNotEmpty && apiKey.isNotEmpty;
  }

  static void save() {
    final configMap = <String, String>{
      "model": model,
      "system": system,
      "apiUrl": apiUrl,
      "apiKey": apiKey,
    };
    _file.writeAsStringSync(jsonEncode(configMap));
  }

  static final _modelCtrl = TextEditingController();
  static final _systemCtrl = TextEditingController();
  static final _apiUrlCtrl = TextEditingController();
  static final _apiKeyCtrl = TextEditingController();

  static show(BuildContext context) async {
    _modelCtrl.text = model;
    _systemCtrl.text = system;
    _apiUrlCtrl.text = apiUrl;
    _apiKeyCtrl.text = apiKey;

    return showDialog(
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
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Save"),
              onPressed: () {
                model = _modelCtrl.text;
                system = _systemCtrl.text;
                apiUrl = _apiUrlCtrl.text;
                apiKey = _apiKeyCtrl.text;

                save();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
