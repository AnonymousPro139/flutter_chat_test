import 'package:flutter/material.dart';

extension SnackBarHelper on BuildContext {
  void showCustomSnackBar(String text, {bool isError = false}) {
    // Clear any existing snackbars so they don't queue up forever
    ScaffoldMessenger.of(this).clearSnackBars();

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red : Colors.blue,
        behavior: SnackBarBehavior.floating, // Looks more modern
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
