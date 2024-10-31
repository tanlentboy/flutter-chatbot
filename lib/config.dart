import "dart:io";
import "dart:convert";
import "package:flutter/material.dart";
import "package:path_provider/path_provider.dart";

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
    model = map["model"] ?? _defaultConfig["model"];
    system = map["system"] ?? _defaultConfig["system"];
    apiUrl = map["apiUrl"] ?? _defaultConfig["apiUrl"];
    apiKey = map["apiKey"] ?? _defaultConfig["apiKey"];
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

final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  brightness: Brightness.dark,
  seedColor: Colors.indigo,
);

final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  brightness: Brightness.light,
  seedColor: Colors.indigo,
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

const codeblockDarkTheme = {
  "root":
      TextStyle(color: Color(0xffabb2bf), backgroundColor: Colors.transparent),
  "comment": TextStyle(color: Color(0xff5c6370), fontStyle: FontStyle.italic),
  "quote": TextStyle(color: Color(0xff5c6370), fontStyle: FontStyle.italic),
  "doctag": TextStyle(color: Color(0xffc678dd)),
  "keyword": TextStyle(color: Color(0xffc678dd)),
  "formula": TextStyle(color: Color(0xffc678dd)),
  "section": TextStyle(color: Color(0xffe06c75)),
  "name": TextStyle(color: Color(0xffe06c75)),
  "selector-tag": TextStyle(color: Color(0xffe06c75)),
  "deletion": TextStyle(color: Color(0xffe06c75)),
  "subst": TextStyle(color: Color(0xffe06c75)),
  "literal": TextStyle(color: Color(0xff56b6c2)),
  "string": TextStyle(color: Color(0xff98c379)),
  "regexp": TextStyle(color: Color(0xff98c379)),
  "addition": TextStyle(color: Color(0xff98c379)),
  "attribute": TextStyle(color: Color(0xff98c379)),
  "meta-string": TextStyle(color: Color(0xff98c379)),
  "built_in": TextStyle(color: Color(0xffe6c07b)),
  "attr": TextStyle(color: Color(0xffd19a66)),
  "variable": TextStyle(color: Color(0xffd19a66)),
  "template-variable": TextStyle(color: Color(0xffd19a66)),
  "type": TextStyle(color: Color(0xffd19a66)),
  "selector-class": TextStyle(color: Color(0xffd19a66)),
  "selector-attr": TextStyle(color: Color(0xffd19a66)),
  "selector-pseudo": TextStyle(color: Color(0xffd19a66)),
  "number": TextStyle(color: Color(0xffd19a66)),
  "symbol": TextStyle(color: Color(0xff61aeee)),
  "bullet": TextStyle(color: Color(0xff61aeee)),
  "link": TextStyle(color: Color(0xff61aeee)),
  "meta": TextStyle(color: Color(0xff61aeee)),
  "selector-id": TextStyle(color: Color(0xff61aeee)),
  "title": TextStyle(color: Color(0xff61aeee)),
  "emphasis": TextStyle(fontStyle: FontStyle.italic),
  "strong": TextStyle(fontWeight: FontWeight.bold),
};

const codeblockLightTheme = {
  "root":
      TextStyle(color: Color(0xff383a42), backgroundColor: Colors.transparent),
  "comment": TextStyle(color: Color(0xffa0a1a7), fontStyle: FontStyle.italic),
  "quote": TextStyle(color: Color(0xffa0a1a7), fontStyle: FontStyle.italic),
  "doctag": TextStyle(color: Color(0xffa626a4)),
  "keyword": TextStyle(color: Color(0xffa626a4)),
  "formula": TextStyle(color: Color(0xffa626a4)),
  "section": TextStyle(color: Color(0xffe45649)),
  "name": TextStyle(color: Color(0xffe45649)),
  "selector-tag": TextStyle(color: Color(0xffe45649)),
  "deletion": TextStyle(color: Color(0xffe45649)),
  "subst": TextStyle(color: Color(0xffe45649)),
  "literal": TextStyle(color: Color(0xff0184bb)),
  "string": TextStyle(color: Color(0xff50a14f)),
  "regexp": TextStyle(color: Color(0xff50a14f)),
  "addition": TextStyle(color: Color(0xff50a14f)),
  "attribute": TextStyle(color: Color(0xff50a14f)),
  "meta-string": TextStyle(color: Color(0xff50a14f)),
  "built_in": TextStyle(color: Color(0xffc18401)),
  "attr": TextStyle(color: Color(0xff986801)),
  "variable": TextStyle(color: Color(0xff986801)),
  "template-variable": TextStyle(color: Color(0xff986801)),
  "type": TextStyle(color: Color(0xff986801)),
  "selector-class": TextStyle(color: Color(0xff986801)),
  "selector-attr": TextStyle(color: Color(0xff986801)),
  "selector-pseudo": TextStyle(color: Color(0xff986801)),
  "number": TextStyle(color: Color(0xff986801)),
  "symbol": TextStyle(color: Color(0xff4078f2)),
  "bullet": TextStyle(color: Color(0xff4078f2)),
  "link": TextStyle(color: Color(0xff4078f2)),
  "meta": TextStyle(color: Color(0xff4078f2)),
  "selector-id": TextStyle(color: Color(0xff4078f2)),
  "title": TextStyle(color: Color(0xff4078f2)),
  "emphasis": TextStyle(fontStyle: FontStyle.italic),
  "strong": TextStyle(fontWeight: FontWeight.bold),
};
