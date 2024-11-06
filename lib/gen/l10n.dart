// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `ChatBot`
  String get title {
    return Intl.message(
      'ChatBot',
      name: 'title',
      desc: '',
      args: [],
    );
  }

  /// `copy`
  String get copy {
    return Intl.message(
      'copy',
      name: 'copy',
      desc: '',
      args: [],
    );
  }

  /// `edit`
  String get edit {
    return Intl.message(
      'edit',
      name: 'edit',
      desc: '',
      args: [],
    );
  }

  /// `source`
  String get source {
    return Intl.message(
      'source',
      name: 'source',
      desc: '',
      args: [],
    );
  }

  /// `delete`
  String get delete {
    return Intl.message(
      'delete',
      name: 'delete',
      desc: '',
      args: [],
    );
  }

  /// `camera`
  String get camera {
    return Intl.message(
      'camera',
      name: 'camera',
      desc: '',
      args: [],
    );
  }

  /// `gallery`
  String get gallery {
    return Intl.message(
      'gallery',
      name: 'gallery',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  /// `Bot`
  String get bot {
    return Intl.message(
      'Bot',
      name: 'bot',
      desc: '',
      args: [],
    );
  }

  /// `APIs`
  String get apis {
    return Intl.message(
      'APIs',
      name: 'apis',
      desc: '',
      args: [],
    );
  }

  /// `Other`
  String get other {
    return Intl.message(
      'Other',
      name: 'other',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  /// `Reset`
  String get reset {
    return Intl.message(
      'Reset',
      name: 'reset',
      desc: '',
      args: [],
    );
  }

  /// `Clear`
  String get clear {
    return Intl.message(
      'Clear',
      name: 'clear',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `API`
  String get api {
    return Intl.message(
      'API',
      name: 'api',
      desc: '',
      args: [],
    );
  }

  /// `Model`
  String get model {
    return Intl.message(
      'Model',
      name: 'model',
      desc: '',
      args: [],
    );
  }

  /// `Max Tokens`
  String get max_tokens {
    return Intl.message(
      'Max Tokens',
      name: 'max_tokens',
      desc: '',
      args: [],
    );
  }

  /// `Temperature`
  String get temperature {
    return Intl.message(
      'Temperature',
      name: 'temperature',
      desc: '',
      args: [],
    );
  }

  /// `System Prompts`
  String get system_prompts {
    return Intl.message(
      'System Prompts',
      name: 'system_prompts',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get name {
    return Intl.message(
      'Name',
      name: 'name',
      desc: '',
      args: [],
    );
  }

  /// `New API`
  String get new_api {
    return Intl.message(
      'New API',
      name: 'new_api',
      desc: '',
      args: [],
    );
  }

  /// `API Url`
  String get api_url {
    return Intl.message(
      'API Url',
      name: 'api_url',
      desc: '',
      args: [],
    );
  }

  /// `API Key`
  String get api_key {
    return Intl.message(
      'API Key',
      name: 'api_key',
      desc: '',
      args: [],
    );
  }

  /// `Model List`
  String get model_list {
    return Intl.message(
      'Model List',
      name: 'model_list',
      desc: '',
      args: [],
    );
  }

  /// `Select Models`
  String get select_models {
    return Intl.message(
      'Select Models',
      name: 'select_models',
      desc: '',
      args: [],
    );
  }

  /// `Duplicate API name`
  String get duplicate_api_name {
    return Intl.message(
      'Duplicate API name',
      name: 'duplicate_api_name',
      desc: '',
      args: [],
    );
  }

  /// `Please complete all fields`
  String get complete_all_fields {
    return Intl.message(
      'Please complete all fields',
      name: 'complete_all_fields',
      desc: '',
      args: [],
    );
  }

  /// `no model`
  String get no_model {
    return Intl.message(
      'no model',
      name: 'no_model',
      desc: '',
      args: [],
    );
  }

  /// `All Chats`
  String get all_chats {
    return Intl.message(
      'All Chats',
      name: 'all_chats',
      desc: '',
      args: [],
    );
  }

  /// `Saved Successfully`
  String get saved_successfully {
    return Intl.message(
      'Saved Successfully',
      name: 'saved_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Copied Successfully`
  String get copied_successfully {
    return Intl.message(
      'Copied Successfully',
      name: 'copied_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Not implemented yet`
  String get not_implemented_yet {
    return Intl.message(
      'Not implemented yet',
      name: 'not_implemented_yet',
      desc: '',
      args: [],
    );
  }

  /// `Invalid Max Tokens`
  String get invalid_max_tokens {
    return Intl.message(
      'Invalid Max Tokens',
      name: 'invalid_max_tokens',
      desc: '',
      args: [],
    );
  }

  /// `Invalid Temperature`
  String get invalid_temperature {
    return Intl.message(
      'Invalid Temperature',
      name: 'invalid_temperature',
      desc: '',
      args: [],
    );
  }

  /// `Enter your message`
  String get enter_your_message {
    return Intl.message(
      'Enter your message',
      name: 'enter_your_message',
      desc: '',
      args: [],
    );
  }

  /// `Failed to comprese image`
  String get image_compress_failed {
    return Intl.message(
      'Failed to comprese image',
      name: 'image_compress_failed',
      desc: '',
      args: [],
    );
  }

  /// `Set up the Bot and API first`
  String get setup_bot_api_first {
    return Intl.message(
      'Set up the Bot and API first',
      name: 'setup_bot_api_first',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
