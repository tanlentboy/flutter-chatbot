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
import "package:flutter_riverpod/flutter_riverpod.dart";

class TaskTab extends ConsumerStatefulWidget {
  const TaskTab({super.key});

  @override
  ConsumerState<TaskTab> createState() => _TaskTabState();
}

class _TaskTabState extends ConsumerState<TaskTab> {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const padding = EdgeInsets.only(left: 24, right: 24);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      children: [
        Padding(
          padding: padding,
          child: Text(
            s.title_generation,
            style: TextStyle(color: primaryColor),
          ),
        ),
        CheckboxListTile(
          title: Text(s.enable),
          contentPadding: const EdgeInsets.only(left: 24, right: 16),
          value: Config.title.enable ?? false,
          subtitle: Text(s.title_enable_hint),
          onChanged: (value) {
            setState(() => Config.title.enable = value);
            Config.save();
          },
        ),
        const Divider(height: 1),
        ListTile(
          title: Text(s.api),
          contentPadding: padding,
          subtitle: Text(Config.title.api ?? s.empty),
          onTap: () async {
            if (Config.apis.isEmpty) return;

            final api = await Dialogs.select(
              context: context,
              list: Config.apis.keys.toList(),
              selected: Config.title.api,
              title: s.choose_api,
            );
            if (api == null) return;

            setState(() => Config.title.api = api);
            Config.save();
          },
        ),
        const Divider(height: 1),
        ListTile(
          title: Text(s.model),
          contentPadding: padding,
          subtitle: Text(Config.title.model ?? s.empty),
          onTap: () async {
            final models = Config.apis[Config.title.api]?.models;
            if (models == null) return;

            final model = await Dialogs.select(
              context: context,
              selected: Config.title.model,
              title: s.choose_model,
              list: models,
            );
            if (model == null) return;

            setState(() => Config.title.model = model);
            Config.save();
          },
        ),
        const Divider(height: 1),
        ListTile(
          title: Text(s.title_prompt),
          contentPadding: padding,
          subtitle: Text(s.title_prompt_hint),
          onTap: () async {
            final texts = await Dialogs.input(
              context: context,
              title: s.title_prompt,
              fields: <InputDialogField>[
                (hint: s.please_input, text: Config.title.prompt)
              ],
            );
            if (texts == null) return;

            String? prompt;
            final text = texts[0].trim();
            if (text.isNotEmpty) prompt = text;

            Config.title.prompt = prompt;
            Config.save();
          },
        ),
        const SizedBox(height: 4),
        InfoCard(info: s.title_generation_hint("{text}")),
      ],
    );
  }
}
