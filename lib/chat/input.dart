import "package:app/config.dart";
import "package:flutter/material.dart";

class InputWidget extends StatelessWidget {
  final int files;
  final bool editable;
  final TextEditingController controller;
  final void Function(BuildContext context)? addImage;
  final void Function(BuildContext context)? sendMessage;

  const InputWidget({
    super.key,
    this.files = 0,
    this.editable = true,
    required this.addImage,
    required this.controller,
    required this.sendMessage,
  });

  @override
  Widget build(BuildContext context) {
    void Function()? add;
    void Function()? send;

    if (addImage != null) {
      add = () {
        addImage!(context);
      };
    }

    if (sendMessage != null) {
      send = () {
        sendMessage!(context);
      };
    }

    final child = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Badge(
          isLabelVisible: files != 0,
          alignment: Alignment.topLeft,
          label: Text(files.toString()),
          child: IconButton(
            onPressed: add,
            style: IconButton.styleFrom(padding: const EdgeInsets.all(12)),
            icon: Icon(files == 0 ? Icons.add_photo_alternate : Icons.delete),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 120),
            child: TextField(
              maxLines: null,
              enabled: editable,
              controller: controller,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Enter your message",
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: send,
          icon: const Icon(Icons.send),
          style: IconButton.styleFrom(padding: const EdgeInsets.all(12)),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        color: colorScheme.surfaceContainer,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 12, left: 8, right: 8, bottom: 12),
        child: child,
      ),
    );
  }
}
