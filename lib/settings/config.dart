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

import "api.dart";
import "../config.dart";
import "../gen/l10n.dart";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class ConfigTab extends ConsumerStatefulWidget {
  const ConfigTab({super.key});

  @override
  ConsumerState<ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends ConsumerState<ConfigTab> {
  String? _bot;
  String? _api;
  String? _model;

  @override
  Widget build(BuildContext context) {
    ref.watch(apisProvider);

    final apiList = <DropdownMenuItem<String>>[];
    final modelList = <DropdownMenuItem<String>>[];

    final apis = Config.apis.keys;
    final models = Config.apis[_api]?.models ?? [];

    if (!apis.contains(_api)) _api = null;
    if (!models.contains(_model)) _model = null;

    for (final api in apis) {
      apiList.add(DropdownMenuItem(
        value: api,
        child: Text(api, overflow: TextOverflow.ellipsis),
      ));
    }

    for (final model in models) {
      modelList.add(DropdownMenuItem(
        value: model,
        child: Text(model, overflow: TextOverflow.ellipsis),
      ));
    }

    return ListView(
      children: [
        Text(" ${S.of(context).default_config}"),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _bot,
                items: [],
                isExpanded: true,
                hint: Text(S.of(context).bot),
                onChanged: (it) => setState(() {}),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
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
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
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
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: FilledButton.tonal(
                child: Text(S.of(context).reset),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: FilledButton(
                child: Text(S.of(context).save),
                onPressed: () async {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}
