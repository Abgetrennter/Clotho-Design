import 'package:flutter/material.dart';

import 'app_router.dart';

class AppState extends ChangeNotifier {
  AppDestination _destination = AppDestination.chat;

  AppDestination get destination => _destination;

  void selectDestination(AppDestination destination) {
    if (_destination == destination) {
      return;
    }

    _destination = destination;
    notifyListeners();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    required super.notifier,
    required super.child,
    super.key,
  });

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    if (scope?.notifier == null) {
      throw StateError(
        'AppStateScope is not available in the current context.',
      );
    }
    return scope!.notifier!;
  }
}
