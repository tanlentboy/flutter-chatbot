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

import "../gen/l10n.dart";
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
            icon: Icon(files == 0 ? Icons.add_photo_alternate : Icons.delete),
          ),
        ),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: TextField(
              maxLines: null,
              enabled: editable,
              controller: controller,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: S.of(context).enter_your_message,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: send,
          icon: const Icon(Icons.send),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 12, left: 6, right: 6, bottom: 12),
        child: child,
      ),
    );
  }
}
