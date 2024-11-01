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

import "package:flutter/material.dart";

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
          child: Text("New API"),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => ApiInfoWidget(),
            );
          },
        ),
        SizedBox(height: 8),
        Expanded(
          child: ListView(),
        ),
      ],
    );
  }
}

class ApiInfoWidget extends StatelessWidget {
  final _nameCtrl = TextEditingController();
  final _modelsCtrl = TextEditingController();
  final _apiUrlCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();

  ApiInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("API"),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
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
                    child: Text("Cancel"),
                    onPressed: () {},
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: FilledButton(
                    child: Text("Save"),
                    onPressed: () {},
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
