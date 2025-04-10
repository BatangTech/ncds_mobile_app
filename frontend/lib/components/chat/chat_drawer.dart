import 'package:flutter/material.dart';
import '../../screens/chat_history_screen.dart';
import '../chat_drawer/app_version_footer.dart';
import '../chat_drawer/drawer_header.dart';
import '../chat_drawer/menu_item.dart';
import '../chat_drawer/section_title.dart';

class ChatDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;
  final VoidCallback onResetChat;
  final VoidCallback onLogout;
  final VoidCallback onViewProfile;
  final String userId;

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
    required this.userId,
    DateTime? nextInterviewDateTime,
    void Function()? onViewInterview,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserProfileHeader(
            userName: userName,
            userEmail: userEmail,
            primaryColor: primaryColor,
            accentColor: accentColor,
            textColor: textColor,
            onViewProfile: onViewProfile,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SectionTitle(
                  title: 'เมนูหลัก',
                  primaryColor: primaryColor,
                  textColor: textColor,
                ),
                DrawerMenuItem(
                  icon: Icons.chat_bubble_rounded,
                  title: 'แชท',
                  onTap: () {
                    Navigator.pop(context);
                  },
                  primaryColor: primaryColor,
                  textColor: textColor,
                  description: 'จัดการการสนทนาของคุณ',
                ),
                DrawerMenuItem(
                  icon: Icons.history_rounded,
                  title: 'ประวัติการสนทนา',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatHistoryScreen(
                          userId: userId,
                          primaryColor: primaryColor,
                          accentColor: accentColor,
                          textColor: textColor,
                        ),
                      ),
                    );
                  },
                  primaryColor: primaryColor,
                  textColor: textColor,
                  description: 'ดูประวัติการสนทนาและความเสี่ยง',
                ),
                DrawerMenuItem(
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
                SectionTitle(
                  title: 'การตั้งค่า',
                  primaryColor: primaryColor,
                  textColor: textColor,
                ),
                DrawerMenuItem(
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
          AppVersionFooter(
            primaryColor: primaryColor,
            textColor: textColor,
          ),
        ],
      ),
    );
  }
}
