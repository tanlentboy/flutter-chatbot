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

import "package:flutter/material.dart";

class BotWidget extends StatefulWidget {
  const BotWidget({super.key});

  @override
  State<BotWidget> createState() => _BotWidgetState();
}

class _BotWidgetState extends State<BotWidget> {
  String? _api = Config.bot.api;
  String? _model = Config.bot.model;

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
        content: const Text("Invalid Max Tokens"),
      );
      return;
    }

    if (_temperatureCtrl.text.isNotEmpty && temperature == null) {
      Util.showSnackBar(
        context: context,
        content: const Text("Invalid Temperature"),
      );
      return;
    }

    Config.bot.api = _api;
    Config.bot.model = _model;
    Config.bot.maxTokens = maxTokens;
    Config.bot.temperature = temperature;
    final systemPrompts = _systemPromptsCtrl.text;
    Config.bot.systemPrompts = systemPrompts.isNotEmpty ? systemPrompts : null;

    Util.showSnackBar(
      context: context,
      content: const Text("Saved Successfully"),
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
                hint: const Text("API"),
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
                hint: const Text("Model"),
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
              flex: 1,
              child: TextField(
                controller: _temperatureCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Temperature",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _maxTokensCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Max Tokens",
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
          decoration: const InputDecoration(
            alignLabelWithHint: true,
            labelText: "System Prompts",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: FilledButton.tonal(
                child: const Text("Reset"),
                onPressed: () {
                  _maxTokensCtrl.text = "";
                  _temperatureCtrl.text = "";
                  _systemPromptsCtrl.text = "";
                  setState(() {
                    _api = null;
                    _model = null;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: FilledButton(
                child: const Text("Save"),
                onPressed: () async => save(context),
              ),
            ),
          ],
        )
      ],
    );
  }
}
