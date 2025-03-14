import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatMessageList extends StatelessWidget {
  final List<Map<String, String>> messages;
  final ScrollController scrollController;
  final Color primaryColor;
  final Color secondaryColor;
  final Color textColor;

  const ChatMessageList({
    Key? key,
    required this.messages,
    required this.scrollController,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          var msg = messages[index];
          bool isUser = msg['query']!.isNotEmpty;
          Color bgColor = isUser ? primaryColor : Colors.white;
          Color textCol = isUser ? Colors.white : textColor;

          if (msg.containsKey('color')) {
            bgColor = Color(int.parse(msg['color']!));
            textCol = Colors.white;
          }

          return Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(5),
                  bottomRight: !isUser ? const Radius.circular(20) : const Radius.circular(5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      isUser ? msg['query']! : msg['response']!,
                      style: GoogleFonts.prompt(
                        fontSize: 16,
                        color: textCol,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (!isUser && !msg.containsKey('color'))
                    Positioned(
                      top: 0,
                      left: 16,
                      child: Container(
                        width: 32,
                        height: 3,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}