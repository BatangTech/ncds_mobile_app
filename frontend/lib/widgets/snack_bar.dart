import 'package:flutter/material.dart';

void showSnackBar(
  BuildContext context,
  String text, {
  Color backgroundColor = Colors.grey,
  Duration duration = const Duration(seconds: 2),
  SnackBarBehavior behavior = SnackBarBehavior.floating,
  EdgeInsets margin = const EdgeInsets.all(15),
  bool showIcon = false,
  IconData icon = Icons.info_outline,
  Color iconColor = Colors.white,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: showIcon
          ? Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(text, style: const TextStyle(fontSize: 16))),
              ],
            )
          : Text(text, style: const TextStyle(fontSize: 16)),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: behavior,
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}

void showSuccessSnackBar(BuildContext context, String text) {
  showSnackBar(
    context,
    text,
    backgroundColor: Colors.green,
    showIcon: true,
    icon: Icons.check_circle,
  );
}

void showErrorSnackBar(BuildContext context, String text) {
  showSnackBar(
    context,
    text,
    backgroundColor: Colors.red,
    duration: const Duration(seconds: 4),
    showIcon: true,
    icon: Icons.error_outline,
  );
}
