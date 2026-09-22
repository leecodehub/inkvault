import 'package:flutter/material.dart';

class CoinProvider extends ChangeNotifier {
  int _coins = 100; // Starting demo balance

  int get coins => _coins;

  void addCoins(int amount) {
    _coins += amount;
    notifyListeners();
  }

  bool spendCoins(int amount) {
    if (_coins >= amount) {
      _coins -= amount;
      notifyListeners();
      return true;
    }
    return false;
  }
}
