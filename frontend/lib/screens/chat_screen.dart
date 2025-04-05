import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../components/chat/chat_app_bar.dart';
import '../components/chat/chat_drawer.dart';
import '../components/chat/chat_input_box.dart';
import '../components/chat/chat_message_list.dart';
import '../components/chat/typing_indicator.dart';
import '../components/manager/interview_manager.dart';
import '../components/manager/message_handler.dart';
import '../services/chat_service.dart';
import '../services/fcm_service.dart';
import '../services/notification_service.dart';
import '../utils/app_colors.dart';
import 'user_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final String userId;

  const ChatScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];
  bool _isLoading = false;
  String _userName = '';
  String _userEmail = '';
  final ScrollController _scrollController = ScrollController();
  late final ChatService _chatService;
  late final FCMService _fcmService;
  late final AppColors _colors;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isAppInForeground = true;
  late final InterviewManager _interviewManager;
  late final NotificationService _notificationService;
  late final MessageHandler _messageHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _colors = AppColors();
    _chatService = ChatService(userId: widget.userId);
    _fcmService = FCMService();
    _interviewManager = InterviewManager(
      userId: widget.userId,
      colors: _colors,
      flutterLocalNotificationsPlugin: _flutterLocalNotificationsPlugin,
      showSnackBar: showSnackBar,
      resetChat: resetChat,
    );

    _notificationService = NotificationService(
      userId: widget.userId,
      flutterLocalNotificationsPlugin: _flutterLocalNotificationsPlugin,
      showSnackBar: showSnackBar,
      showInterviewDetails: (DateTime time) =>
          _interviewManager.showInterviewDetails(context, time),
      checkScheduledInterviews: _interviewManager.checkScheduledInterviews,
      chatService: _chatService,
    );

    _messageHandler = MessageHandler(
      userId: widget.userId,
      chatService: _chatService,
      fcmService: _fcmService,
      showSnackBar: showSnackBar,
      scrollToBottom: _scrollToBottom,
      addMessage: (Map<String, String> message) {
        setState(() {
          messages.add(message);
        });
      },
      updateRiskStatus: _chatService.updateRiskStatus,
      completeInterviewIfScheduled: (String riskLevel) =>
          _interviewManager.completeInterviewIfScheduled(riskLevel, _userName),
      colors: _colors,
    );

    _getUserProfile();
    _interviewManager.checkScheduledInterviews();
    _messageHandler.fetchInitialMessage();
    _initializeNotifications();
    _interviewManager.checkPendingInterviewDetails(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _scrollController.dispose();

    FirebaseMessaging.instance.unsubscribeFromTopic('chat_${widget.userId}');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;

    if (state == AppLifecycleState.resumed) {
      _interviewManager.checkScheduledInterviews();
      _interviewManager.checkPendingInterviewDetails(context);
    }
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();

    FirebaseMessaging.onMessage.listen((message) {
      _notificationService.handleForegroundMessage(
        message,
        isAppInForeground: _isAppInForeground,
        addMessage: (Map<String, String> msg) {
          setState(() {
            messages.add(msg);
          });
        },
        scrollToBottom: _scrollToBottom,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _notificationService.handleBackgroundMessage(
        message,
        addMessage: (Map<String, String> msg) {
          setState(() {
            messages.add(msg);
          });
        },
        scrollToBottom: _scrollToBottom,
      );
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _notificationService.handleInitialMessage(
          message,
          addMessage: (Map<String, String> msg) {
            setState(() {
              messages.add(msg);
            });
          },
          scrollToBottom: _scrollToBottom,
        );
      }
    });

    _interviewManager.startScheduledInterview();
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
    if (!mounted) return;

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

  Future<void> resetChat({bool isInterview = false}) async {
    try {
      final responseData = await _chatService.resetChat();
      if (mounted) {
        setState(() {
          messages.clear();

          messages.add({'query': '', 'response': responseData["response"]});

          if (isInterview) {
            messages.add({
              'query': '',
              'response':
                  "🎙️ การสัมภาษณ์ AI เพื่อประเมินความเสี่ยงสุขภาพเริ่มขึ้นแล้ว กรุณาตอบคำถามต่อไปนี้อย่างละเอียดและตรงไปตรงมาเพื่อการประเมินที่แม่นยำ"
            });
          }
        });

        if (!isInterview) {
          showSnackBar("✅ เริ่มแชทใหม่แล้วค่ะ!");
        }

        _scrollToBottom();
      }
    } catch (e) {
      print("❌ Error: $e");
      showSnackBar("❌ ไม่สามารถเริ่มแชทใหม่ได้");
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
      await _messageHandler.processMessage(message, context,
          setState: (Function() callback) {
        if (mounted) setState(callback);
      }, isLoading: (bool value) {
        if (mounted) {
          setState(() {
            _isLoading = value;
          });
        }
      });
    } catch (e) {
      showSnackBar("❌ เกิดข้อผิดพลาดในการเชื่อมต่อ");
      setState(() => _isLoading = false);
      print("❌ Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: ChatAppBar(
        title: _interviewManager.hasScheduledInterview
            ? 'AI Interview'
            : 'Health AI',
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
        hasScheduledInterview: _interviewManager.hasScheduledInterview,
        nextInterviewDateTime: _interviewManager.nextInterviewDateTime,
        onViewInterview: _interviewManager.hasScheduledInterview
            ? () => _interviewManager.showInterviewDetails(
                context, _interviewManager.nextInterviewDateTime!)
            : null,
        onResetChat: resetChat,
        onLogout: () async {
          await FirebaseMessaging.instance
              .unsubscribeFromTopic('chat_${widget.userId}');
          await FirebaseAuth.instance.signOut();

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        },
        onViewProfile: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(
                primaryColor: _colors.primaryColor,
                accentColor: _colors.accentColor,
                textColor: _colors.textColor,
              ),
            ),
          );
        },
      ),
      body: Column(
        children: [
          if (_interviewManager.hasScheduledInterview)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: _colors.accentColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: _colors.accentColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _interviewManager.nextInterviewDateTime != null
                          ? 'สัมภาษณ์ AI: ${_interviewManager.nextInterviewDateTime!.day}/${_interviewManager.nextInterviewDateTime!.month}/${_interviewManager.nextInterviewDateTime!.year} เวลา ${_interviewManager.nextInterviewDateTime!.hour.toString().padLeft(2, '0')}:${_interviewManager.nextInterviewDateTime!.minute.toString().padLeft(2, '0')} น.'
                          : 'มีการนัดสัมภาษณ์ AI',
                      style: GoogleFonts.prompt(
                        fontSize: 12,
                        color: _colors.accentColor,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _interviewManager.showInterviewDetails(
                        context, _interviewManager.nextInterviewDateTime!),
                    child: Text(
                      'ดูรายละเอียด',
                      style: GoogleFonts.prompt(
                        fontSize: 12,
                        color: _colors.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ChatMessageList(
              messages: messages,
              scrollController: _scrollController,
              primaryColor: _colors.primaryColor,
              secondaryColor: _colors.secondaryColor,
              textColor: _colors.textColor,
            ),
          ),
          if (_isLoading)
            TypingIndicator(
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