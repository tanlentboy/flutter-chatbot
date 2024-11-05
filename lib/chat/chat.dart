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
import "package:image_picker/image_picker.dart";
import "package:openai_dart/openai_dart.dart" as openai;
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
    if (currentChat == null) {
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
      currentChat = chat;

      final filePath = Config.chatFilePath(fileName);
      currentFile = File(filePath);

      setState(() => Config.chats.add(chat));
      Config.save();
    }

    await currentFile!.writeAsString(jsonEncode(_messages));
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
    final request = _createRequest(_messages);
    _messages.add(message);

    try {
      final client = openai.OpenAIClient(
        baseUrl: Config.apiUrl,
        apiKey: Config.apiKey,
      );

      final stream = client.createChatCompletionStream(request: request);

      await for (final chunk in stream) {
        final content = chunk.choices.first.delta.content;
        if (content != null) setState(() => message.text += content);
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
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
                selected: currentChat == chat,
                title: Text(
                  chat.title,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(chat.time),
                onTap: () async {
                  if (currentChat == chat) return;
                  _messages.clear();

                  final file = File(Config.chatFilePath(chat.fileName));
                  currentFile = file;
                  currentChat = chat;

                  final json = jsonDecode(await file.readAsString());
                  for (final message in json) {
                    _messages.add(Message.fromJson(message));
                  }

                  setState(() => image = null);
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    if (currentChat == chat) {
                      currentChat = null;
                      currentFile = null;
                      _messages.clear();
                      image = null;
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
                currentChat = null;
                currentFile = null;
                setState(() => image = null);
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

openai.CreateChatCompletionRequest _createRequest(List<Message> list) {
  final messages = <openai.ChatCompletionMessage>[];

  if (Config.bot.systemPrompts != null) {
    messages.add(
      openai.ChatCompletionMessage.system(content: Config.bot.systemPrompts!),
    );
  }

  for (final item in list) {
    switch (item.role) {
      case MessageRole.assistant:
        messages.add(
          openai.ChatCompletionMessage.assistant(content: item.text),
        );
        break;

      case MessageRole.user:
        if (item.image == null) {
          messages.add(
            openai.ChatCompletionMessage.user(
              content: openai.ChatCompletionUserMessageContent.string(
                item.text,
              ),
            ),
          );
        } else {
          messages.add(
            openai.ChatCompletionMessage.user(
              content: openai.ChatCompletionUserMessageContent.parts(
                [
                  openai.ChatCompletionMessageContentPart.text(
                    text: item.text,
                  ),
                  openai.ChatCompletionMessageContentPart.image(
                    imageUrl: openai.ChatCompletionMessageImageUrl(
                      url: item.image!,
                      detail: openai.ChatCompletionMessageImageDetail.auto,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
    }
  }

  final request = openai.CreateChatCompletionRequest(
    model: openai.ChatCompletionModel.modelId(Config.bot.model!),
    temperature: Config.bot.temperature,
    maxTokens: Config.bot.maxTokens,
    messages: messages,
  );

  return request;
}
