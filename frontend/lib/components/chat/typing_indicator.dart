import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TypingIndicator extends StatelessWidget {
  final Color primaryColor;
  final Color lightTextColor;

  const TypingIndicator({
    Key? key,
    required this.primaryColor,
    required this.lightTextColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "AI กำลังพิมพ์...",
            style: GoogleFonts.prompt(fontSize: 14, color: lightTextColor),
          ),
        ],
      ),
    );
  }
}