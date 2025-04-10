import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_edit_form.dart';
import 'profile_header.dart';
import 'profile_info_section.dart';

class ProfileEmptyState extends StatelessWidget {
  final Color primaryColor;
  final Color textColor;

  const ProfileEmptyState({Key? key, required this.primaryColor, required this.textColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(Icons.person_off_rounded, size: 40, color: primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่พบข้อมูลผู้ใช้',
            style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w500, color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'กรุณาลองใหม่อีกครั้ง',
            style: GoogleFonts.prompt(fontSize: 14, color: textColor.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}

class ProfileContent extends StatelessWidget {
  final Map<String, dynamic> userData;
  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final List<String> selectedNcds;
  final List<String> availableNcds;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;
  final Function(List<String>) updateSelectedNcds;

  const ProfileContent({
    Key? key,
    required this.userData,
    required this.isEditing,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.selectedNcds,
    required this.availableNcds,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
    required this.updateSelectedNcds,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        ProfileHeader(
          isEditing: isEditing,
          nameController: nameController,
          userData: userData,
          primaryColor: primaryColor,
          accentColor: accentColor,
          textColor: textColor,
        ),
        const SizedBox(height: 16),
        isEditing
            ? ProfileEditForm(
                nameController: nameController,
                emailController: emailController,
                phoneController: phoneController,
                selectedNcds: selectedNcds,
                availableNcds: availableNcds,
                primaryColor: primaryColor,
                accentColor: accentColor,
                textColor: textColor,
                updateSelectedNcds: updateSelectedNcds,
              )
            : ProfileInfoSection(
                userData: userData,
                primaryColor: primaryColor,
                accentColor: accentColor,
                textColor: textColor,
              ),
      ],
    );
  }
}