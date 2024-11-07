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
import "current.dart";
import "../util.dart";
import "../config.dart";
import "../gen/l10n.dart";
import "../settings/api.dart";

import "dart:io";
import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:langchain/langchain.dart";
import "package:image_picker/image_picker.dart";
import "package:langchain_openai/langchain_openai.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_image_compress/flutter_image_compress.dart";

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? _image;
  bool _sendable = true;

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
              leading: const Icon(Icons.camera),
              title: Text(S.of(context).camera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(S.of(context).gallery),
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
        content: Text(S.of(context).image_compress_failed),
      );
    }

    final base64 = base64Encode(bytes);
    setState(() => _image = base64);
  }

  Future<void> _sendMessage(BuildContext context) async {
    final text = _editCtrl.text;
    if (text.isEmpty) return;

    final apiUrl = Current.apiUrl;
    final apiKey = Current.apiKey;
    final model = Current.model;

    if (apiUrl == null || apiKey == null || model == null) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).setup_bot_api_first),
      );
      return;
    }

    Current.messages
        .add(Message(role: MessageRole.user, text: text, image: _image));
    final message = Message(role: MessageRole.assistant, text: "");
    final messages = _buildContext(Current.messages);
    Current.messages.add(message);

    setState(() => _sendable = false);

    try {
      final llm = ChatOpenAI(
        apiKey: apiKey,
        baseUrl: apiUrl,
        defaultOptions: ChatOpenAIOptions(
          model: model,
          maxTokens: Current.maxTokens,
          temperature: Current.temperature,
        ),
      );

      if (Config.bot.stream ?? true) {
        final stream = llm.stream(PromptValue.chat(messages));
        await for (final chunk in stream) {
          final content = chunk.output.content;
          setState(() => message.text += content);
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      } else {
        final result = await llm.invoke(PromptValue.chat(messages));
        setState(() => message.text += result.output.content);
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }

      _image = null;
      _editCtrl.clear();
      await Current.save();
    } catch (e) {
      if (context.mounted) {
        Util.showSnackBar(
          context: context,
          content: Text("$e"),
          duration: const Duration(milliseconds: 1500),
        );
      }
      Current.messages.length -= 2;
    }

    setState(() => _sendable = true);
  }

  Future<void> _longPress(BuildContext context, int index) async {
    if (!_sendable) return;

    final message = Current.messages[index];
    final children = [
      ListTile(
        title: Text(S.of(context).copy),
        leading: const Icon(Icons.copy_all),
        onTap: () => Navigator.pop(context, MessageEvent.copy),
      ),
      // ListTile(
      //   title: Text(S.of(context).source),
      //   leading: const Icon(Icons.code_outlined),
      //   onTap: () => Navigator.pop(context, MessageEvent.source),
      // ),
      // ListTile(
      //   title: Text(S.of(context).edit),
      //   leading: const Icon(Icons.edit_outlined),
      //   onTap: () => Navigator.pop(context, MessageEvent.edit),
      // ),
    ];

    if (message.role == MessageRole.user) {
      children.add(
        ListTile(
          title: Text(S.of(context).delete),
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
            content: Text(S.of(context).copied_successfully),
          );
        }
        break;

      case MessageEvent.delete:
        setState(() => Current.messages.removeRange(index, index + 2));
        await Current.save();
        break;

      default:
        if (context.mounted) {
          Util.showSnackBar(
            context: context,
            content: Text(S.of(context).not_implemented_yet),
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
            padding: const EdgeInsets.all(8),
            itemCount: Current.messages.length,
            itemBuilder: (context, index) {
              final message = Current.messages[index];
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
          contentPadding: const EdgeInsets.only(left: 16, right: 8),
        ),
        Divider(),
        Container(
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Text(
            S.of(context).all_chats,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: Config.chats.length,
            itemBuilder: (context, index) {
              final chat = Config.chats[index];
              return ListTile(
                contentPadding: const EdgeInsets.only(left: 16, right: 8),
                leading: const Icon(Icons.article),
                selected: Current.chat == chat,
                title: Text(
                  chat.title,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(chat.time),
                onTap: () async {
                  if (Current.chat == chat) return;
                  await Current.load(chat);
                  setState(() {});
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    if (Current.chat == chat) Current.clear();
                    await File(Config.chatFilePath(chat.fileName)).delete();
                    Config.chats.removeAt(index);
                    await Config.save();
                    setState(() {});
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
        title: Row(children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ChatBot",
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Consumer(builder: (context, ref, child) {
                  ref.watch(apisNotifierProvider);
                  return Text(
                    Config.bot.model ?? S.of(context).no_model,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  );
                })
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.swap_vert),
            iconSize: 20,
            onPressed: () {},
          ),
        ]),
        actions: [
          IconButton(
              icon: const Icon(Icons.note_add_outlined),
              onPressed: () {
                Current.clear();
                setState(() {});
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
