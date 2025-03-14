import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RiskAlertDialog extends StatelessWidget {
  final String riskLevel;
  final Color riskColor;
  final IconData riskIcon;
  final Color primaryColor;

  const RiskAlertDialog({
    Key? key,
    required this.riskLevel,
    required this.riskColor,
    required this.riskIcon,
    required this.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(12),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      content: Container(
        constraints: BoxConstraints(
          maxWidth: screenWidth * 0.8,
          maxHeight: screenHeight * 0.7, // ป้องกันการล้นขอบหน้าจอ
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView( // ทำให้สามารถเลื่อนดูเนื้อหาได้
          child: Column(
            mainAxisSize: MainAxisSize.min, // ปรับขนาดให้พอดีกับเนื้อหา
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(riskIcon, size: isSmallScreen ? 40 : 48, color: riskColor),
              ),
              const SizedBox(height: 12),
              Text(
                "ระดับความเสี่ยงของคุณ",
                style: GoogleFonts.prompt(
                  fontSize: isSmallScreen ? 16 : 18, 
                  fontWeight: FontWeight.bold
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  riskLevel,
                  style: GoogleFonts.prompt(
                    fontSize: isSmallScreen ? 16 : 17,
                    fontWeight: FontWeight.w600,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              "ตกลง",
              style: GoogleFonts.prompt(
                fontSize: isSmallScreen ? 15 : 16, 
                fontWeight: FontWeight.w600
              )
            ),
          ),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.only(bottom: 12),
    );
  }
}
