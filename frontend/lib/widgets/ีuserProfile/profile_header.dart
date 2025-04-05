import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileHeader extends StatelessWidget {
  final bool isEditing;
  final TextEditingController nameController;
  final Map<String, dynamic> userData;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;

  const ProfileHeader({
    Key? key,
    required this.isEditing,
    required this.nameController,
    required this.userData,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
          Positioned(
            bottom: -25,
            left: -25,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
          Positioned(
            top: 15,
            left: 25,
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(17.5),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 40,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12.5),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isEditing
                        ? (nameController.text.isNotEmpty ? nameController.text[0].toUpperCase() : 'U')
                        : (userData['name']?.isNotEmpty == true ? userData['name'][0].toUpperCase() : 'U'),
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              isEditing
                  ? TextFormField(
                      controller: nameController,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'ชื่อของคุณ',
                        hintStyle: GoogleFonts.prompt(fontSize: 20, color: textColor.withOpacity(0.5)),
                        border: InputBorder.none,
                      ),
                    )
                  : Text(
                      userData['name'] ?? 'ผู้ใช้งาน',
                      style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
                    ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ออนไลน์',
                          style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}