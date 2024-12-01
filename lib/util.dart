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
        copyText(context: context, text: link);
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

  static Future<void> handleError({
    required BuildContext context,
    required dynamic error,
  }) async {
    final info = error.toString();
    final result = await showDialog<bool>(
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
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.of(context).copy),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      Util.copyText(context: context, text: info);
    }
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
