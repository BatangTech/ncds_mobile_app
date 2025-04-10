import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatHistoryScreen extends StatefulWidget {
  final String userId;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;

  const ChatHistoryScreen({
    Key? key,
    required this.userId,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
  }) : super(key: key);

  @override
  _ChatHistoryScreenState createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<Map<String, dynamic>> _chatSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChatHistory();
  }

  // ในฟังก์ชัน _fetchChatHistory() ของ ChatHistoryScreen
  Future<void> _fetchChatHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. ดึงข้อมูลแชทปัจจุบัน
      final DocumentSnapshot mainDoc = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.userId)
          .get();

      final List<Map<String, dynamic>> sessions = [];

      // 2. ถ้ามีแชทปัจจุบัน ให้เพิ่มลงในรายการ
      if (mainDoc.exists) {
        final data = mainDoc.data() as Map<String, dynamic>;
        final timestamp = data['timestamp'] ?? Timestamp.now();
        final riskLevel = data['risk_level'] ?? 'ไม่ระบุ';

        sessions.add({
          'id': widget.userId,
          'date': timestamp.toDate(),
          'risk_level': riskLevel,
          'message_count': (data['conversation'] as List?)?.length ?? 0,
          'is_main_conversation': true,
        });
      }

      // 3. ดึงข้อมูลแชทเก่าจาก sessions collection
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.userId)
          .collection('sessions')
          .orderBy('timestamp', descending: true)
          .get();

      // 4. เพิ่มแชทเก่าลงในรายการ
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final String riskLevel = data['risk_level'] ?? 'ไม่ระบุ';
        final Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
        final DateTime date = timestamp.toDate();

        sessions.add({
          'id': doc.id,
          'date': date,
          'risk_level': riskLevel,
          'message_count': (data['conversation'] as List?)?.length ?? 0,
          'is_main_conversation': false,
        });
      }

      setState(() {
        _chatSessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching chat history: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถโหลดประวัติการสนทนาได้',
              style: GoogleFonts.prompt()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _viewChatSession(
      String sessionId, bool isMainConversation) async {
    try {
      DocumentSnapshot doc;
      if (isMainConversation) {
        doc = await FirebaseFirestore.instance
            .collection('conversations')
            .doc(widget.userId)
            .get();
      } else {
        doc = await FirebaseFirestore.instance
            .collection('conversations')
            .doc(widget.userId)
            .collection('sessions')
            .doc(sessionId)
            .get();
      }

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่พบข้อมูลการสนทนา', style: GoogleFonts.prompt()),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final List<dynamic> conversation = data['conversation'] as List<dynamic>;

      await showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.primaryColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history, color: widget.textColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ประวัติการสนทนา',
                        style: GoogleFonts.prompt(
                          fontWeight: FontWeight.bold,
                          color: widget.textColor,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: widget.textColor),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                padding: const EdgeInsets.all(16),
                child: ListView.builder(
                  itemCount: conversation.length,
                  itemBuilder: (context, index) {
                    final message = conversation[index] as Map<String, dynamic>;
                    return Column(
                      crossAxisAlignment: message['query'] != null &&
                              message['query'].toString().isNotEmpty
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (message['query'] != null &&
                            message['query'].toString().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 8, left: 40),
                            decoration: BoxDecoration(
                              color: widget.accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              message['query'].toString(),
                              style: GoogleFonts.prompt(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        if (message['response'] != null &&
                            message['response'].toString().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 8, right: 40),
                            decoration: BoxDecoration(
                              color: widget.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              message['response'].toString(),
                              style: GoogleFonts.prompt(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('❌ Error fetching conversation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล',
              style: GoogleFonts.prompt()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getRiskColor(String riskLevel) {
    if (riskLevel.contains('แดง') || riskLevel.contains('red')) {
      return Colors.red.shade100;
    } else if (riskLevel.contains('เขียว') || riskLevel.contains('green')) {
      return Colors.green.shade100;
    } else {
      return Colors.grey.shade100;
    }
  }

  IconData _getRiskIcon(String riskLevel) {
    if (riskLevel.contains('แดง') || riskLevel.contains('red')) {
      return Icons.warning_rounded;
    } else if (riskLevel.contains('เขียว') || riskLevel.contains('green')) {
      return Icons.check_circle_outline;
    } else {
      return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ประวัติการสนทนา', style: GoogleFonts.prompt()),
        backgroundColor: widget.primaryColor,
        foregroundColor: widget.textColor,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: widget.primaryColor))
          : _chatSessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_rounded, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'ไม่พบประวัติการสนทนา',
                        style: GoogleFonts.prompt(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _chatSessions.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final session = _chatSessions[index];
                    final riskLevel = session['risk_level'] as String;
                    final date = session['date'] as DateTime;
                    final messageCount = session['message_count'] as int;
                    final isMainConversation =
                        session['is_main_conversation'] as bool;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () =>
                            _viewChatSession(session['id'], isMainConversation),
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: _getRiskColor(riskLevel),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _getRiskIcon(riskLevel),
                                    size: 18,
                                    color: riskLevel.contains('แดง') ||
                                            riskLevel.contains('red')
                                        ? Colors.red
                                        : riskLevel.contains('เขียว') ||
                                                riskLevel.contains('green')
                                            ? Colors.green
                                            : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'ระดับความเสี่ยง: $riskLevel',
                                      style: GoogleFonts.prompt(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (isMainConversation)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: widget.primaryColor
                                            .withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'ปัจจุบัน',
                                        style: GoogleFonts.prompt(
                                          color: widget.textColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')} น.',
                                    style: GoogleFonts.prompt(),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$messageCount ข้อความ',
                                    style: GoogleFonts.prompt(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
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
