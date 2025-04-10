import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatService {
  final String userId;
  final String baseUrl = 'http://10.0.2.2:8080';

  ChatService({required this.userId});

  Future<Map<String, dynamic>> fetchInitialMessage() async {
    final url = Uri.parse('$baseUrl/start_chat?user_id=$userId');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Failed to fetch initial message");
    }
  }

  Future<Map<String, dynamic>> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'message': message,
      }),
    );

    final responseData = json.decode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return responseData;
    } else {
      throw Exception(responseData['error'] ?? "Failed to send message");
    }
  }

  Future<Map<String, dynamic>> resetChat({required String sessionId}) async {
    try {
      final url = Uri.parse('$baseUrl/new_chat?user_id=$userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception("Failed to reset chat");
      }
    } catch (e) {
      print("❌ Error in resetChat: $e");
      throw Exception("Failed to reset chat: $e");
    }
  }

  Future<void> updateRiskStatus(String riskLevel) async {
    if (userId.isEmpty) return;

    try {
      String collectionName = "low_risk_users";

      if (riskLevel == "red" ||
          riskLevel.contains("สูง") ||
          riskLevel.contains("เสี่ยงสูง")) {
        collectionName = "high_risk_users";
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

  Future<String?> fetchSpecificMessage(String messageId) async {
    try {
      final String apiUrl =
          "http://10.0.2.2:8080/get_message?user_id=$userId&message_id=$messageId";

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'];
      } else {
        print("❌ Error fetching specific message: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching specific message: $e");
      return null;
    }
  }
}
