import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;
  final VoidCallback onResetChat;
  final VoidCallback onLogout;
  final VoidCallback onViewProfile;

  const ChatDrawer({
    Key? key,
    required this.userName,
    required this.userEmail,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
    required this.onResetChat,
    required this.onLogout,
    required this.onViewProfile,
    required bool hasScheduledInterview,
    DateTime? nextInterviewDateTime,
    void Function()? onViewInterview,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(75),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 60,
                            width: 60,
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
                                userName.isNotEmpty
                                    ? userName[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: GoogleFonts.prompt(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                userEmail,
                                style: GoogleFonts.prompt(
                                  fontSize: 14,
                                  color: textColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Online',
                              style: GoogleFonts.prompt(
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: onViewProfile,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'ดูโปรไฟล์',
                                style: GoogleFonts.prompt(
                                  color: accentColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildModernSectionTitle('เมนูหลัก', primaryColor),
                _buildModernMenuItem(
                  icon: Icons.chat_bubble_rounded,
                  title: 'แชท',
                  onTap: () {
                    Navigator.pop(context);
                  },
                  primaryColor: primaryColor,
                  textColor: textColor,
                  description: 'จัดการการสนทนาของคุณ',
                ),
                _buildModernMenuItem(
                  icon: Icons.refresh_rounded,
                  title: 'เริ่มแชทใหม่',
                  onTap: () {
                    onResetChat();
                    Navigator.pop(context);
                  },
                  primaryColor: primaryColor,
                  textColor: textColor,
                  description: 'เริ่มการสนทนาใหม่',
                ),
                const SizedBox(height: 8),
                _buildModernSectionTitle('การตั้งค่า', primaryColor),
                _buildModernMenuItem(
                  icon: Icons.logout_rounded,
                  title: 'ออกจากระบบ',
                  onTap: onLogout,
                  primaryColor: accentColor,
                  textColor: textColor,
                  isDestructive: true,
                  description: 'ออกจากระบบแอปพลิเคชัน',
                ),
              ],
            ),
          ),
          Container(
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
          ),
        ],
      ),
    );
  }

  Widget _buildModernSectionTitle(String title, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12, top: 24),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.prompt(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color primaryColor,
    required Color textColor,
    bool isDestructive = false,
    String? description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: isDestructive
                ? primaryColor.withOpacity(0.05)
                : primaryColor.withOpacity(0.05),
            highlightColor: isDestructive
                ? primaryColor.withOpacity(0.1)
                : primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDestructive
                            ? [
                                primaryColor.withOpacity(0.1),
                                primaryColor.withOpacity(0.2)
                              ]
                            : [
                                primaryColor.withOpacity(0.1),
                                primaryColor.withOpacity(0.2)
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isDestructive ? primaryColor : primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.prompt(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDestructive ? primaryColor : textColor,
                          ),
                        ),
                        if (description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: GoogleFonts.prompt(
                              fontSize: 12,
                              color: textColor.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (isDestructive ? primaryColor : primaryColor)
                          .withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: (isDestructive ? primaryColor : primaryColor)
                            .withOpacity(0.5),
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}