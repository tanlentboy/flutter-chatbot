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

import "package:flutter_riverpod/flutter_riverpod.dart";

final apisProvider = NotifierProvider<ApisNotifier, bool>(ApisNotifier.new);

class ApisNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void notify() => ref.notifyListeners();
}

final currentChatProvider =
    NotifierProvider<CurrentChatNotifier, bool>(CurrentChatNotifier.new);

class CurrentChatNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void notify() => ref.notifyListeners();
}
