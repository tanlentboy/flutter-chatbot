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

class Util {
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

  static String _keepTwo(int n) => n.toString().padLeft(2, "0");

  static String formatDateTime(DateTime time) {
    return "${_keepTwo(time.month)}-${_keepTwo(time.day)} "
        "${_keepTwo(time.hour)}:${_keepTwo(time.minute)}";
  }
}
