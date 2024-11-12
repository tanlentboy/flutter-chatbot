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
import "current.dart";
import "../util.dart";
import "../config.dart";
import "../gen/l10n.dart";

import "package:flutter/material.dart";
import "package:markdown/markdown.dart" as md;
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "package:markdown/markdown.dart" hide Element, Text;
import "package:flutter_highlighter/flutter_highlighter.dart";
import "package:flutter_markdown_latex/flutter_markdown_latex.dart";

final messageProvider = NotifierProvider.autoDispose
    .family<MessageNotifier, void, Message>(MessageNotifier.new);

class MessageNotifier extends AutoDisposeFamilyNotifier<void, Message> {
  @override
  void build(Message arg) {}
  void notify() => ref.notifyListeners();
}

enum MessageRole {
  assistant,
  user,
}

enum MessageEvent {
  source,
  delete,
  copy,
  edit,
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

  static final extensionSet = ExtensionSet(
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

  Future<void> _longPress(BuildContext context, WidgetRef ref) async {
    if (!CurrentChat.isNothing) return;

    final children = [
      Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 16, bottom: 8),
        decoration: const BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
      ),
      ListTile(
        title: Text(S.of(context).copy),
        leading: const Icon(Icons.copy_all),
        onTap: () => Navigator.pop(context, MessageEvent.copy),
      ),
      ListTile(
        title: Text(S.of(context).source),
        leading: const Icon(Icons.code_outlined),
        onTap: () => Navigator.pop(context, MessageEvent.source),
      ),
      ListTile(
        title: Text(S.of(context).delete),
        leading: const Icon(Icons.delete_outlined),
        onTap: () => Navigator.pop(context, MessageEvent.delete),
      ),
      // ListTile(
      //   title: Text(S.of(context).edit),
      //   leading: const Icon(Icons.edit_outlined),
      //   onTap: () => Navigator.pop(context, MessageEvent.edit),
      // ),
    ];

    final event = await showModalBottomSheet<MessageEvent>(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          alignment: WrapAlignment.center,
          children: children,
        );
      },
    );
    if (event == null) return;

    switch (event) {
      case MessageEvent.copy:
        if (!context.mounted) return;
        await Util.copyText(context: context, text: message.text);
        break;

      case MessageEvent.delete:
        CurrentChat.messages.remove(message);
        ref.read(messagesProvider.notifier).notify();
        await CurrentChat.save();
        break;

      case MessageEvent.source:
        if (!context.mounted) return;
        await showDialog(
          context: context,
          builder: (context) {
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                title: Text(S.of(context).source),
              ),
              body: Padding(
                padding: EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: SelectableText(message.text),
                ),
              ),
            );
          },
        );

        break;

      default:
        if (!context.mounted) return;
        Util.showSnackBar(
          context: context,
          content: Text(S.of(context).not_implemented_yet),
        );
        break;
    }
  }

  const MessageWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(messageProvider(message));
    String content = message.text;
    final Alignment alignment;
    final Color background;

    final colorScheme = Theme.of(context).colorScheme;
    final markdownStyleSheet = MarkdownStyleSheet(
      codeblockDecoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        color: colorScheme.surfaceContainer,
      ),
    );

    if (message.image != null) {
      content =
          "![image](data:image/jpeg;base64,${message.image})\n\n${message.text}";
    }

    switch (message.role) {
      case MessageRole.user:
        background = colorScheme.secondaryContainer;
        alignment = Alignment.centerRight;
        break;

      case MessageRole.assistant:
        background = colorScheme.surfaceContainerHighest;
        alignment = Alignment.centerLeft;
        break;
    }

    return Container(
      alignment: alignment,
      margin: const EdgeInsets.all(8),
      child: GestureDetector(
        onLongPress: () async => await _longPress(context, ref),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              bottomLeft: const Radius.circular(16),
              bottomRight: const Radius.circular(16),
              topRight:
                  Radius.circular(message.role == MessageRole.user ? 4 : 16),
            ),
          ),
          child: MarkdownBody(
            data: content,
            shrinkWrap: true,
            extensionSet: extensionSet,
            onTapLink: (text, href, title) async =>
                await Util.openLink(context: context, link: href),
            builders: {
              "code": CodeElementBuilder(context: context),
              "latex": LatexElementBuilder(textScaleFactor: 1.2),
            },
            styleSheet: markdownStyleSheet,
            styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
          ),
        ),
      ),
    );
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  CodeElementBuilder({required this.context});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final theme = switch (Theme.of(context).colorScheme.brightness) {
      Brightness.light => codeLightTheme,
      Brightness.dark => codeDarkTheme,
    };
    var language = "";

    if (element.attributes["class"] != null) {
      language = element.attributes["class"]!.substring(9);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: HighlightView(
        tabSize: 2,
        theme: theme,
        language: language,
        element.textContent.trim(),
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}
