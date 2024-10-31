import "../config.dart";

import "package:flutter/material.dart";
import "package:markdown/markdown.dart" as md;
import "package:flutter_markdown/flutter_markdown.dart";
import "package:flutter_highlighter/flutter_highlighter.dart";
import "package:flutter_highlighter/themes/atom-one-dark.dart";
import "package:flutter_highlighter/themes/atom-one-light.dart";

class Message {
  String text;
  String? image;
  MessageRole role;

  Message({required this.role, required this.text, this.image});
}

enum MessageRole {
  assistant,
  system,
  user,
}

class MessageWidget extends StatelessWidget {
  final Message message;

  const MessageWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Alignment alignment;
    var content = message.text;

    switch (message.role) {
      case MessageRole.user:
        background = colorScheme.secondaryContainer;
        alignment = Alignment.centerRight;
        break;

      case MessageRole.system:
        background = colorScheme.primaryContainer;
        alignment = Alignment.centerRight;
        break;

      case MessageRole.assistant:
        background = colorScheme.surfaceContainer;
        alignment = Alignment.centerLeft;
        break;
    }

    if (message.image != null) {
      content = "![image](${message.image})\n\n${message.text}";
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
                data: content,
                shrinkWrap: true,
                selectable: true,
                styleSheet: _markdownStyleSheet,
                builders: {"code": _CodeElementBuilder()},
                styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final theme = switch (colorScheme.brightness) {
      Brightness.light => atomOneLightTheme,
      Brightness.dark => atomOneDarkTheme,
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
        element.textContent,
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}

final _markdownStyleSheet = MarkdownStyleSheet(
  codeblockDecoration: BoxDecoration(
    borderRadius: BorderRadius.circular(8),
  ),
);
