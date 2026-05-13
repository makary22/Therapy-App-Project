import 'package:flutter/foundation.dart';

class ChatHistoryRefresh {
  static final ValueNotifier<int> token = ValueNotifier<int>(0);

  static void notifyUpdated() {
    token.value++;
  }
}
