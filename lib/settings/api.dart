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

import "settings.dart";
import "../util.dart";
import "../config.dart";

import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;

class APIWidget extends StatefulWidget {
  const APIWidget({super.key});

  @override
  State<APIWidget> createState() => _APIWidgetState();
}

class _APIWidgetState extends State<APIWidget> {
  @override
  Widget build(BuildContext context) {
    final shared = SettingsShared.of(context);
    final apis = Config.apis.entries.toList();

    return Column(
      children: [
        FilledButton(
          child: const Text("New API"),
          onPressed: () async {
            final changed = await showDialog<bool>(
              context: context,
              builder: (context) => ApiInfoWidget(shared: shared),
            );
            if (changed != null && changed) {
              await Config.save();
            }
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: apis.length,
            itemBuilder: (context, index) {
              return Card.filled(
                child: ListTile(
                  title: Text(apis[index].key),
                  leading: const Icon(Icons.api),
                  contentPadding: const EdgeInsets.only(left: 16, right: 8),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final changed = await showDialog<bool>(
                        context: context,
                        builder: (context) =>
                            ApiInfoWidget(shared: shared, entry: apis[index]),
                      );
                      if (changed != null && changed) {
                        await Config.save();
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ApiInfoWidget extends StatelessWidget {
  final SettingsShared shared;
  final MapEntry<String, ApiConfig>? entry;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _modelsCtrl = TextEditingController();
  final TextEditingController _apiUrlCtrl = TextEditingController();
  final TextEditingController _apiKeyCtrl = TextEditingController();

  ApiInfoWidget({
    super.key,
    this.entry,
    required this.shared,
  });

  void fix() {
    final api = Config.bot.api;
    final model = Config.bot.model;

    if (api != null) {
      final apis = Config.apis[api];
      if (apis == null) {
        Config.bot.api = null;
        Config.bot.model = null;
      } else if (!apis.models.contains(model)) {
        Config.bot.model = null;
      }
    } else if (model != null) {
      Config.bot.model = null;
    }
  }

  bool save(BuildContext context) {
    final name = _nameCtrl.text;
    final models = _modelsCtrl.text;
    final apiUrl = _apiUrlCtrl.text;
    final apiKey = _apiKeyCtrl.text;

    if (name.isEmpty || models.isEmpty || apiUrl.isEmpty || apiKey.isEmpty) {
      Util.showSnackBar(
        context: context,
        content: const Text("Please complete all fields"),
      );
      return false;
    }

    if (Config.apis.containsKey(name) &&
        (entry == null || name != entry!.key)) {
      Util.showSnackBar(
        context: context,
        content: Text("The $name API already exists"),
      );
      return false;
    }

    if (entry != null) {
      shared.setState(() => Config.apis.remove(entry!.key));
    }

    final modelList = models.split(",").map((e) => e.trim()).toList();
    shared.setState(() {
      Config.apis[name] = ApiConfig(
        url: apiUrl,
        key: apiKey,
        models: modelList,
      );
      fix();
    });

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
              title: const Text("Select Models"),
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
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text("Clear"),
                  onPressed: () => setState(() =>
                      chosen.forEach((model, _) => chosen[model] = false)),
                ),
                TextButton(
                  child: const Text("Save"),
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
        content: const Text("Please complete all fields"),
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
        title: Text("API"),
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
                      labelText: "Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
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
                      labelText: "API Url",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _apiKeyCtrl,
              decoration: InputDecoration(
                labelText: "API Key",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
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
                      labelText: "Model List",
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Column(
                  children: [
                    IconButton.outlined(
                      onPressed: () async => _fetchModels(context),
                      icon: const Icon(Icons.sync),
                    ),
                    SizedBox(height: 8),
                    IconButton.outlined(
                      onPressed: () async => _editModels(context),
                      icon: const Icon(Icons.edit),
                    ),
                  ],
                )
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text("Cancel"),
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
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      onPressed: () {
                        shared.setState(() {
                          Config.apis.remove(entry!.key);
                          fix();
                        });
                        Navigator.of(context).pop(true);
                      },
                      child: const Text("Delete"),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: FilledButton(
                    child: const Text("Save"),
                    onPressed: () {
                      if (save(context)) {
                        Navigator.of(context).pop(true);
                      }
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
}
