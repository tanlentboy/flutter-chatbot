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

import "dart:io";
import "dart:async";
import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:markdown/markdown.dart" as md;
import "package:audioplayers/audioplayers.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "package:markdown/markdown.dart" hide Element, Text;
import "package:flutter_highlighter/flutter_highlighter.dart";
import "package:flutter_markdown_latex/flutter_markdown_latex.dart";

final messageProvider = NotifierProvider.autoDispose
    .family<MessageNotifier, void, Message>(MessageNotifier.new);

final ttsProvider =
    NotifierProvider.autoDispose<TtsNotifier, void>(TtsNotifier.new);

class MessageNotifier extends AutoDisposeFamilyNotifier<void, Message> {
  @override
  void build(Message arg) {}
  void notify() => ref.notifyListeners();
}

class TtsNotifier extends AutoDisposeNotifier<void> {
  static final AudioPlayer _player = AudioPlayer();

  @override
  void build() {
    final subscription = _player.onPlayerComplete.listen(
      (e) => clear(),
      onError: (e) => clear(),
    );

    ref.onDispose(() async => await subscription.cancel());
  }

  void notify() => ref.notifyListeners();

  Future<void> play(String path) async {
    await _player.play(DeviceFileSource(path));
    CurrentChat.ttsStatus = TtsStatus.playing;
    notify();
  }

  Future<void> stop() async {
    await _player.stop();
    clear();
  }

  void clear() {
    CurrentChat.ttsStatus = TtsStatus.nothing;
    notify();
  }
}

enum MessageRole {
  assistant,
  user;

  bool get isAssistant => this == MessageRole.assistant;
  bool get isUser => this == MessageRole.user;
}

enum MessageEvent {
  source,
  delete,
  copy,
  edit,
  tts,
}

class Message {
  String text;
  String? image;
  MessageRole role;

  Message({this.image, required this.role, required this.text});

  Map<String, String?> toJson() => {
        "text": text,
        "image": image,
        "role": role.name,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        text: json["text"],
        image: json["image"],
        role: switch (json["role"]) {
          "assistant" => MessageRole.assistant,
          "user" => MessageRole.user,
          _ => throw "bad role",
        },
      );
}

class MessageWidget extends ConsumerWidget {
  final Message message;
  static int _ttsTimes = 0;

  const MessageWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(messageProvider(message));

    final MainAxisAlignment optsAlignment;
    String content = message.text;
    final Alignment alignment;
    final Color background;

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

    if (message.image != null) {
      content =
          "![image](data:image/jpeg;base64,${message.image})\n\n${message.text}";
    }

    switch (message.role) {
      case MessageRole.user:
        background = colorScheme.secondaryContainer;
        optsAlignment = MainAxisAlignment.end;
        alignment = Alignment.topRight;
        break;

      case MessageRole.assistant:
        background = colorScheme.surfaceContainerHighest;
        optsAlignment = MainAxisAlignment.start;
        alignment = Alignment.topLeft;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: alignment,
          child: GestureDetector(
            onLongPress: () async => await _more(context, ref),
            child: Container(
              margin: EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                  topRight: Radius.circular(
                      message.role == MessageRole.user ? 2 : 16),
                ),
              ),
              child: MarkdownBody(
                data: content,
                shrinkWrap: true,
                extensionSet: _extensionSet,
                onTapLink: (text, href, title) async =>
                    await Util.openLink(context: context, link: href),
                builders: {
                  "pre": CodeBlockBuilder(context: context),
                  "latex": LatexElementBuilder(textScaleFactor: 1.2),
                },
                styleSheet: markdownStyleSheet,
                styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
              ),
            ),
          ),
        ),
        if (CurrentChat.messages.lastOrNull == message &&
            CurrentChat.chatStatus.isNothing) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: optsAlignment,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  icon: const Icon(Icons.paste),
                  iconSize: 16,
                  onPressed: () async => await _copy(context),
                ),
              ),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  icon: const Icon(Icons.play_circle_outlined),
                  iconSize: 18,
                  onPressed: () async => await _tts(context, ref),
                ),
              ),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  icon: const Icon(Icons.code_outlined),
                  iconSize: 18,
                  onPressed: () async => await _source(context),
                ),
              ),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  iconSize: 18,
                  onPressed: () async => await _edit(context, ref),
                ),
              ),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  icon: const Icon(Icons.delete_outlined),
                  iconSize: 18,
                  onPressed: () async => await _delete(context, ref),
                ),
              ),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  icon: const Icon(Icons.more_horiz),
                  iconSize: 18,
                  onPressed: () async => await _more(context, ref),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _tts(BuildContext context, WidgetRef ref) async {
    if (!CurrentChat.ttsStatus.isNothing) return;

    final tts = Config.tts;
    final model = tts.model;
    final voice = tts.voice;
    final api = Config.apis[tts.api];

    if (model == null || voice == null || api == null) {
      if (!context.mounted) return;
      Util.showSnackBar(
        context: context,
        content: Text(
          S.of(context).setup_tts_first,
        ),
      );
      return;
    }

    final apiUrl = api.url;
    final apiKey = api.key;
    final endPoint = "$apiUrl/audio/speech";

    CurrentChat.ttsStatus = TtsStatus.loading;
    ref.read(ttsProvider.notifier).notify();
    final times = ++_ttsTimes;

    try {
      final response = await http.post(
        Uri.parse(endPoint),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": model,
          "voice": voice,
          "stream": false,
          "input": _markdownToText(message.text),
        }),
      );

      if (response.statusCode != 200) {
        throw "${response.statusCode} ${response.body}";
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final path = Config.audioFilePath("$timestamp.mp3");

      final file = File(path);
      await file.writeAsBytes(response.bodyBytes);
      if (CurrentChat.ttsStatus.isNothing || times != _ttsTimes) return;

      await ref.read(ttsProvider.notifier).play(path);
    } catch (e) {
      if (context.mounted) await Util.handleError(context: context, error: e);
      CurrentChat.ttsStatus = TtsStatus.nothing;
      ref.read(ttsProvider.notifier).notify();
    }
  }

  Future<void> _copy(BuildContext context) async {
    await Util.copyText(context: context, text: message.text);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    if (!CurrentChat.chatStatus.isNothing) return;
    if (!CurrentChat.ttsStatus.isNothing) return;

    InputWidget.unFocus();
    final undoCtrl = UndoHistoryController();
    final textCtrl = TextEditingController(text: message.text);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: () => undoCtrl.undo(),
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                onPressed: () => undoCtrl.redo(),
              ),
              IconButton(
                icon: const Icon(Icons.save_outlined),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
            title: Text(S.of(context).edit),
          ),
          body: Padding(
            padding:
                const EdgeInsets.only(top: 0, left: 16, right: 16, bottom: 0),
            child: TextField(
              expands: true,
              maxLines: null,
              controller: textCtrl,
              undoController: undoCtrl,
              textAlign: TextAlign.start,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: S.of(context).enter_your_message,
              ),
            ),
          ),
        );
      },
    );
    if (!(result ?? false)) return;
    undoCtrl.dispose();
    textCtrl.dispose();

    message.text = textCtrl.text;
    ref.read(messageProvider(message).notifier).notify();
    await CurrentChat.save();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!CurrentChat.chatStatus.isNothing) return;
    if (!CurrentChat.ttsStatus.isNothing) return;
    CurrentChat.messages.remove(message);
    ref.read(messagesProvider.notifier).notify();
    await CurrentChat.save();
  }

  Future<void> _source(BuildContext context) async {
    InputWidget.unFocus();

    await showModalBottomSheet(
      context: context,
      enableDrag: true,
      useSafeArea: true,
      isScrollControlled: false,
      scrollControlDisabledMaxHeightRatio: 1,
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: double.infinity,
            minHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
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
                SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                        top: 0, left: 16, right: 16, bottom: 0),
                    child: Column(
                      children: [
                        SelectableText(
                          message.text,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _more(BuildContext context, WidgetRef ref) async {
    InputWidget.unFocus();

    final children = [
      SizedBox(height: 8),
      Container(
        width: 36,
        height: 4,
        decoration: const BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
      ),
      SizedBox(height: 8),
      ListTile(
        minTileHeight: 48,
        shape: StadiumBorder(),
        title: Text(S.of(context).copy),
        leading: const Icon(Icons.copy_all),
        onTap: () => Navigator.pop(context, MessageEvent.copy),
      ),
      ListTile(
        minTileHeight: 48,
        shape: StadiumBorder(),
        title: Text(S.of(context).play),
        leading: const Icon(Icons.play_circle_outlined),
        onTap: () => Navigator.pop(context, MessageEvent.tts),
      ),
      ListTile(
        minTileHeight: 48,
        shape: StadiumBorder(),
        title: Text(S.of(context).source),
        leading: const Icon(Icons.code_outlined),
        onTap: () => Navigator.pop(context, MessageEvent.source),
      ),
      ListTile(
        minTileHeight: 48,
        shape: StadiumBorder(),
        title: Text(S.of(context).edit),
        leading: const Icon(Icons.edit_outlined),
        onTap: () => Navigator.pop(context, MessageEvent.edit),
      ),
      ListTile(
        minTileHeight: 48,
        shape: StadiumBorder(),
        title: Text(S.of(context).delete),
        leading: const Icon(Icons.delete_outlined),
        onTap: () => Navigator.pop(context, MessageEvent.delete),
      ),
    ];

    final event = await showModalBottomSheet<MessageEvent>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        );
      },
    );
    if (event == null || !context.mounted) return;

    switch (event) {
      case MessageEvent.tts:
        await _tts(context, ref);
        break;

      case MessageEvent.copy:
        await _copy(context);
        break;

      case MessageEvent.edit:
        await _edit(context, ref);
        break;

      case MessageEvent.source:
        await _source(context);
        break;

      case MessageEvent.delete:
        await _delete(context, ref);
        break;
    }
  }
}

class CodeBlockBuilder extends MarkdownElementBuilder {
  var language = "";
  final BuildContext context;

  CodeBlockBuilder({required this.context});

  @override
  void visitElementBefore(md.Element element) {
    final code = element.children?.first;
    if (code is md.Element) {
      final lang = code.attributes["class"];
      if (lang != null) language = lang.substring(9);
    }
    super.visitElementBefore(element);
  }

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = switch (colorScheme.brightness) {
      Brightness.light => codeLightTheme,
      Brightness.dark => codeDarkTheme,
    };
    final content = text.textContent.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme == codeDarkTheme
                ? Colors.black.withOpacity(0.3)
                : Colors.blueGrey.withOpacity(0.3),
          ),
          padding: EdgeInsets.only(left: 16, top: 8, bottom: 8, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language),
              GestureDetector(
                onTap: () async {
                  await Util.copyText(
                    context: context,
                    text: content,
                  );
                },
                child: Text(
                  S.of(context).copy,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: HighlightView(
            content,
            tabSize: 2,
            theme: theme,
            language: language,
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }
}

final _extensionSet = ExtensionSet(
  <BlockSyntax>[
    LatexBlockSyntax(),
    const TableSyntax(),
    const FootnoteDefSyntax(),
    const FencedCodeBlockSyntax(),
    const OrderedListWithCheckboxSyntax(),
    const UnorderedListWithCheckboxSyntax(),
  ],
  <InlineSyntax>[
    InlineHtmlSyntax(),
    LatexInlineSyntax(),
    StrikethroughSyntax(),
    AutolinkExtensionSyntax()
  ],
);

String _elementToText(md.Element element) {
  final buff = StringBuffer();
  final nodes = element.children ?? [];

  if (element.tag == "ul") {
    for (final node in nodes) {
      if (node is md.Element && node.tag == "li") {
        buff.write(_elementToText(node));
      }
    }
  } else if (element.tag == "ol") {
    int index = 1;
    for (final node in nodes) {
      if (node is md.Element && node.tag == "li") {
        buff.write("${index++}. ${_elementToText(node)}");
      }
    }
  } else {
    for (final node in nodes) {
      if (node is md.Text) {
        buff.write(node.text);
      } else if (node is md.Element) {
        final tag = node.tag;
        if (tag == "code") continue;
        if (tag == "latex") continue;
        if (tag == "th" || tag == "td") continue;
        buff.write(_elementToText(node));
      }
      buff.write("\n");
    }
  }

  return buff.toString();
}

String _markdownToText(String markdown) {
  final doc = md.Document(
    extensionSet: _extensionSet,
  );
  final buff = StringBuffer();
  final nodes = doc.parse(markdown);

  for (final node in nodes) {
    if (node is md.Element) {
      buff.write(_elementToText(node));
    }
  }

  return buff.toString().trim();
}
