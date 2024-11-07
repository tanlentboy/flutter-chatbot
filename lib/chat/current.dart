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

import "message.dart";
import "../util.dart";
import "../config.dart";
import "../gen/l10n.dart";
import "../settings/api.dart";

import "dart:io";
import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class Current {
  static File? _file;
  static BotConfig? _bot;
  static ChatConfig? _chat;
  static final List<Message> _messages = [];

  static Future<void> load(ChatConfig chat) async {
    clear();

    _chat = chat;
    _file = File(Config.chatFilePath(chat.fileName));

    final json = jsonDecode(await _file!.readAsString());
    final messagesJson = json["messages"];
    final botJson = json["bot"];

    if (messagesJson != null) {
      for (final message in messagesJson) {
        _messages.add(Message.fromJson(message));
      }
    }
    if (botJson != null) _bot = BotConfig.fromJson(botJson);
  }

  static void clear() {
    _bot = null;
    _chat = null;
    _file = null;
    _messages.clear();
  }

  static void initBot() => _bot = BotConfig();

  static void initChat(String title) {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();

    final time = Util.formatDateTime(now);
    final fileName = "$timestamp.json";

    final chat = ChatConfig(
      time: time,
      title: title,
      fileName: fileName,
    );
    _chat = chat;
  }

  static void initFile() => _file = File(Config.chatFilePath(_chat!.fileName));

  static Future<void> save() async {
    if (_chat == null) {
      initChat(_messages.first.text);
    }

    if (_file == null) {
      initFile();

      Config.chats.add(_chat!);
      await Config.save();
    }

    await _file!.writeAsString(jsonEncode({
      "bot": _bot,
      "messages": _messages,
    }));
  }

  static void fixBot() {
    if (_bot == null) return;

    final api = _bot!.api;
    final model = _bot!.model;

    if (api == null) return;
    final models = Config.apis[api]?.models;

    if (models == null) {
      _bot!.model = null;
      _bot!.api = null;
      return;
    } else if (!models.contains(model)) {
      _bot!.model = null;
      return;
    }
  }

  static File? get file => _file;
  static BotConfig? get bot => _bot;
  static ChatConfig? get chat => _chat;
  static List<Message> get messages => _messages;

  static String? get title => _chat?.title;
  static String? get apiUrl => Config.apis[api]?.url;
  static String? get apiKey => Config.apis[api]?.key;
  static String? get api => _bot?.api ?? Config.bot.api;

  static String? get model => _bot?.model ?? Config.bot.model;
  static bool? get stream => _bot?.stream ?? Config.bot.stream;
  static int? get maxTokens => _bot?.maxTokens ?? Config.bot.maxTokens;
  static double? get temperature => _bot?.temperature ?? Config.bot.temperature;
  static String? get systemPrompts =>
      _bot?.systemPrompts ?? Config.bot.systemPrompts;
}

final currentProvider =
    NotifierProvider<CurrentNotifier, bool>(CurrentNotifier.new);

class CurrentNotifier extends Notifier<bool> {
  @override
  bool build() {
    return true;
  }

  void notify() {
    ref.notifyListeners();
  }
}

class CurrentWidget extends StatefulWidget {
  const CurrentWidget({super.key});

  @override
  State<CurrentWidget> createState() => CurrentWidgetState();
}

class CurrentWidgetState extends State<CurrentWidget> {
  String? _api = Current.bot?.api;
  String? _model = Current.bot?.model;
  bool? _stream = Current.bot?.stream;

  final TextEditingController _titleCtrl =
      TextEditingController(text: Current.chat?.title.toString());
  final TextEditingController _maxTokensCtrl =
      TextEditingController(text: Current.bot?.maxTokens?.toString());
  final TextEditingController _temperatureCtrl =
      TextEditingController(text: Current.bot?.temperature?.toString());
  final TextEditingController _systemPromptsCtrl =
      TextEditingController(text: Current.bot?.systemPrompts?.toString());

  bool save(BuildContext context) {
    final title = _titleCtrl.text;
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

    if (Current.file != null && title.isEmpty) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).enter_a_title),
      );
      return false;
    }

    if (Current.chat != null) {
      Current.chat!.title = title;
    } else if (Current.chat == null && title.isNotEmpty) {
      Current.initChat(title);
    }

    Current.initBot();
    final bot = Current.bot!;

    bot.api = _api;
    bot.model = _model;
    bot.stream = _stream;
    bot.maxTokens = maxTokens;
    bot.temperature = temperature;
    final systemPrompts = _systemPromptsCtrl.text;
    bot.systemPrompts = systemPrompts.isNotEmpty ? systemPrompts : null;

    Util.showSnackBar(
      context: context,
      content: Text(S.of(context).saved_successfully),
    );

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(S.of(context).chat_settings),
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 16),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: S.of(context).chat_title,
                border: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Consumer(builder: (context, ref, child) {
              ref.watch(apisProvider);

              final apiList = <DropdownMenuItem<String>>[];
              final modelList = <DropdownMenuItem<String>>[];

              final apis = Config.apis.keys;
              for (final api in apis) {
                apiList.add(DropdownMenuItem(
                    value: api,
                    child: Text(api, overflow: TextOverflow.ellipsis)));
              }

              final models = Config.apis[_api]?.models ?? [];
              for (final model in models) {
                modelList.add(DropdownMenuItem(
                    value: model,
                    child: Text(model, overflow: TextOverflow.ellipsis)));
              }

              return Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _api,
                      items: apiList,
                      isExpanded: true,
                      hint: Text(S.of(context).api),
                      onChanged: (it) => setState(() {
                        _model = null;
                        _api = it;
                      }),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _model,
                      items: modelList,
                      isExpanded: true,
                      hint: Text(S.of(context).model),
                      onChanged: (it) => setState(() => _model = it),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
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
                    title: Text(S.of(context).streaming_response),
                    value: _stream ?? true,
                    onChanged: (value) {
                      setState(() => _stream = value);
                    },
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
                      _titleCtrl.text = "";
                      _maxTokensCtrl.text = "";
                      _temperatureCtrl.text = "";
                      _systemPromptsCtrl.text = "";
                      setState(() {
                        _api = null;
                        _model = null;
                        _stream = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Consumer(builder: (context, ref, child) {
                    return FilledButton(
                      child: Text(S.of(context).save),
                      onPressed: () {
                        if (save(context)) {
                          ref.read(currentProvider.notifier).notify();
                          Navigator.of(context).pop(true);
                        }
                      },
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(S.of(context).use_default_settings),
            ),
          ],
        ),
      ),
    );
  }
}
