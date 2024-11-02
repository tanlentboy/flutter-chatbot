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
  final TextEditingController _maxTokensCtrl = TextEditingController();
  final TextEditingController _temperatureCtrl = TextEditingController();
  final TextEditingController _systemPromptsCtrl = TextEditingController();

  Future<void> save(BuildContext context) async {
    final maxTokens = int.tryParse(_maxTokensCtrl.text);
    final temperature = num.tryParse(_temperatureCtrl.text);

    if (_maxTokensCtrl.text.isNotEmpty && maxTokens == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text("Invalid Max Tokens"),
          dismissDirection: DismissDirection.horizontal,
        ),
      );
      return;
    }

    if (_temperatureCtrl.text.isNotEmpty && temperature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text("Invalid Temperature"),
          dismissDirection: DismissDirection.horizontal,
        ),
      );
      return;
    }

    Config.bot.api = _api;
    Config.bot.model = _model;
    Config.bot.systemPrompts = _systemPromptsCtrl.text;
    if (maxTokens != null) Config.bot.maxTokens = maxTokens;
    if (temperature != null) Config.bot.temperature = temperature;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text("Saved Successfully"),
        duration: Duration(milliseconds: 500),
        dismissDirection: DismissDirection.horizontal,
      ),
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

    _maxTokensCtrl.text = Config.bot.maxTokens.toString();
    _temperatureCtrl.text = Config.bot.temperature.toString();
    _systemPromptsCtrl.text = Config.bot.systemPrompts.toString();

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
                hint: Text("API"),
                onChanged: (String? it) => setState(() {
                  _model = null;
                  _api = it;
                }),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _model,
                items: modelList,
                isExpanded: true,
                hint: Text("Model"),
                onChanged: (String? it) => setState(() => _model = it),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: TextField(
                controller: _temperatureCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Temperature",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _maxTokensCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Max Tokens",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        TextField(
          maxLines: 4,
          controller: _systemPromptsCtrl,
          decoration: InputDecoration(
            alignLabelWithHint: true,
            labelText: "System Prompts",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: FilledButton.tonal(
                child: const Text("Reset"),
                onPressed: () {
                  final bot = BotConfig();
                  _maxTokensCtrl.text = bot.maxTokens.toString();
                  _temperatureCtrl.text = bot.temperature.toString();
                  _systemPromptsCtrl.text = bot.systemPrompts.toString();
                  setState(() {
                    _api = null;
                    _model = null;
                  });
                },
              ),
            ),
            SizedBox(width: 8),
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
