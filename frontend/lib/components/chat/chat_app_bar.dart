import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color primaryColor;
  final Color textColor;
  final Function({bool clearHistory}) onResetChat;

  const ChatAppBar({
    Key? key,
    required this.title,
    required this.primaryColor,
    required this.textColor,
    required this.onResetChat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.health_and_safety, color: primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.prompt(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: primaryColor),
          onPressed: () => onResetChat(clearHistory: true),
          tooltip: 'เริ่มแชทใหม่',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
