import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CustomToast {
  CustomToast._();

  static void showSuccess({
    required String message,
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      timeInSecForIosWeb: 3,
      backgroundColor: const Color(0xFF4CAF50),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showError({
    required String message,
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: gravity,
      timeInSecForIosWeb: 4,
      backgroundColor: const Color(0xFFF44336),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showWarning({
    required String message,
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      timeInSecForIosWeb: 3,
      backgroundColor: const Color(0xFFFF9800),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showInfo({
    required String message,
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      timeInSecForIosWeb: 3,
      backgroundColor: const Color(0xFF2196F3),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showCustom({
    required String message,
    required Color backgroundColor,
    Color textColor = Colors.white,
    ToastGravity gravity = ToastGravity.BOTTOM,
    Toast length = Toast.LENGTH_SHORT,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: length,
      gravity: gravity,
      timeInSecForIosWeb: length == Toast.LENGTH_LONG ? 4 : 3,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 16.0,
    );
  }

  static void showValidationError({
    required String message,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 4,
      backgroundColor: const Color(0xFFD32F2F),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showSportsSuccess({
    required String message,
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      timeInSecForIosWeb: 3,
      backgroundColor: const Color(0xFF1B5E20),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showProcessing({
    required String message,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: const Color(0xFF424242),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void cancel() {
    Fluttertoast.cancel();
  }
}
