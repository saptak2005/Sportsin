import 'package:flutter/material.dart';

class StatControllerPair {
  final TextEditingController keyController;
  final TextEditingController valueController;

  StatControllerPair()
      : keyController = TextEditingController(),
        valueController = TextEditingController();

  StatControllerPair.fromMap(String key, String value)
      : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value);

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
