import 'dart:async';

class SubscriptionManager {
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  void add<T>(StreamSubscription<T> subscription) {
    _subscriptions.add(subscription);
  }

  void cancelAll() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  void dispose() {
    cancelAll();
  }
}