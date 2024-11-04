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
import "../util.dart";
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

  File? currentFile;
  ChatConfig? currentChat;
  final List<Message> _messages = [];

  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _editCtrl = TextEditingController();

  Future<void> _addImage(BuildContext context) async {
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
      Util.showSnackBar(
        context: context,
        content: const Text("Failed to comprese image"),
      );
    }

    final base64 = base64Encode(bytes);
    setState(() => image = "data:image/jpeg;base64,$base64");
  }

  Future<void> _saveChat() async {
    if (currentChat == null || currentFile == null) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final filePath = Config.chatFilePath(fileName);

      currentChat = ChatConfig(
        time: DateTime.now().toString(),
        title: _messages[0].text,
        fileName: fileName,
      );
      currentFile = File(filePath);

      setState(() => Config.chats.add(currentChat!));
    }
  }

  Future<void> _sendMessage(BuildContext context) async {
    if (Config.isNotOk) {
      Util.showSnackBar(
        context: context,
        content: const Text("Set up the Bot and API first"),
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

      image = null;
      _editCtrl.clear();
      await _saveChat();
    } catch (e) {
      if (context.mounted) {
        Util.showSnackBar(
          context: context,
          content: Text("$e"),
          duration: const Duration(milliseconds: 1500),
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
        leading: const Icon(Icons.copy_all),
        onTap: () => Navigator.pop(context, MessageEvent.copy),
      ),
      // ListTile(
      //   title: const Text("Edit"),
      //   leading: const Icon(Icons.edit_outlined),
      //   onTap: () => Navigator.pop(context, MessageEvent.edit),
      // ),
      // ListTile(
      //   title: const Text("Source"),
      //   leading: const Icon(Icons.code_outlined),
      //   onTap: () => Navigator.pop(context, MessageEvent.source),
      // ),
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
          Util.showSnackBar(
            context: context,
            content: const Text("Copied Successfully"),
          );
        }
        break;

      case MessageEvent.delete:
        setState(() => _messages.removeRange(index, index + 2));
        break;

      default:
        if (context.mounted) {
          Util.showSnackBar(
            context: context,
            content: Text("Not implemented yet"),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
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

    final drawer = Column(
      children: [
        ListTile(
          title: Text(
            "ChatBot",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          contentPadding: EdgeInsets.only(left: 16, right: 8),
          trailing: IconButton(
            icon: Icon(Icons.add),
            onPressed: () {},
          ),
        ),
        Divider(),
        ListTile(
          title: Text(
            "All Chats",
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: Config.chats.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.message),
                title: Text(Config.chats[index].title),
                onTap: () {},
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {},
                ),
              );
            },
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("ChatBot"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => setState(() {
              image = null;
              _messages.length = 0;
            }),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed("/settings"),
          ),
        ],
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: SafeArea(child: drawer),
      ),
      body: body,
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
