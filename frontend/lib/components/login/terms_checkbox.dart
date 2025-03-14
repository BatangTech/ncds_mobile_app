import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsCheckbox extends StatelessWidget {
  final bool isChecked;
  final ValueChanged<bool> onChanged;

  const TermsCheckbox({
    Key? key,
    required this.isChecked,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => onChanged(!isChecked),
          child: Icon(
            isChecked ? Icons.check_circle : Icons.circle_outlined,
            color: isChecked ? const Color(0xFF6C63FF) : Colors.black38,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "By signing up, you agree to our Terms of Service and Privacy Policy",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}