import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'voice_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _getUserProfile();
    fetchInitialMessage();
  }

  Future<void> fetchInitialMessage() async {
    final url =
        Uri.parse('http://10.0.2.2:8080/start_chat?user_id=${widget.userId}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          messages.add({'query': '', 'response': responseData["response"]});
        });
      } else {
        print("❌ Error fetching initial message");
      }
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  Future<void> updateRiskStatus(String userId, String riskLevel) async {
    if (userId.isEmpty) return;

    try {
      
      String collectionName = "low_risk_users"; 

      if (riskLevel == "red" ||
          riskLevel.contains("สูง") ||
          riskLevel.contains("เสี่ยงสูง")) {
        collectionName =
            "high_risk_users"; 
      }

      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(userId)
          .set({
        'user_id': userId,
        'risk_level': riskLevel,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("✅ อัปเดตข้อมูลผู้ใช้ที่มีความเสี่ยง $riskLevel สำเร็จ");
    } catch (e) {
      print("❌ ไม่สามารถอัปเดตข้อมูลความเสี่ยงได้: $e");
    }
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty || widget.userId.isEmpty) {
      showSnackBar(context, "User ID หรือข้อความไม่ถูกต้อง");
      return;
    }

    setState(() {
      messages.add({'query': message, 'response': ''});
      _isLoading = true;
    });

    _controller.clear();

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'message': message,
        }),
      );

      final responseData = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        String aiResponse =
            responseData['response'] ?? "AI ไม่สามารถให้คำตอบได้";

        if (mounted) {
          setState(() {
            messages.add({'query': '', 'response': aiResponse});
            _isLoading = false;
          });

          if (responseData.containsKey('next_question') &&
              responseData['next_question'].isNotEmpty) {
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() {
                  messages.add(
                      {'query': '', 'response': responseData['next_question']});
                });
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
                ? Colors.red
                : (isLowRisk ? Colors.green : Colors.orange);
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

            
            if (isHighRisk || isLowRisk) {
              updateRiskStatus(widget.userId, riskLevel);
            }

           
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(riskIcon, size: 80, color: riskColor),
                      const SizedBox(height: 10),
                      Text(
                        "ระดับความเสี่ยงของคุณ",
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        riskLevel,
                        style:
                            GoogleFonts.poppins(fontSize: 16, color: riskColor),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("ตกลง",
                          style: GoogleFonts.poppins(fontSize: 16)),
                    ),
                  ],
                );
              },
            );
          }
        }
      } else {
        String errorMessage = responseData.containsKey('error')
            ? responseData['error']
            : "เกิดข้อผิดพลาด กรุณาลองใหม่";
        showSnackBar(context, errorMessage);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      showSnackBar(context, "❌ เกิดข้อผิดพลาดในการเชื่อมต่อ");
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

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> resetChat() async {
    final url =
        Uri.parse('http://10.0.2.2:8080/new_chat?user_id=${widget.userId}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          messages.clear(); // ล้างแชทเก่าออก
          messages.add({'query': '', 'response': responseData["response"]});
        });

        showSnackBar(context, "✅ เริ่มแชทใหม่แล้วค่ะ!");
      } else {
        showSnackBar(context, "❌ ไม่สามารถเริ่มแชทใหม่ได้");
      }
    } catch (e) {
      print("❌ Error: $e");
      showSnackBar(context, "❌ เกิดข้อผิดพลาดในการเชื่อมต่อ");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('AI Assistant',
            style:
                GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(_userName),
              accountEmail: Text(_userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.blue[50],
                child: Text(_userName.isNotEmpty ? _userName[0] : 'U',
                    style: const TextStyle(fontSize: 40)),
              ),
              decoration: BoxDecoration(
                color: Colors.blue[700],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('เริ่มแชทใหม่'),
              onTap: () {
                resetChat();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chat'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                var msg = messages[index];
                bool isUser = msg['query']!.isNotEmpty;
                Color bgColor = isUser ? Colors.blueAccent : Colors.grey[300]!;
                bool isAI = msg['response']!.isNotEmpty;

                if (msg.containsKey('color')) {
                  bgColor = Color(int.parse(msg['color']!));
                }

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(15),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(2, 4),
                        )
                      ],
                    ),
                    child: Text(
                      isUser ? msg['query']! : msg['response']!,
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                  const SizedBox(height: 5),
                  Text("AI กำลังตอบ...",
                      style: GoogleFonts.poppins(fontSize: 12)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "พิมพ์ข้อความ...",
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.graphic_eq, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VoiceScreen(userId: widget.userId),
                      ),
                    );
                  },
                ),
                GestureDetector(
                  onTap: () => sendMessage(_controller.text),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
