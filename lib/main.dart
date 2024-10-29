import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:flutter_markdown/flutter_markdown.dart";

const String model = "Qwen/Qwen2.5-72B-Instruct";
const String system = "你是一个人工智能助手，你的任务是解答用户的问题。";
const String apiURL = "https://api.siliconflow.cn/v1/chat/completions";
const String apiKEY = "sk-ffkekuryoenqamomygnrokbbvcrcaqafuboylsladfekfstd";

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  final color = Colors.deepPurple;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "ChatBot",
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: color),
        appBarTheme: AppBarTheme(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
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
  bool sendable = true;
  final List<Message> _messages = [
    Message(type: MessageType.system, text: system)
  ];
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _editCtrl = TextEditingController();

  Map<String, Object> _buildContext() {
    Map<String, Object> context = {
      "model": model,
      "stream": true,
    };
    List<Map<String, String>> list = [];

    for (final message in _messages) {
      list.add({"role": message.type.name, "content": message.text});
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

  void _sendMessage() async {
    final text = _editCtrl.text;
    if (text.trim().isEmpty) return;

    setState(() {
      sendable = false;
    });

    final message = Message(type: MessageType.assistant, text: "");
    _messages.add(Message(type: MessageType.user, text: text));
    _messages.add(message);

    final client = http.Client();

    try {
      final request = http.Request("POST", Uri.parse(apiURL));
      request.headers["Content-Type"] = "application/json";
      request.headers["Authorization"] = "Bearer $apiKEY";
      request.body = jsonEncode(_buildContext());

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

    setState(() {
      sendable = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    var child = Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            itemCount: _messages.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final message = _messages[index];
              return ChatMessage(
                type: message.type,
                message: message.text,
              );
            },
          ),
        ),
        ChatInputField(
          editable: sendable,
          controller: _editCtrl,
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
  assistant,
  system,
  user,
}

class Message {
  String text;
  final MessageType type;
  Message({required this.type, required this.text});
}

class ChatMessage extends StatelessWidget {
  final String message;
  final MessageType type;

  const ChatMessage({
    super.key,
    required this.type,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Alignment alignment;

    switch (type) {
      case MessageType.user:
        alignment = Alignment.centerRight;
        background = Colors.green.shade900;
        break;

      case MessageType.system:
        alignment = Alignment.centerRight;
        background = Colors.green.shade900;
        break;

      case MessageType.assistant:
        alignment = Alignment.centerLeft;
        background = Colors.grey.shade900;
        break;
    }

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
                data: message,
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
  final Function()? onSend;
  final TextEditingController controller;

  const ChatInputField({
    super.key,
    this.editable = true,
    required this.onSend,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    var child = Row(
      children: [
        Expanded(
          child: TextField(
            maxLines: null,
            enabled: editable,
            controller: controller,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: 'Enter your message',
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
