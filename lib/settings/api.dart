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

import "bot.dart";
import "../util.dart";
import "../config.dart";
import "../gen/l10n.dart";

import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:flutter_riverpod/flutter_riverpod.dart";

final apisProvider =
    NotifierProvider<ApisNotifier, Map<String, ApiConfig>>(ApisNotifier.new);

class ApisNotifier extends Notifier<Map<String, ApiConfig>> {
  @override
  Map<String, ApiConfig> build() {
    return Config.apis;
  }

  void notify() {
    ref.notifyListeners();
  }
}

class APIWidget extends StatefulWidget {
  const APIWidget({super.key});

  @override
  State<APIWidget> createState() => _APIWidgetState();
}

class _APIWidgetState extends State<APIWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilledButton(
          child: Text(S.of(context).new_api),
          onPressed: () async {
            final changed = await showDialog<bool>(
              context: context,
              builder: (context) => ApiInfoWidget(),
            );
            if (changed ?? false) await Config.save();
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Consumer(builder: (context, ref, child) {
            ref.watch(apisProvider);
            final apis = Config.apis.entries.toList();

            return ListView.builder(
              itemCount: apis.length,
              itemBuilder: (context, index) {
                return Card.filled(
                  child: ListTile(
                    title: Text(
                      apis[index].key,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: const Icon(Icons.api),
                    contentPadding: const EdgeInsets.only(left: 16, right: 8),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final changed = await showDialog<bool>(
                          context: context,
                          builder: (_) => ApiInfoWidget(entry: apis[index]),
                        );
                        if (changed ?? false) await Config.save();
                      },
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

class ApiInfoWidget extends StatelessWidget {
  final MapEntry<String, ApiConfig>? entry;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _modelsCtrl = TextEditingController();
  final TextEditingController _apiUrlCtrl = TextEditingController();
  final TextEditingController _apiKeyCtrl = TextEditingController();

  ApiInfoWidget({
    super.key,
    this.entry,
  });

  bool save(BuildContext context, WidgetRef ref) {
    final name = _nameCtrl.text;
    final models = _modelsCtrl.text;
    final apiUrl = _apiUrlCtrl.text;
    final apiKey = _apiKeyCtrl.text;

    if (name.isEmpty || models.isEmpty || apiUrl.isEmpty || apiKey.isEmpty) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).complete_all_fields),
      );
      return false;
    }

    if (Config.apis.containsKey(name) &&
        (entry == null || name != entry!.key)) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).duplicate_api_name),
      );
      return false;
    }

    if (entry != null) {
      Config.apis.remove(entry!.key);
    }

    final modelList = models.split(",").map((e) => e.trim()).toList();
    Config.apis[name] = ApiConfig(
      url: apiUrl,
      key: apiKey,
      models: modelList,
    );
    if (Config.fixBot()) ref.read(botProvider.notifier).notify();

    ref.read(apisProvider.notifier).notify();
    return true;
  }

  Future<void> _editModels(BuildContext context) async {
    final models = _modelsCtrl.text;
    if (models.isEmpty) return;

    final chosen = {for (final model in models.split(",")) model.trim(): true};
    if (chosen.isEmpty) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(S.of(context).select_models),
              content: SingleChildScrollView(
                child: ListBody(
                  children: chosen.keys.map((model) {
                    return CheckboxListTile(
                      title: Text(model),
                      value: chosen[model],
                      onChanged: (value) =>
                          setState(() => chosen[model] = value ?? false),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  child: Text(S.of(context).cancel),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text(S.of(context).clear),
                  onPressed: () => setState(() =>
                      chosen.forEach((model, _) => chosen[model] = false)),
                ),
                TextButton(
                  child: Text(S.of(context).save),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !result) return;

    _modelsCtrl.text = [
      for (final pair in chosen.entries)
        if (pair.value) pair.key
    ].join(", ");
  }

  Future<void> _fetchModels(BuildContext context) async {
    final url = _apiUrlCtrl.text;
    final key = _apiKeyCtrl.text;

    if (url.isEmpty || key.isEmpty) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).complete_all_fields),
      );
      return;
    }

    final modelsEndpoint = "$url/models";

    try {
      final response = await http.get(
        Uri.parse(modelsEndpoint),
        headers: {"Authorization": "Bearer $key"},
      );

      if (response.statusCode != 200) {
        throw "${response.statusCode} ${response.body}";
      }

      final json = jsonDecode(response.body);
      final models = <String>[for (final cell in json["data"]) cell["id"]];

      _modelsCtrl.text = models.join(", ");
    } catch (e) {
      if (context.mounted) {
        Util.showSnackBar(
          context: context,
          content: Text("$e"),
          duration: const Duration(milliseconds: 1500),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (entry != null) {
      _nameCtrl.text = entry!.key;
      _apiUrlCtrl.text = entry!.value.url;
      _apiKeyCtrl.text = entry!.value.key;
      _modelsCtrl.text = entry!.value.models.join(", ");
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(S.of(context).api),
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 16),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: S.of(context).name,
                      border: OutlineInputBorder(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _apiUrlCtrl,
                    decoration: InputDecoration(
                      labelText: S.of(context).api_url,
                      border: OutlineInputBorder(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyCtrl,
              decoration: InputDecoration(
                labelText: S.of(context).api_key,
                border: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    maxLines: 4,
                    controller: _modelsCtrl,
                    decoration: InputDecoration(
                      labelText: S.of(context).model_list,
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton.outlined(
                      onPressed: () async => _fetchModels(context),
                      icon: const Icon(Icons.sync),
                    ),
                    const SizedBox(height: 8),
                    IconButton.outlined(
                      onPressed: () async => _editModels(context),
                      icon: const Icon(Icons.edit),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            Consumer(builder: (context, ref, child) {
              return Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: Text(S.of(context).cancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Visibility(
                    visible: entry != null,
                    child: Expanded(
                      flex: 1,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor:
                              Theme.of(context).colorScheme.onError,
                        ),
                        onPressed: () {
                          Config.apis.remove(entry!.key);
                          if (Config.fixBot()) {
                            ref.read(botProvider.notifier).notify();
                          }
                          ref.read(apisProvider.notifier).notify();
                          Navigator.of(context).pop(true);
                        },
                        child: Text(S.of(context).delete),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: FilledButton(
                      child: Text(S.of(context).save),
                      onPressed: () {
                        if (save(context, ref)) {
                          Navigator.of(context).pop(true);
                        }
                      },
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
