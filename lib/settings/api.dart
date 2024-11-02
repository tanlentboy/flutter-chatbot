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
import "../config.dart";

import "package:flutter/material.dart";

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
          child: Text("New API"),
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
        SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: apis.length,
            itemBuilder: (context, index) {
              return Card.filled(
                child: ListTile(
                  title: Text(apis[index].key),
                  leading: const Icon(Icons.api),
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

  bool save(BuildContext context) {
    final name = _nameCtrl.text;
    final models = _modelsCtrl.text;
    final apiUrl = _apiUrlCtrl.text;
    final apiKey = _apiKeyCtrl.text;

    if (name.isEmpty || models.isEmpty || apiUrl.isEmpty || apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text("Please complete all fields"),
          dismissDirection: DismissDirection.horizontal,
        ),
      );
      return false;
    }

    if (Config.apis.containsKey(name) &&
        (entry == null || name != entry!.key)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text("The $name API already exists"),
          dismissDirection: DismissDirection.horizontal,
        ),
      );
      return false;
    }

    if (entry != null) {
      shared.setState(() => Config.apis.remove(entry!.key));
    }

    final modelList = models.split(",").map((e) => e.trim()).toList();
    shared.setState(() => Config.apis[name] =
        ApiConfig(url: apiUrl, key: apiKey, models: modelList));

    return true;
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
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text("API"),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _apiUrlCtrl,
              decoration: InputDecoration(
                labelText: "API Url",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
            SizedBox(height: 16),
            TextField(
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
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: Text("Cancel"),
                  ),
                ),
                SizedBox(width: 8),
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
                        shared.setState(() => Config.apis.remove(entry!.key));
                        Navigator.of(context).pop(true);
                      },
                      child: Text("Delete"),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: FilledButton(
                    child: Text("Save"),
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
