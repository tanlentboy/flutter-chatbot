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

import "chat.dart";
import "input.dart";
import "current.dart";
import "../util.dart";
import "../config.dart";
import "../gen/l10n.dart";
import "../markdown/all.dart";

import "dart:io";
import "dart:async";
import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:langchain/langchain.dart";
import "package:animate_do/animate_do.dart";
import "package:audioplayers/audioplayers.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "package:langchain_openai/langchain_openai.dart";

final messageProvider = NotifierProvider.autoDispose
    .family<MessageNotifier, void, Message>(MessageNotifier.new);

class MessageNotifier extends AutoDisposeFamilyNotifier<void, Message> {
  @override
  void build(Message arg) {}

  void notify() => ref.notifyListeners();
}

enum MessageRole {
  assistant,
  user;

  bool get isAssistant => this == MessageRole.assistant;
  bool get isUser => this == MessageRole.user;
}

class MessageItem {
  String text;
  String? time;
  String? model;
  String? image;
  MessageRole role;

  MessageItem({
    this.time,
    this.image,
    this.model,
    required this.role,
    required this.text,
  });

  factory MessageItem.fromJson(Map json) => switch (json["role"]) {
        "assistant" => MessageItem(
            time: json["time"],
            text: json["text"],
            model: json["model"],
            role: MessageRole.assistant,
          ),
        "user" => MessageItem(
            text: json["text"],
            image: json["image"],
            role: MessageRole.user,
          ),
        _ => throw "bad role",
      };

  Map toJson() => switch (role) {
        MessageRole.assistant => {
            "time": time,
            "text": text,
            "model": model,
            "role": role.name,
          },
        MessageRole.user => {
            "text": text,
            "image": image,
            "role": role.name,
          },
      };
}

class Message {
  int index;
  List<MessageItem> list;

  Message({
    required this.index,
    required this.list,
  });

  factory Message.fromItem(MessageItem item) => Message(index: 0, list: [item]);

  factory Message.fromJson(Map json) =>
      json["index"] == null && json["list"] == null
          ? Message(index: 0, list: [MessageItem.fromJson(json)])
          : Message(
              index: json["index"],
              list: [
                for (final item in json["list"]) MessageItem.fromJson(item),
              ],
            );

  Map toJson() => {
        "index": index,
        "list": list,
      };

  MessageItem get item => list[index];
}

class MessageWidget extends ConsumerStatefulWidget {
  final Message message;

  const MessageWidget({
    super.key,
    required this.message,
  });

  @override
  ConsumerState<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends ConsumerState<MessageWidget> {
  http.Client? ttsClient;
  http.Client? chatClient;
  static final AudioPlayer _player = AudioPlayer();

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    ref.watch(messageProvider(message));

    final item = message.item;
    var content = item.text;
    final role = item.role;

    final colorScheme = Theme.of(context).colorScheme;
    final markdownStyleSheet = MarkdownStyleSheet(
      codeblockPadding: EdgeInsets.all(0),
      codeblockDecoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        color: colorScheme.surfaceContainer,
      ),
      blockquoteDecoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        color: colorScheme.brightness == Brightness.light
            ? Colors.blueGrey.withOpacity(0.3)
            : Colors.black.withOpacity(0.3),
      ),
    );

    final background = role.isUser
        ? colorScheme.secondaryContainer
        : colorScheme.surfaceContainerHighest;

    if (item.image != null) {
      content = "![image](data:image/jpeg;base64,${item.image})\n\n$content";
    }

    return Container(
      alignment: role.isAssistant ? Alignment.topLeft : Alignment.topRight,
      child: Column(
        crossAxisAlignment: role.isAssistant
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          if (role.isAssistant) ...[
            const SizedBox(height: 12),
            _buildHeader(message, item),
          ],
          SizedBox(height: role.isAssistant ? 8 : 12),
          GestureDetector(
            onLongPress: _longPress,
            child: Container(
              padding: const EdgeInsets.all(12),
              constraints: role.isUser
                  ? BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    )
                  : null,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                  topRight: Radius.circular(role.isUser ? 2 : 16),
                ),
              ),
              child: switch (item.text.isNotEmpty) {
                true => MarkdownBody(
                    data: content,
                    shrinkWrap: true,
                    extensionSet: mdExtensionSet,
                    onTapLink: (text, href, title) =>
                        Dialogs.openLink(context: context, link: href),
                    builders: {
                      "pre": CodeBlockBuilder(context: context),
                      "latex": LatexElementBuilder(textScaleFactor: 1.2),
                    },
                    styleSheet: markdownStyleSheet,
                    styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
                  ),
                false => SizedBox(
                    width: 36,
                    height: 18,
                    child: SpinKitWave(
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              },
            ),
          ),
          if (CurrentChat.messages.lastOrNull == message &&
              CurrentChat.chatStatus.isNothing) ...[
            const SizedBox(height: 4),
            FadeIn(child: _buildToolBar(role)),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(Message message, MessageItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          child: const Icon(Icons.smart_toy),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.model ?? CurrentChat.model ?? S.of(context).model,
                style: Theme.of(context).textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                item.time ??
                    CurrentChat.chat?.time ??
                    Util.formatDateTime(DateTime.now()),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        if (message.list.length > 1) ...[
          const SizedBox(width: 4),
          if (message != CurrentChat.messages.last ||
              CurrentChat.chatStatus.isNothing) ...[
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                iconSize: 16,
                onPressed: () {
                  if (item == message.list.first) return;
                  setState(() => message.index--);
                  CurrentChat.save();
                },
              ),
            ),
            Text("${message.index + 1}/${message.list.length}"),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                iconSize: 16,
                onPressed: () {
                  if (item == message.list.last) return;
                  setState(() => message.index++);
                  CurrentChat.save();
                },
              ),
            ),
          ],
          if (message == CurrentChat.messages.last &&
              CurrentChat.chatStatus.isResponding)
            SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                icon: const Icon(Icons.pause_outlined),
                iconSize: 18,
                onPressed: _reanswer,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildToolBar(MessageRole role) {
    return Row(
      mainAxisAlignment:
          role.isAssistant ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        if (role.isAssistant) ...[
          SizedBox(
            width: 36,
            height: 26,
            child: IconButton(
              icon: Icon(switch (CurrentChat.ttsStatus) {
                TtsStatus.loading => Icons.cancel_outlined,
                TtsStatus.nothing => Icons.volume_up_outlined,
                TtsStatus.playing => Icons.pause_circle_outlined,
              }),
              iconSize: 18,
              onPressed: _tts,
              padding: EdgeInsets.zero,
            ),
          ),
          SizedBox(
            width: 36,
            height: 26,
            child: IconButton(
              icon: const Icon(Icons.sync_outlined),
              iconSize: 18,
              onPressed: _reanswer,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
        SizedBox(
          width: 36,
          height: 26,
          child: IconButton(
            icon: const Icon(Icons.paste_outlined),
            iconSize: 16,
            onPressed: _copy,
            padding: EdgeInsets.zero,
          ),
        ),
        SizedBox(
          width: 36,
          height: 26,
          child: IconButton(
            icon: const Icon(Icons.edit_outlined),
            iconSize: 18,
            onPressed: _edit,
            padding: EdgeInsets.zero,
          ),
        ),
        SizedBox(
          width: 36,
          height: 26,
          child: IconButton(
            icon: const Icon(Icons.delete_outlined),
            iconSize: 18,
            onPressed: _delete,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Future<void> _tts() async {
    if (!CurrentChat.ttsStatus.isNothing) {
      CurrentChat.ttsStatus = TtsStatus.nothing;
      ttsClient?.close();
      ttsClient = null;
      _player.stop();
      return;
    }

    final text = widget.message.item.text;
    if (text.isEmpty) return;

    final tts = Config.tts;
    final model = tts.model;
    final voice = tts.voice;
    final api = Config.apis[tts.api];

    if (model == null || voice == null || api == null) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).setup_tts_first),
      );
      return;
    }

    final apiUrl = api.url;
    final apiKey = api.key;
    final endPoint = "$apiUrl/audio/speech";

    setState(() => CurrentChat.ttsStatus = TtsStatus.loading);

    try {
      ttsClient ??= http.Client();
      final response = await ttsClient!.post(
        Uri.parse(endPoint),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": model,
          "voice": voice,
          "stream": false,
          "input": markdownToText(text),
        }),
      );

      if (response.statusCode != 200) {
        throw "${response.statusCode} ${response.body}";
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final path = Config.audioFilePath("$timestamp.mp3");

      final file = File(path);
      await file.writeAsBytes(response.bodyBytes);

      if (CurrentChat.ttsStatus.isLoading) {
        setState(() => CurrentChat.ttsStatus = TtsStatus.playing);
        await _player.play(DeviceFileSource(path));
        await _player.onPlayerStateChanged.first;
      }
    } catch (e) {
      if (!CurrentChat.ttsStatus.isNothing && mounted) {
        Dialogs.error(context: context, error: e);
      }
    }

    setState(() => CurrentChat.ttsStatus = TtsStatus.nothing);
  }

  void _copy() {
    Util.copyText(context: context, text: widget.message.item.text);
  }

  void _edit() {
    InputWidget.unFocus();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => _MessageEditor(message: widget.message),
    ));
  }

  void _delete() {
    if (!CurrentChat.chatStatus.isNothing) return;
    if (!CurrentChat.ttsStatus.isNothing) return;

    final message = widget.message;
    final list = message.list;
    final item = message.item;

    if (list.length == 1) {
      CurrentChat.messages.remove(message);
      ref.read(messagesProvider.notifier).notify();
    } else {
      if (item == list.last) message.index--;
      setState(() => list.remove(item));
    }

    CurrentChat.save();
  }

  void _source() {
    InputWidget.unFocus();

    showModalBottomSheet(
      context: context,
      enableDrag: true,
      useSafeArea: true,
      isScrollControlled: false,
      scrollControlDisabledMaxHeightRatio: 1,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: double.infinity,
          minHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                      top: 0, left: 16, right: 16, bottom: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        widget.message.item.text,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 48, width: double.infinity),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reanswer() async {
    if (!CurrentChat.chatStatus.isNothing) {
      CurrentChat.chatStatus = ChatStatus.nothing;
      chatClient?.close();
      chatClient = null;
      return;
    }

    final messages = CurrentChat.messages;
    final apiUrl = CurrentChat.apiUrl;
    final apiKey = CurrentChat.apiKey;
    final model = CurrentChat.model;

    if (apiUrl == null || apiKey == null || model == null) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).setup_api_model_first),
      );
      return;
    }

    final chatContext = buildChatContext(messages);
    final item = MessageItem(
      text: "",
      model: CurrentChat.model,
      role: MessageRole.assistant,
      time: Util.formatDateTime(DateTime.now()),
    );

    final message = widget.message;
    setState(() {
      message.list.add(item);
      message.index = message.list.length - 1;
      CurrentChat.chatStatus = ChatStatus.responding;
    });

    try {
      chatClient ??= http.Client();
      final llm = ChatOpenAI(
        apiKey: apiKey,
        baseUrl: apiUrl,
        client: chatClient,
        defaultOptions: ChatOpenAIOptions(
          model: model,
          maxTokens: CurrentChat.maxTokens,
          temperature: CurrentChat.temperature,
        ),
      );

      if (CurrentChat.stream ?? true) {
        final stream = llm.stream(PromptValue.chat(chatContext));
        await for (final chunk in stream) {
          setState(() => item.text += chunk.output.content);
        }
      } else {
        final result = await llm.invoke(PromptValue.chat(chatContext));
        setState(() => item.text += result.output.content);
      }
    } catch (e) {
      if (CurrentChat.chatStatus.isResponding && mounted) {
        Dialogs.error(context: context, error: e);
      }
      if (item.text.isEmpty) {
        setState(() {
          message.list.removeLast();
          message.index--;
        });
      }
    }

    setState(() => CurrentChat.chatStatus = ChatStatus.nothing);
    CurrentChat.save();
  }

  Future<void> _longPress() async {
    InputWidget.unFocus();

    final event = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              minTileHeight: 48,
              shape: StadiumBorder(),
              title: Text(S.of(context).copy),
              leading: const Icon(Icons.copy_all),
              onTap: () => Navigator.pop(context, 1),
            ),
            ListTile(
              minTileHeight: 48,
              shape: const StadiumBorder(),
              title: Text(S.of(context).edit),
              leading: const Icon(Icons.edit_outlined),
              onTap: () => Navigator.pop(context, 2),
            ),
            ListTile(
              minTileHeight: 48,
              shape: const StadiumBorder(),
              title: Text(S.of(context).source),
              leading: const Icon(Icons.code_outlined),
              onTap: () => Navigator.pop(context, 3),
            ),
            ListTile(
              minTileHeight: 48,
              shape: const StadiumBorder(),
              title: Text(S.of(context).delete),
              leading: const Icon(Icons.delete_outlined),
              onTap: () => Navigator.pop(context, 4),
            ),
          ],
        ),
      ),
    );
    if (event == null || !context.mounted) return;

    switch (event) {
      case 1:
        _copy();
        break;

      case 2:
        _edit();
        break;

      case 3:
        _source();
        break;

      case 4:
        _delete();
        break;
    }
  }
}

class MessageView extends StatelessWidget {
  final Message message;

  const MessageView({
    required this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final item = message.item;
    var content = item.text;
    final role = item.role;

    final colorScheme = Theme.of(context).colorScheme;
    final markdownStyleSheet = MarkdownStyleSheet(
      codeblockPadding: EdgeInsets.all(0),
      codeblockDecoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        color: colorScheme.surfaceContainer,
      ),
      blockquoteDecoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        color: colorScheme.brightness == Brightness.light
            ? Colors.blueGrey.withOpacity(0.3)
            : Colors.black.withOpacity(0.3),
      ),
    );

    final background = role.isUser
        ? colorScheme.secondaryContainer
        : colorScheme.surfaceContainerHighest;

    if (item.image != null) {
      content = "![image](data:image/jpeg;base64,${item.image})\n\n$content";
    }

    return Container(
      alignment: role.isAssistant ? Alignment.topLeft : Alignment.topRight,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      child: Column(
        crossAxisAlignment: role.isAssistant
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          if (role.isAssistant) ...[
            const SizedBox(height: 12),
            _buildHeader(context, message, item),
          ],
          SizedBox(height: role.isAssistant ? 8 : 12),
          Container(
            padding: const EdgeInsets.all(12),
            constraints: role.isUser
                ? BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  )
                : null,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                bottomLeft: const Radius.circular(16),
                bottomRight: const Radius.circular(16),
                topRight: Radius.circular(role.isUser ? 2 : 16),
              ),
            ),
            child: switch (item.text.isNotEmpty) {
              true => MarkdownBody(
                  data: content,
                  shrinkWrap: true,
                  extensionSet: mdExtensionSet,
                  onTapLink: (text, href, title) =>
                      Dialogs.openLink(context: context, link: href),
                  builders: {
                    "pre": CodeBlockBuilder(context: context),
                    "latex": LatexElementBuilder(textScaleFactor: 1.2),
                  },
                  styleSheet: markdownStyleSheet,
                  styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
                ),
              false => SizedBox(
                  width: 36,
                  height: 18,
                  child: SpinKitWave(
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Message message, MessageItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          child: const Icon(Icons.smart_toy),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.model ?? CurrentChat.model ?? S.of(context).no_model,
                style: Theme.of(context).textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                item.time ??
                    CurrentChat.chat?.time ??
                    Util.formatDateTime(DateTime.now()),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageEditor extends ConsumerStatefulWidget {
  final Message message;

  const _MessageEditor({
    required this.message,
  });

  @override
  ConsumerState<_MessageEditor> createState() => _MessageEditorState();
}

class _MessageEditorState extends ConsumerState<_MessageEditor> {
  late final Message message;
  late final UndoHistoryController _undoCtrl;
  late final TextEditingController _editCtrl;

  @override
  void initState() {
    super.initState();
    message = widget.message;
    _undoCtrl = UndoHistoryController();
    final text = widget.message.item.text;
    _editCtrl = TextEditingController(text: text);
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    _undoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).edit),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () => _undoCtrl.undo(),
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: () => _undoCtrl.redo(),
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: () {
              message.item.text = _editCtrl.text;
              ref.read(messageProvider(message).notifier).notify();

              CurrentChat.save();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8),
        child: TextField(
          expands: true,
          maxLines: null,
          controller: _editCtrl,
          undoController: _undoCtrl,
          textAlign: TextAlign.start,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: S.of(context).enter_message,
          ),
        ),
      ),
    );
  }
}
