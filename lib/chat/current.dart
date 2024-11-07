import "message.dart";
import "../util.dart";
import "../config.dart";

import "dart:io";
import "dart:convert";

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

  static Future<void> save() async {
    if (_chat == null) {
      initChat(_messages.first.text);
    }

    if (_file == null) {
      final filePath = Config.chatFilePath(_chat!.fileName);
      _file = File(filePath);

      Config.chats.add(_chat!);
      await Config.save();
    }

    await _file!.writeAsString(jsonEncode({
      "bot": _bot,
      "messages": _messages,
    }));
  }

  static BotConfig? get bot => _bot;
  static ChatConfig? get chat => _chat;
  static List<Message> get messages => _messages;

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
