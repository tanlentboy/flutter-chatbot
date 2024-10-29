import "dart:io";
import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:file_picker/file_picker.dart";
import 'package:path_provider/path_provider.dart';
import "package:flutter_markdown/flutter_markdown.dart";

void main() async {
  runApp(const MyApp());
  await Config.initialize();
}

final globalKey = GlobalKey<ScaffoldMessengerState>();

class Config {
  static String model = "";
  static String system = "";
  static String apiUrl = "";
  static String apiKey = "";

  static const defaultConfig = {
    "model": "Qwen/Qwen2-VL-72B-Instruct",
    "system": "",
    "apiUrl": "https://api.siliconflow.cn/v1/chat/completions",
    "apiKey": "",
  };

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
      _file.writeAsStringSync(jsonEncode(defaultConfig));
      _updateFrom(defaultConfig);
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

    final textField = ({label, controller}) => TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ));

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Config"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                textField(label: "Model", controller: _modelCtrl),
                SizedBox(height: 16),
                textField(label: "System", controller: _systemCtrl),
                SizedBox(height: 16),
                textField(label: "API Url", controller: _apiUrlCtrl),
                SizedBox(height: 16),
                textField(label: "API Key", controller: _apiKeyCtrl),
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const color = Colors.deepPurple;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "ChatBot",
      scaffoldMessengerKey: globalKey,
      theme: ThemeData.dark().copyWith(
        appBarTheme: AppBarTheme(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: color),
      ),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? image;
  bool sendable = true;
  final List<Message> _messages = [];
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _editCtrl = TextEditingController();

  Map<String, Object> _buildContext() {
    Map<String, Object> context = {
      "model": Config.model,
      "stream": true,
    };
    List<Map<String, Object>> list = [];

    if (Config.system.isNotEmpty) {
      list.add({"role": "system", "content": Config.system});
    }

    for (final pair in _messages.indexed) {
      final Object content;
      final index = pair.$1;
      final message = pair.$2;
      final image = message.image;

      if (index != _messages.length - 1 || image == null) {
        content = message.text;
      } else {
        content = [
          {
            "type": "image_url",
            "image_url": {"url": image},
          },
          {
            "type": "text",
            "text": message.text,
          },
        ];
      }

      list.add({"role": message.role.name, "content": content});
    }

    context["messages"] = list;
    return context;
  }

  void _clearMessage() => setState(() {
        _messages.length = 1;
      });

  void _showSettings(BuildContext context) async => await Config.show(context);

  void _scrollToBottom() => _scrollCtrl.jumpTo(
        _scrollCtrl.position.maxScrollExtent,
      );

  void _addImage(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result == null) return;

    final path = result.files.first.path;
    if (path == null) {
      return;
    }

    final bytes = await File(path).readAsBytes();
    final base64 = base64Encode(bytes);

    image = "data:image/jpeg;base64,$base64";
  }

  void _sendMessage(BuildContext context) async {
    final text = _editCtrl.text;
    if (text.isEmpty) return;

    if (Config.isEmpty) {
      await Config.show(context);
      return;
    }

    setState(() {
      sendable = false;
    });

    _messages.add(Message(role: MessageRole.user, text: text, image: image));
    final message = Message(role: MessageRole.assistant, text: "");
    final window = _buildContext();
    _messages.add(message);

    final client = http.Client();

    try {
      final request = http.Request("POST", Uri.parse(Config.apiUrl));
      request.headers["Authorization"] = "Bearer ${Config.apiKey}";
      request.headers["Content-Type"] = "application/json";
      request.body = jsonEncode(window);

      final response = await client.send(request);
      final stream = response.stream.transform(utf8.decoder);

      if (response.statusCode != 200) {
        throw Exception("bad request");
      }

      outer:
      await for (final chunk in stream) {
        final lines = LineSplitter.split(chunk).toList();

        for (final line in lines) {
          if (!line.startsWith("data:")) continue;
          final raw = line.substring(5);

          if (raw.trim() == "[DONE]") break outer;
          final json = jsonDecode(raw);

          setState(() {
            message.text += json["choices"][0]["delta"]["content"];
            _scrollToBottom();
          });
        }
      }

      _editCtrl.clear();
    } catch (e) {
      _editCtrl.text = text;
      _messages.length -= 2;
    } finally {
      client.close();
    }

    image = null;
    setState(() {
      sendable = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            itemCount: _messages.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final message = _messages[index];
              return ChatMessage(
                type: message.role,
                image: message.image,
                message: message.text,
              );
            },
          ),
        ),
        ChatInputField(
          editable: sendable,
          controller: _editCtrl,
          addImage: sendable ? _addImage : null,
          sendMessage: sendable ? _sendMessage : null,
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: _clearMessage,
            icon: const Icon(Icons.delete_outline),
          ),
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () {
                  _showSettings(context);
                },
                icon: const Icon(Icons.settings_outlined),
              );
            },
          )
        ],
        title: const Text("ChatBot"),
      ),
      body: Container(child: child),
    );
  }
}

enum MessageRole {
  assistant,
  system,
  user,
}

class Message {
  String text;
  String? image;
  MessageRole role;

  Message({required this.role, required this.text, this.image});
}

class ChatMessage extends StatelessWidget {
  final String? image;
  final String message;
  final MessageRole type;

  const ChatMessage({
    super.key,
    this.image,
    required this.type,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    var content = message;
    final Color background;
    final Alignment alignment;

    switch (type) {
      case MessageRole.user:
        alignment = Alignment.centerRight;
        background = Colors.green.shade900;
        break;

      case MessageRole.system:
        alignment = Alignment.centerRight;
        background = Colors.green.shade900;
        break;

      case MessageRole.assistant:
        alignment = Alignment.centerLeft;
        background = Colors.grey.shade900;
        break;
    }

    if (image != null) content = "![image]($image)\n\n$content";

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: background, borderRadius: BorderRadius.circular(8)),
              child: MarkdownBody(
                data: content,
                shrinkWrap: true,
                selectable: true,
                styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
              ),
            ),
          );
        },
      ),
    );
  }
}

class ChatInputField extends StatelessWidget {
  final bool editable;
  final TextEditingController controller;
  final void Function(BuildContext context)? addImage;
  final void Function(BuildContext context)? sendMessage;

  const ChatInputField({
    super.key,
    this.editable = true,
    required this.addImage,
    required this.controller,
    required this.sendMessage,
  });

  @override
  Widget build(BuildContext context) {
    void Function()? add;
    void Function()? send;

    if (addImage != null) {
      add = () {
        addImage!(context);
      };
    }

    if (sendMessage != null) {
      send = () {
        sendMessage!(context);
      };
    }

    final child = Row(
      children: [
        IconButton.filled(
          onPressed: add,
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(padding: const EdgeInsets.all(12)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            maxLines: null,
            enabled: editable,
            controller: controller,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: "Enter your message",
              contentPadding: const EdgeInsets.all(12),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: send,
          icon: const Icon(Icons.send_rounded),
          style: IconButton.styleFrom(padding: const EdgeInsets.all(12)),
        ),
      ],
    );

    return Column(
      children: [
        Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.5)),
        Padding(padding: const EdgeInsets.all(12), child: child)
      ],
    );
  }
}
