import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppVersionFooter extends StatelessWidget {
  final Color primaryColor;
  final Color textColor;

  const AppVersionFooter({
    Key? key,
    required this.primaryColor,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'v1.0.0',
            style: GoogleFonts.prompt(color: textColor.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}