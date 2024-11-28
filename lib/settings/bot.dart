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

import "../util.dart";
import "../config.dart";
import "../gen/l10n.dart";
import "../chat/current.dart";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

final botsProvider =
    NotifierProvider.autoDispose<BotsNotifier, void>(BotsNotifier.new);

class BotsNotifier extends AutoDisposeNotifier<void> {
  @override
  void build() {}
  void notify() => ref.notifyListeners();
}

class BotsTab extends ConsumerWidget {
  const BotsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(botsProvider);
    final bots = Config.bots.entries.toList();

    return Stack(
      children: [
        ListView.builder(
          padding:
              const EdgeInsets.only(top: 4, left: 16, right: 16, bottom: 16),
          itemCount: bots.length,
          itemBuilder: (context, index) => Card.filled(
            margin: const EdgeInsets.only(top: 12),
            child: ListTile(
              title: Text(
                bots[index].key,
                overflow: TextOverflow.ellipsis,
              ),
              leading: const Icon(Icons.smart_toy),
              contentPadding: const EdgeInsets.only(left: 16, right: 8),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => BotSettings(botPair: bots[index]),
              )),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: "bot",
            icon: const Icon(Icons.smart_toy),
            label: Text(S.of(context).new_bot),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => BotSettings(),
            )),
          ),
        ),
      ],
    );
  }
}

class BotSettings extends ConsumerStatefulWidget {
  final MapEntry<String, BotConfig>? botPair;

  const BotSettings({
    super.key,
    this.botPair,
  });

  @override
  ConsumerState<BotSettings> createState() => _BotSettingsState();
}

class _BotSettingsState extends ConsumerState<BotSettings> {
  bool? _stream;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _maxTokensCtrl = TextEditingController();
  final TextEditingController _temperatureCtrl = TextEditingController();
  final TextEditingController _systemPromptsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    final botPair = widget.botPair;
    final bot = botPair?.value;

    final maxTokens = bot?.maxTokens;
    final temperature = bot?.temperature;
    final systemPrompts = bot?.systemPrompts;

    _stream = bot?.stream;
    if (botPair != null) {
      _nameCtrl.text = botPair.key;
    }
    if (maxTokens != null) {
      _maxTokensCtrl.text = maxTokens.toString();
    }
    if (temperature != null) {
      _temperatureCtrl.text = temperature.toString();
    }
    if (systemPrompts != null) {
      _systemPromptsCtrl.text = systemPrompts.toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _maxTokensCtrl.dispose();
    _temperatureCtrl.dispose();
    _systemPromptsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final botPair = widget.botPair;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(S.of(context).bot),
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 16),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: S.of(context).name,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _temperatureCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: S.of(context).temperature,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _maxTokensCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: S.of(context).max_tokens,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              controller: _systemPromptsCtrl,
              decoration: InputDecoration(
                alignLabelWithHint: true,
                labelText: S.of(context).system_prompts,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Flexible(
                  child: SwitchListTile(
                    value: _stream ?? true,
                    title: Text(S.of(context).streaming_response),
                    contentPadding: const EdgeInsets.only(left: 8, right: 8),
                    onChanged: (value) => setState(() => _stream = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: FilledButton.tonal(
                    child: Text(S.of(context).reset),
                    onPressed: () {
                      _maxTokensCtrl.text = "";
                      _temperatureCtrl.text = "";
                      _systemPromptsCtrl.text = "";
                      setState(() => _stream = null);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                if (botPair != null)
                  Expanded(
                    flex: 1,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      child: Text(S.of(context).delete),
                      onPressed: () async {
                        Config.bots.remove(botPair.key);

                        ref.read(botsProvider.notifier).notify();
                        Navigator.of(context).pop();
                        await Config.save();
                      },
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: FilledButton(
                    child: Text(S.of(context).save),
                    onPressed: () async {
                      if (!_save(context)) return;

                      ref.read(botsProvider.notifier).notify();
                      Navigator.of(context).pop();
                      await Config.save();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _save(BuildContext context) {
    final name = _nameCtrl.text;

    if (name.isEmpty) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).enter_a_name),
      );
      return false;
    }

    final botPair = widget.botPair;
    if (Config.bots.containsKey(name) &&
        (botPair == null || name != botPair.key)) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).duplicate_bot_name),
      );
      return false;
    }

    final maxTokens = int.tryParse(_maxTokensCtrl.text);
    final temperature = double.tryParse(_temperatureCtrl.text);

    if (_maxTokensCtrl.text.isNotEmpty && maxTokens == null) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).invalid_max_tokens),
      );
      return false;
    }

    if (_temperatureCtrl.text.isNotEmpty && temperature == null) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).invalid_temperature),
      );
      return false;
    }

    if (botPair != null) Config.bots.remove(botPair.key);

    final text = _systemPromptsCtrl.text;
    final systemPrompts = text.isEmpty ? null : text;
    Config.bots[name] = BotConfig(
      stream: _stream,
      maxTokens: maxTokens,
      temperature: temperature,
      systemPrompts: systemPrompts,
    );

    return true;
  }
}
