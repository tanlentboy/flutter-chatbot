import "dart:io";
import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:file_picker/file_picker.dart";
import "package:flutter_markdown/flutter_markdown.dart";

const String model = "Qwen/Qwen2-VL-72B-Instruct";
const String system = "你是一个人工智能助手，你的任务是解答用户的问题。";
const String apiURL = "https://api.siliconflow.cn/v1/chat/completions";
const String apiKEY = "sk-scqmbpaiugxfnwxgkwbcornphzgebmcftevknhpkiuddohiw";

void main() => runApp(const MyApp());
final globalKey = GlobalKey<ScaffoldMessengerState>();

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
  final List<Message> _messages = [
    Message(role: MessageRole.system, text: system)
  ];
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _editCtrl = TextEditingController();

  Map<String, Object> _buildContext() {
    Map<String, Object> context = {
      "model": model,
      "stream": true,
    };
    List<Map<String, Object>> list = [];

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

  void _scrollToBottom() => _scrollCtrl.jumpTo(
        _scrollCtrl.position.maxScrollExtent,
      );

  void _addFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result == null) return;

    final path = result.files.first.path;
    if (path == null) {
      globalKey.currentState?.showSnackBar(
        SnackBar(content: const Text("failed to pick file")),
      );
      return;
    }

    final bytes = await File(path).readAsBytes();
    final base64 = base64Encode(bytes);

    image = "data:image/jpeg;base64,$base64";
  }

  void _sendMessage() async {
    final text = _editCtrl.text;
    if (text.isEmpty) return;

    setState(() {
      sendable = false;
    });

    _messages.add(Message(role: MessageRole.user, text: text, image: image));
    final message = Message(role: MessageRole.assistant, text: "");
    final context = _buildContext();
    _messages.add(message);

    final client = http.Client();

    try {
      final request = http.Request("POST", Uri.parse(apiURL));
      request.headers["Content-Type"] = "application/json";
      request.headers["Authorization"] = "Bearer $apiKEY";
      request.body = jsonEncode(context);

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
          addFile: sendable ? _addFile : null,
          onSend: sendable ? _sendMessage : null,
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: _clearMessage,
            icon: const Icon(Icons.delete),
          )
        ],
        title: const Text("ChatBot"),
      ),
      body: Container(child: child),
    );
  }
}

enum MessageType {
  image,
  text,
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
  final void Function()? onSend;
  final void Function()? addFile;
  final TextEditingController controller;

  const ChatInputField({
    super.key,
    this.editable = true,
    required this.onSend,
    required this.addFile,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      children: [
        IconButton.filled(
          onPressed: addFile,
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
          onPressed: onSend,
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
