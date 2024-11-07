import 'message.dart';
import "../util.dart";
import '../config.dart';

import 'dart:io';
import 'dart:convert';

class Current {
  static File? _file;
  static BotConfig? _bot;
  static ChatConfig? _chat;
  static final List<Message> messages = [];

  static Future<void> load(ChatConfig chat) async {
    _chat = chat;
    _file = File(Config.chatFilePath(chat.fileName));

    final json = jsonDecode(await _file!.readAsString());
    final messagesJson = json["messages"];
    final botJson = json["bot"];

    if (messagesJson != null) {
      messages.clear();
      for (final message in messagesJson) {
        messages.add(Message.fromJson(message));
      }
    }
    if (botJson != null) _bot = BotConfig.fromJson(botJson);
  }

  void clear() {
    _chat = null;
    _file = null;
  }

  void initChat(String title) {
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

  Future<void> save() async {
    if (_chat == null) {
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch.toString();

      final time = Util.formatDateTime(now);
      final title = messages.first.text;
      final fileName = "$timestamp.json";

      final chat = ChatConfig(
        time: time,
        title: title,
        fileName: fileName,
      );

      final filePath = Config.chatFilePath(fileName);
      _file = File(filePath);
      _chat = chat;

      Config.chats.add(chat);
      Config.save();
    }

    await _file!.writeAsString(jsonEncode({
      "bot": _bot,
      "messages": messages,
    }));
  }

  static String? get api {
    return _bot?.api ?? Config.bot.api;
  }

  static (String url, String key)? get urlKey {
    final config = Config.apis[api];
    return config != null ? (config.url, config.key) : null;
  }

  static String? get model {
    return _bot?.model ?? Config.bot.model;
  }
}
