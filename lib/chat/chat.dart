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
import "package:langchain/langchain.dart";
import "package:image_picker/image_picker.dart";
import "package:langchain_openai/langchain_openai.dart";
import "package:flutter_image_compress/flutter_image_compress.dart";

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? _image;
  bool _sendable = true;

  File? _currentFile;
  ChatConfig? _currentChat;
  final List<Message> _messages = [];

  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _editCtrl = TextEditingController();

  Future<void> _addImage(BuildContext context) async {
    if (_image != null) {
      return setState(() => _image = null);
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
    setState(() => _image = base64);
  }

  Future<void> _saveChat() async {
    if (_currentChat == null) {
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch.toString();

      final time = Util.formatDateTime(now);
      final title = _messages.first.text;
      final fileName = "$timestamp.json";

      final chat = ChatConfig(
        time: time,
        title: title,
        fileName: fileName,
      );
      _currentChat = chat;

      final filePath = Config.chatFilePath(fileName);
      _currentFile = File(filePath);

      setState(() => Config.chats.add(chat));
      Config.save();
    }

    await _currentFile!.writeAsString(jsonEncode(_messages));
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

    setState(() => _sendable = false);

    _messages.add(Message(role: MessageRole.user, text: text, image: _image));
    final message = Message(role: MessageRole.assistant, text: "");
    final messages = _buildContext(_messages);
    _messages.add(message);

    try {
      final llm = ChatOpenAI(
        apiKey: Config.apiKey!,
        baseUrl: Config.apiUrl!,
        defaultOptions: ChatOpenAIOptions(
          model: Config.bot.model,
          maxTokens: Config.bot.maxTokens,
          temperature: Config.bot.temperature,
        ),
      );

      final stream = llm.stream(PromptValue.chat(messages));

      await for (final chunk in stream) {
        final content = chunk.output.content;
        setState(() => message.text += content);
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }

      _image = null;
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
    }

    setState(() => _sendable = true);
  }

  Future<void> _longPress(BuildContext context, int index) async {
    if (!_sendable) return;

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
        await _saveChat();
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
          editable: _sendable,
          controller: _editCtrl,
          files: _image != null ? 1 : 0,
          addImage: _sendable ? _addImage : null,
          sendMessage: _sendable ? _sendMessage : null,
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
        ),
        Divider(),
        Container(
          alignment: Alignment.topLeft,
          padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child:
              Text("All Chats", style: Theme.of(context).textTheme.labelSmall),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: Config.chats.length,
            itemBuilder: (context, index) {
              final chat = Config.chats[index];
              return ListTile(
                contentPadding: EdgeInsets.only(left: 16, right: 8),
                leading: const Icon(Icons.article),
                selected: _currentChat == chat,
                title: Text(
                  chat.title,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(chat.time),
                onTap: () async {
                  if (_currentChat == chat) return;
                  _messages.clear();

                  final file = File(Config.chatFilePath(chat.fileName));
                  _currentFile = file;
                  _currentChat = chat;

                  final json = jsonDecode(await file.readAsString());
                  for (final message in json) {
                    _messages.add(Message.fromJson(message));
                  }

                  setState(() => _image = null);
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    if (_currentChat == chat) {
                      _currentChat = null;
                      _currentFile = null;
                      _messages.clear();
                      _image = null;
                    }

                    await File(Config.chatFilePath(chat.fileName)).delete();
                    setState(() => Config.chats.removeAt(index));
                    await Config.save();
                  },
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
              icon: const Icon(Icons.note_add_outlined),
              onPressed: () {
                _messages.clear();
                _currentChat = null;
                _currentFile = null;
                setState(() => _image = null);
              }),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
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

List<ChatMessage> _buildContext(List<Message> list) {
  final context = <ChatMessage>[];

  if (Config.bot.systemPrompts != null) {
    context.add(ChatMessage.system(Config.bot.systemPrompts!));
  }

  for (final item in list) {
    switch (item.role) {
      case MessageRole.assistant:
        context.add(ChatMessage.ai(item.text));
        break;

      case MessageRole.user:
        if (item.image == null) {
          context.add(ChatMessage.humanText(item.text));
        } else {
          context.add(ChatMessage.human(ChatMessageContent.multiModal([
            ChatMessageContent.text(item.text),
            ChatMessageContent.image(
              mimeType: "image/jpeg",
              data: item.image!,
            ),
          ])));
        }
    }
  }

  return context;
}
