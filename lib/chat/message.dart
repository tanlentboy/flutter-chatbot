import "package:flutter/material.dart";
import "package:flutter_markdown/flutter_markdown.dart";

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
        alignment = Alignment.centerRight;
        background = Colors.green.shade900;
        break;

      case MessageRole.system:
        alignment = Alignment.centerRight;
        background = Colors.green.shade900;
        break;

      case MessageRole.assistant:
        alignment = Alignment.centerLeft;
        background = Colors.grey.shade900;
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
                styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
              ),
            ),
          );
        },
      ),
    );
  }
}
