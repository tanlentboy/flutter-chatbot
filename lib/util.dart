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

import "../gen/l10n.dart";

import "package:flutter/services.dart";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";

class Util {
  static Future<void> copyText({
    required BuildContext context,
    required String text,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    Util.showSnackBar(
      context: context,
      content: Text(S.of(context).copied_successfully),
    );
  }

  static void showSnackBar({
    required Text content,
    required BuildContext context,
    Duration duration = const Duration(milliseconds: 800),
    SnackBarBehavior behavior = SnackBarBehavior.floating,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content,
        duration: duration,
        behavior: behavior,
        dismissDirection: DismissDirection.down,
      ),
    );
  }

  static String formatDateTime(DateTime time) {
    return "${_keepTwo(time.month)}-${_keepTwo(time.day)} "
        "${_keepTwo(time.hour)}:${_keepTwo(time.minute)}";
  }

  static String _keepTwo(int n) => n.toString().padLeft(2, '0');
}

class Dialogs {
  static Future<String?> input({
    required BuildContext context,
    required String title,
    String? text,
    String? hint,
  }) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        child: _InputDialog(
          title: title,
          text: text,
          hint: hint,
        ),
      ),
    );
  }

  static void error({
    required BuildContext context,
    required dynamic error,
  }) {
    final info = error.toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).error),
        content: Text(info),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              Util.copyText(context: context, text: info);
              Navigator.of(context).pop();
            },
            child: Text(S.of(context).copy),
          ),
        ],
      ),
    );
  }

  static Future<String?> select({
    required BuildContext context,
    required List<String> list,
    required String title,
    String? selected,
  }) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.only(left: 24, right: 24),
                child: Divider(),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (context, index) => RadioListTile(
                    value: list[index],
                    groupValue: selected,
                    title: Text(list[index]),
                    contentPadding: const EdgeInsets.only(left: 16, right: 24),
                    onChanged: (value) => setState(() => selected = value),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 24, right: 24),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: Navigator.of(context).pop,
                    child: Text(S.of(context).cancel),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(selected),
                    child: Text(S.of(context).ok),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  static void loading({
    required BuildContext context,
    required String hint,
    bool canPop = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: canPop,
      builder: (context) => PopScope(
        canPop: canPop,
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 24),
                Text(hint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> openLink({
    required BuildContext context,
    required String? link,
  }) async {
    if (link == null) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).empty_link),
      );
      return;
    }

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).link),
        content: Text(link),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(1),
            child: Text(S.of(context).copy),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(2),
            child: Text(S.of(context).open),
          ),
        ],
      ),
    );

    switch (result) {
      case 1:
        if (!context.mounted) return;
        Util.copyText(context: context, text: link);
        break;

      case 2:
        final uri = Uri.parse(link);
        if (await canLaunchUrl(uri)) {
          launchUrl(uri, mode: LaunchMode.platformDefault);
        } else {
          if (!context.mounted) return;
          Util.showSnackBar(
            context: context,
            content: Text(S.of(context).cannot_open),
          );
        }
        break;
    }
  }
}

class _InputDialog extends StatefulWidget {
  final String title;
  final String? text;
  final String? hint;

  const _InputDialog({
    required this.title,
    this.text,
    this.hint,
  });

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  late final TextEditingController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = TextEditingController(text: widget.text);
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              labelText: widget.hint,
              border: const UnderlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text(S.of(context).cancel),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ctrl.text),
              child: Text(S.of(context).ok),
            ),
            const SizedBox(width: 24),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
