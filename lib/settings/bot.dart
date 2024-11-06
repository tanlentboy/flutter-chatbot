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

import "package:flutter/material.dart";

class BotWidget extends StatefulWidget {
  const BotWidget({super.key});

  @override
  State<BotWidget> createState() => _BotWidgetState();
}

class _BotWidgetState extends State<BotWidget> {
  String? _api = Config.bot.api;
  String? _model = Config.bot.model;
  bool? _stream = Config.bot.stream;

  final TextEditingController _maxTokensCtrl =
      TextEditingController(text: Config.bot.maxTokens?.toString());
  final TextEditingController _temperatureCtrl =
      TextEditingController(text: Config.bot.temperature?.toString());
  final TextEditingController _systemPromptsCtrl =
      TextEditingController(text: Config.bot.systemPrompts?.toString());

  Future<void> save(BuildContext context) async {
    final maxTokens = int.tryParse(_maxTokensCtrl.text);
    final temperature = double.tryParse(_temperatureCtrl.text);

    if (_maxTokensCtrl.text.isNotEmpty && maxTokens == null) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).invalid_max_tokens),
      );
      return;
    }

    if (_temperatureCtrl.text.isNotEmpty && temperature == null) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).invalid_temperature),
      );
      return;
    }

    Config.bot.api = _api;
    Config.bot.model = _model;
    Config.bot.stream = _stream;
    Config.bot.maxTokens = maxTokens;
    Config.bot.temperature = temperature;
    final systemPrompts = _systemPromptsCtrl.text;
    Config.bot.systemPrompts = systemPrompts.isNotEmpty ? systemPrompts : null;

    Util.showSnackBar(
      context: context,
      content: Text(S.of(context).saved_successfully),
    );

    await Config.save();
  }

  @override
  Widget build(BuildContext context) {
    final apiList = <DropdownMenuItem<String>>[];
    final modelList = <DropdownMenuItem<String>>[];

    final apis = Config.apis.keys;
    for (final api in apis) {
      apiList.add(DropdownMenuItem(
          value: api, child: Text(api, overflow: TextOverflow.ellipsis)));
    }

    final models = Config.apis[_api]?.models ?? [];
    for (final model in models) {
      modelList.add(DropdownMenuItem(
          value: model, child: Text(model, overflow: TextOverflow.ellipsis)));
    }

    return ListView(
      children: [
        Row(
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
              child: FilledButton(
                child: Text(S.of(context).save),
                onPressed: () async => save(context),
              ),
            ),
          ],
        )
      ],
    );
  }
}
