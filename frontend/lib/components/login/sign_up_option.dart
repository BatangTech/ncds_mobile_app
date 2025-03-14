import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpOption extends StatelessWidget {
  final String leadText;
  final String actionText;
  final VoidCallback onTap;

  const SignUpOption({
    Key? key,
    required this.leadText,
    required this.actionText,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          leadText,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6C63FF),
            ),
          ),
        ),
      ],
    );
  }
}