import "package:flutter_riverpod/flutter_riverpod.dart";

final apisProvider = NotifierProvider<ApisNotifier, bool>(ApisNotifier.new);

class ApisNotifier extends Notifier<bool> {
  @override
  bool build() {
    return true;
  }

  void notify() {
    ref.notifyListeners();
  }
}

final currentChatProvider =
    NotifierProvider<CurrentChatNotifier, bool>(CurrentChatNotifier.new);

class CurrentChatNotifier extends Notifier<bool> {
  @override
  bool build() {
    return true;
  }

  void notify() {
    ref.notifyListeners();
  }
}
