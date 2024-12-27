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
import "../config.dart";
import "../gen/l10n.dart";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class ChatSettings extends ConsumerStatefulWidget {
  const ChatSettings({super.key});

  @override
  ConsumerState<ChatSettings> createState() => _ChatSettingsState();
}

class _ChatSettingsState extends ConsumerState<ChatSettings> {
  String? _bot = Current.bot;
  String? _api = Current.api;
  String? _model = Current.model;
  final TextEditingController _titleCtrl =
      TextEditingController(text: Current.title);

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(top: 16, left: 24, right: 12, bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                S.of(context).chat_settings,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: Navigator.of(context).pop,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: S.of(context).chat_title,
              border: const UnderlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBots(),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          flex: 2,
                          child: _buildApis(),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          flex: 3,
                          child: _buildModels(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(width: 24),
            TextButton(
              onPressed: () => setState(() {
                _model = null;
                _api = null;
                _bot = null;
              }),
              child: Text(S.of(context).reset),
            ),
            const Expanded(child: SizedBox()),
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text(S.of(context).cancel),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _save,
              child: Text(S.of(context).ok),
            ),
            const SizedBox(width: 24),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBots() {
    final bots = Config.bots.keys.toList();

    return Card.filled(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                Icons.smart_toy,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Text(
                S.of(context).bot,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (bots.isNotEmpty) ...[
            const Divider(height: 1),
            const SizedBox(height: 8),
            Stack(
              children: [
                const IgnorePointer(
                  child: Opacity(
                    opacity: 0,
                    child: ChoiceChip(
                      label: Text("bot"),
                      padding: EdgeInsets.all(4),
                      selected: true,
                    ),
                  ),
                ),
                const SizedBox(width: double.infinity),
                Positioned.fill(
                  child: ListView.separated(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    itemCount: bots.length,
                    itemBuilder: (context, index) {
                      final bot = bots[index];
                      return ChoiceChip(
                        label: Text(bot),
                        padding: const EdgeInsets.all(4),
                        selected: _bot == bot,
                        onSelected: (value) =>
                            setState(() => _bot = value ? bot : null),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildApis() {
    final apis = Config.apis.keys.toList();

    return Card.filled(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                Icons.api,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Text(
                S.of(context).api,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (apis.isNotEmpty) ...[
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final api in apis)
                      ListTile(
                        title: Text(api),
                        minTileHeight: 48,
                        selected: _api == api,
                        onTap: () => setState(() => _api = api),
                        contentPadding:
                            const EdgeInsets.only(left: 16, right: 16),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildModels() {
    final models = Config.apis[_api]?.models ?? [];

    return Card.filled(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                Icons.face,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Text(
                S.of(context).model,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (models.isNotEmpty) ...[
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final model in models)
                      ListTile(
                        title: Text(model),
                        minTileHeight: 48,
                        selected: _model == model,
                        onTap: () => setState(() => _model = model),
                        contentPadding:
                            const EdgeInsets.only(left: 16, right: 16),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  void _save() {
    final title = _titleCtrl.text;
    final oldModel = Current.model;
    final oldTitle = Current.title ?? "";
    final bool hasChat = Current.hasChat;

    if (title.isEmpty && hasChat) {
      return;
    }

    Current.core = CoreConfig(
      bot: _bot,
      api: _api,
      model: _model,
    );

    if (title != oldTitle) {
      if (hasChat) {
        Current.title = title;
      } else {
        Current.newChat(title);
      }
      ref.read(chatProvider.notifier).notify();
      ref.read(chatsProvider.notifier).notify();
    } else if (_model != oldModel) {
      ref.read(chatProvider.notifier).notify();
    }

    if (Current.hasChat) Current.save();
    if (mounted) Navigator.of(context).pop();
  }
}
