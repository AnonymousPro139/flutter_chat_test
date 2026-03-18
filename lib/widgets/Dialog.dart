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

  void showWaitSnackBar(
    String text, {
    bool isLoading = true,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(this).clearSnackBars();

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        // If loading, keep it open indefinitely (or until you manually hide it).
        // Otherwise, use the default 4-second dismiss.
        duration: isLoading
            ? const Duration(seconds: 10)
            : const Duration(seconds: 2),
        backgroundColor: isError ? Colors.red : Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Row(
          children: [
            // Only show the spinner if isLoading is true
            if (isLoading) ...[
              const SizedBox(
                width: 20,
                height: 20, // Constrain the spinner size so it fits nicely
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16), // Space between spinner and text
            ],

            // Wrap text in Expanded so long messages wrap to the next line
            // instead of causing a "RenderFlex overflow" error
            Expanded(
              child: Text(text, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
