import 'package:flutter/material.dart';

class ConfirmDialog {
  Widget build(BuildContext context, String title, String subtitle,
      String cancelText, String okText) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [Text(subtitle)],
      ),
      actions: [
        TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary),
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text(cancelText)),
        TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface),
            child: Text(okText)),
      ],
    );
  }
}
