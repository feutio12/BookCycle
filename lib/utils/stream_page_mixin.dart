import 'dart:async';

import 'package:flutter/widgets.dart';

import '../pages/chats/subscription_manager.dart';

mixin StreamPageMixin<T extends StatefulWidget> on State<T> {
  final SubscriptionManager _subscriptionManager = SubscriptionManager();

  void addSubscription<T>(StreamSubscription<T> subscription) {
    _subscriptionManager.add(subscription);
  }

  @override
  void dispose() {
    _subscriptionManager.dispose();
    super.dispose();
  }
}
