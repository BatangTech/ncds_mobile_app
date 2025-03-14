import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../components/chat/chat_app_bar.dart';
import '../components/chat/chat_drawer.dart';
import '../components/chat/chat_input_box.dart';
import '../components/chat/chat_message_list.dart';
import '../components/chat/risk_alert_dialog.dart';
import '../components/chat/typing_indicator.dart';
import '../services/chat_service.dart';
import '../utils/app_colors.dart';



class ChatScreen extends StatefulWidget {
  final String userId;

  const ChatScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];
  bool _isLoading = false;
  String _userName = '';
  String _userEmail = '';
  final ScrollController _scrollController = ScrollController();
  late final ChatService _chatService;
  late final AppColors _colors;

  @override
  void initState() {
    super.initState();
    _colors = AppColors();
    _chatService = ChatService(userId: widget.userId);
    _getUserProfile();
    fetchInitialMessage();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> fetchInitialMessage() async {
    try {
      final responseData = await _chatService.fetchInitialMessage();
      if (mounted) {
        setState(() {
          messages.add({'query': '', 'response': responseData["response"]});
        });
        _scrollToBottom();
      }
    } catch (e) {
      print("❌ Error fetching initial message: $e");
    }
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty || widget.userId.isEmpty) {
      showSnackBar("User ID หรือข้อความไม่ถูกต้อง");
      return;
    }

    setState(() {
      messages.add({'query': message, 'response': ''});
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final responseData = await _chatService.sendMessage(message);

      if (mounted) {
        String aiResponse = responseData['response'] ?? "AI ไม่สามารถให้คำตอบได้";

        setState(() {
          messages.add({'query': '', 'response': aiResponse});
          _isLoading = false;
        });
        _scrollToBottom();

        if (responseData.containsKey('next_question') &&
            responseData['next_question'].isNotEmpty) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                messages.add(
                    {'query': '', 'response': responseData['next_question']});
              });
              _scrollToBottom();
            }
          });
        }

        if (responseData.containsKey('risk_level')) {
          String riskLevel = responseData['risk_level'].toLowerCase();
          bool isHighRisk = riskLevel == "red" ||
              riskLevel.contains("สูง") ||
              riskLevel.contains("เสี่ยงสูง");
          bool isLowRisk = riskLevel == "green" ||
              riskLevel.contains("ต่ำ") ||
              riskLevel.contains("เสี่ยงต่ำ");

          Color riskColor = isHighRisk
              ? _colors.accentColor
              : (isLowRisk ? const Color(0xFF4CAF50) : const Color(0xFFFF9800));
          IconData riskIcon = isHighRisk
              ? Icons.warning_amber_rounded
              : (isLowRisk ? Icons.check_circle : Icons.info_outline);

          setState(() {
            messages.add({
              'query': '',
              'response': "📢 ผลการวิเคราะห์สุขภาพของคุณ: $riskLevel",
              'color': riskColor.value.toString()
            });
          });
          _scrollToBottom();

          if (isHighRisk || isLowRisk) {
            await _chatService.updateRiskStatus(riskLevel);
          }

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return RiskAlertDialog(
                riskLevel: riskLevel,
                riskColor: riskColor,
                riskIcon: riskIcon,
                primaryColor: _colors.primaryColor,
              );
            },
          );
        }
      }
    } catch (e) {
      showSnackBar("❌ เกิดข้อผิดพลาดในการเชื่อมต่อ");
      setState(() => _isLoading = false);
      print("❌ Error: $e");
    }
  }

  Future<void> _getUserProfile() async {
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    if (userDoc.exists && mounted) {
      setState(() {
        _userName = userDoc['name'] ?? 'ไม่ระบุชื่อ';
        _userEmail = userDoc['email'] ?? '';
      });
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.prompt()),
        backgroundColor: _colors.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> resetChat() async {
    try {
      final responseData = await _chatService.resetChat();
      setState(() {
        messages.clear(); // ล้างแชทเก่าออก
        messages.add({'query': '', 'response': responseData["response"]});
      });

      showSnackBar("✅ เริ่มแชทใหม่แล้วค่ะ!");
    } catch (e) {
      print("❌ Error: $e");
      showSnackBar("❌ ไม่สามารถเริ่มแชทใหม่ได้");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: ChatAppBar(
        title: 'Health AI',
        primaryColor: _colors.primaryColor,
        textColor: _colors.textColor,
        onResetChat: resetChat,
      ),
      drawer: ChatDrawer(
        userName: _userName,
        userEmail: _userEmail,
        primaryColor: _colors.primaryColor,
        accentColor: _colors.accentColor,
        textColor: _colors.textColor,
        onResetChat: resetChat,
        onLogout: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatMessageList(
              messages: messages,
              scrollController: _scrollController,
              primaryColor: _colors.primaryColor,
              secondaryColor: _colors.secondaryColor,
              textColor: _colors.textColor,
            ),
          ),
          if (_isLoading) TypingIndicator(
            primaryColor: _colors.primaryColor,
            lightTextColor: _colors.lightTextColor,
          ),
          ChatInputBox(
            controller: _controller,
            onSendMessage: sendMessage,
            primaryColor: _colors.primaryColor,
            secondaryColor: _colors.secondaryColor,
            lightTextColor: _colors.lightTextColor,
            userId: widget.userId,
          ),
        ],
      ),
    );
  }
}