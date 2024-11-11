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
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

final modelProvider =
    NotifierProvider.autoDispose<ModelNotifier, void>(ModelNotifier.new);

final chatsProvider =
    NotifierProvider.autoDispose<ChatsNotifier, void>(ChatsNotifier.new);

final messagesProvider =
    NotifierProvider.autoDispose<MessagesNotifier, void>(MessagesNotifier.new);

class ModelNotifier extends AutoDisposeNotifier<void> {
  @override
  void build() => ref.listen(apisProvider, (prev, next) => notify());
  void notify() => ref.notifyListeners();
}

class ChatsNotifier extends AutoDisposeNotifier<void> {
  @override
  void build() {}
  void notify() => ref.notifyListeners();
}

class MessagesNotifier extends AutoDisposeNotifier<void> {
  @override
  void build() {}
  void notify() => ref.notifyListeners();
}

class ChatPage extends ConsumerWidget {
  final ScrollController scrollCtrl = ScrollController();

  ChatPage({super.key});

  Future<void> _longPress(
      BuildContext context, WidgetRef ref, int index) async {
    if (!CurrentChat.isNothing) return;

    final message = CurrentChat.messages[index];
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
        await Clipboard.setData(ClipboardData(text: message.text));
        if (context.mounted) {
          Util.showSnackBar(
            context: context,
            content: Text(S.of(context).copied_successfully),
          );
        }
        break;

      case MessageEvent.delete:
        CurrentChat.messages.removeAt(index);
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
  Widget build(BuildContext context, WidgetRef ref) {
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
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Text(
            S.of(context).all_chats,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              ref.watch(chatsProvider);

              return ListView.builder(
                itemCount: Config.chats.length,
                itemBuilder: (context, index) {
                  final chat = Config.chats[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 16, right: 8),
                    leading: const Icon(Icons.article),
                    selected: CurrentChat.chat == chat,
                    title: Text(
                      chat.title,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(chat.time),
                    onTap: () async {
                      if (CurrentChat.chat == chat) return;

                      await CurrentChat.load(chat);
                      ref.read(modelProvider.notifier).notify();
                      ref.read(chatsProvider.notifier).notify();
                      ref.read(messagesProvider.notifier).notify();
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        if (CurrentChat.chat == chat) {
                          CurrentChat.clear();
                          ref.read(modelProvider.notifier).notify();
                          ref.read(messagesProvider.notifier).notify();
                        }

                        await File(Config.chatFilePath(chat.fileName)).delete();
                        ref.read(chatsProvider.notifier).notify();
                        Config.chats.removeAt(index);
                        await Config.save();
                      },
                    ),
                  );
                },
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
                Consumer(
                  builder: (context, ref, child) {
                    ref.watch(modelProvider);

                    return Text(
                      CurrentChat.model ?? S.of(context).no_model,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    );
                  },
                )
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.swap_vert),
            iconSize: 20,
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => CurrentChatSettings(),
              );
            },
          ),
        ]),
        actions: [
          IconButton(
              icon: const Icon(Icons.note_add_outlined),
              onPressed: () {
                CurrentChat.clear();
                ref.read(modelProvider.notifier).notify();
                ref.read(messagesProvider.notifier).notify();
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
      body: Column(
        children: [
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                ref.watch(messagesProvider);

                return ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(8),
                  itemCount: CurrentChat.messages.length,
                  itemBuilder: (context, index) {
                    final message = CurrentChat.messages[index];
                    return MessageWidget(
                      message: message,
                      key: ValueKey(message),
                      longPress: (context) async =>
                          await _longPress(context, ref, index),
                    );
                  },
                );
              },
            ),
          ),
          InputWidget(scrollCtrl: scrollCtrl),
        ],
      ),
    );
  }
}
