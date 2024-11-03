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

import "input.dart";
import "message.dart";
import "../config.dart";

import "dart:io";
import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:http/http.dart" as http;
import "package:image_picker/image_picker.dart";
import "package:flutter_image_compress/flutter_image_compress.dart";

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? image;
  bool sendable = true;
  final List<Message> _messages = [];
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _editCtrl = TextEditingController();

  void _addImage(BuildContext context) async {
    if (image != null) {
      return setState(() => image = null);
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              title: const Text("Camera"),
              leading: const Icon(Icons.camera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              title: const Text("Gallery"),
              leading: const Icon(Icons.photo_library),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        );
      },
    );
    if (source == null) return;

    final result = await _picker.pickImage(source: source);
    if (result == null) return;

    final compressed = await FlutterImageCompress.compressWithFile(result.path,
        quality: 60, minWidth: 1024, minHeight: 1024);
    Uint8List bytes = compressed ?? await File(result.path).readAsBytes();

    if (compressed == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text("Failed to comprese image"),
          dismissDirection: DismissDirection.horizontal,
        ),
      );
    }

    final base64 = base64Encode(bytes);
    setState(() => image = "data:image/jpeg;base64,$base64");
  }

  void _sendMessage(BuildContext context) async {
    if (Config.isNotOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text("Set up the Bot and API first"),
          dismissDirection: DismissDirection.horizontal,
        ),
      );
      return;
    }

    final text = _editCtrl.text;
    if (text.isEmpty) return;

    setState(() => sendable = false);

    _messages.add(Message(role: MessageRole.user, text: text, image: image));
    final message = Message(role: MessageRole.assistant, text: "");
    final window = _buildContext(_messages);
    _messages.add(message);

    final client = http.Client();

    try {
      final request = http.Request("POST", Uri.parse(Config.apiUrl!));
      request.headers["Authorization"] = "Bearer ${Config.apiKey}";
      request.headers["Content-Type"] = "application/json";
      request.body = jsonEncode(window);

      final response = await client.send(request);
      final stream = response.stream.transform(utf8.decoder);

      if (response.statusCode != 200) {
        throw "${response.statusCode} ${await stream.join()}";
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
          });
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      }

      _editCtrl.clear();
      image = null;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$e"),
            behavior: SnackBarBehavior.floating,
            dismissDirection: DismissDirection.horizontal,
          ),
        );
      }
      _messages.length -= 2;
    } finally {
      client.close();
    }

    setState(() => sendable = true);
  }

  Future<void> _longPress(BuildContext context, int index) async {
    if (!sendable) return;

    final message = _messages[index];
    final children = [
      ListTile(
        title: const Text("Copy"),
        leading: const Icon(Icons.copy),
        onTap: () => Navigator.pop(context, MessageEvent.copy),
      ),
      ListTile(
        title: const Text("Edit"),
        leading: const Icon(Icons.edit_outlined),
        onTap: () => Navigator.pop(context, MessageEvent.edit),
      ),
      ListTile(
        title: const Text("Source"),
        leading: const Icon(Icons.code),
        onTap: () => Navigator.pop(context, MessageEvent.source),
      ),
    ];

    if (message.role == MessageRole.user) {
      children.add(
        ListTile(
          title: const Text("Delete"),
          leading: const Icon(Icons.delete_outlined),
          onTap: () => Navigator.pop(context, MessageEvent.delete),
        ),
      );
    }

    final event = await showModalBottomSheet<MessageEvent>(
      context: context,
      builder: (BuildContext context) {
        return Wrap(children: children);
      },
    );
    if (event == null) return;

    switch (event) {
      case MessageEvent.copy:
        await Clipboard.setData(ClipboardData(text: message.text));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text("Copied Successfully"),
            duration: Duration(milliseconds: 500),
            dismissDirection: DismissDirection.horizontal,
          ));
        }
        break;

      case MessageEvent.delete:
        setState(() => _messages.removeRange(index, index + 2));
        break;

      default:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text("Not implemented yet."),
            duration: Duration(milliseconds: 500),
            dismissDirection: DismissDirection.horizontal,
          ));
        }
        break;
    }
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
              return MessageWidget(
                message: message,
                longPress: () async => await _longPress(context, index),
              );
            },
          ),
        ),
        InputWidget(
          editable: sendable,
          controller: _editCtrl,
          files: image != null ? 1 : 0,
          addImage: sendable ? _addImage : null,
          sendMessage: sendable ? _sendMessage : null,
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                image = null;
                _messages.length = 0;
              });
            },
            icon: const Icon(Icons.delete),
          ),
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.of(context).pushNamed("/settings"),
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

Map<String, Object> _buildContext(List<Message> messages) {
  Map<String, Object> context = {
    "model": Config.bot.model!,
    "stream": true,
  };
  if (Config.bot.maxTokens != null) {
    context["max_tokens"] = Config.bot.maxTokens!;
  }
  if (Config.bot.temperature != null) {
    context["temperature"] = Config.bot.temperature!;
  }

  List<Map<String, Object>> list = [];
  if (Config.bot.systemPrompts != null) {
    list.add({"role": "system", "content": Config.bot.systemPrompts!});
  }

  for (final pair in messages.indexed) {
    final Object content;
    final index = pair.$1;
    final message = pair.$2;
    final image = message.image;

    if (index != messages.length - 1 || image == null) {
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
