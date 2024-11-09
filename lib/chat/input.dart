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
import "../chat/current.dart";
import "package:flutter/material.dart";

class InputWidget extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function(BuildContext context) addImage;
  final void Function(BuildContext context) clearImage;
  final Future<void> Function(BuildContext context) sendMessage;
  final void Function(BuildContext context) stopResponding;

  const InputWidget({
    super.key,
    required this.controller,
    required this.addImage,
    required this.clearImage,
    required this.sendMessage,
    required this.stopResponding,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = CurrentChat.image != null;
    final isResponding = CurrentChat.isResponding;

    final child = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Badge(
          isLabelVisible: hasImage,
          label: const Text("1"),
          alignment: Alignment.topLeft,
          child: IconButton(
            onPressed: () async {
              if (hasImage) {
                clearImage(context);
              } else {
                await addImage(context);
              }
            },
            icon: Icon(hasImage ? Icons.delete : Icons.add_photo_alternate),
          ),
        ),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: TextField(
              maxLines: null,
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
          onPressed: () async {
            if (isResponding) {
              stopResponding(context);
            } else {
              await sendMessage(context);
            }
          },
          icon: Icon(isResponding ? Icons.stop_circle : Icons.send),
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
