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
      children: [
        Badge(
          isLabelVisible: files != 0,
          alignment: Alignment.topLeft,
          label: Text(files.toString()),
          child: IconButton.filled(
            onPressed: add,
            icon: Icon(files == 0 ? Icons.add : Icons.remove),
            style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            maxLines: null,
            enabled: editable,
            controller: controller,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: "Enter your message",
              contentPadding: const EdgeInsets.all(12),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: send,
          icon: const Icon(Icons.reply),
          style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
        ),
      ],
    );

    return Column(
      children: [
        Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.5)),
        Padding(padding: const EdgeInsets.all(12), child: child)
      ],
    );
  }
}
