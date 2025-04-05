import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:frontend/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class InterviewManager {
  final String userId;
  final AppColors colors;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final Function(String) showSnackBar;
  final Function({bool isInterview}) resetChat;

  bool _hasInterviewScheduled = false;
  DateTime? _nextInterviewDateTime;
  bool _hasPendingInterviewDetails = false;

  bool get hasScheduledInterview => _hasInterviewScheduled;
  DateTime? get nextInterviewDateTime => _nextInterviewDateTime;

  InterviewManager({
    required this.userId,
    required this.colors,
    required this.flutterLocalNotificationsPlugin,
    required this.showSnackBar,
    required this.resetChat,
  });

  Future<void> checkPendingInterviewDetails(BuildContext? context) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingDetails = prefs.getString('pending_interview_details');

    if (pendingDetails != null && context != null) {
      final interviewTime = DateTime.parse(pendingDetails);
      showInterviewDetails(context, interviewTime);

      await prefs.remove('pending_interview_details');
      _hasPendingInterviewDetails = false;
    }
  }

  Future<void> checkScheduledInterviews() async {
    try {
      final QuerySnapshot interviewsSnapshot = await FirebaseFirestore.instance
          .collection('scheduled_interviews')
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'scheduled')
          .where('completed', isEqualTo: false)
          .orderBy('interview_datetime')
          .limit(1)
          .get();

      if (interviewsSnapshot.docs.isNotEmpty) {
        final interviewDoc = interviewsSnapshot.docs.first;
        final interviewData = interviewDoc.data() as Map<String, dynamic>;
        final Timestamp interviewTimestamp =
            interviewData['interview_datetime'];
        final DateTime interviewDateTime = interviewTimestamp.toDate();

        _hasInterviewScheduled = true;
        _nextInterviewDateTime = interviewDateTime;

        final now = DateTime.now();
        if (interviewDateTime.year == now.year &&
            interviewDateTime.month == now.month &&
            interviewDateTime.day == now.day) {
          _showInterviewReminder(interviewDateTime);
        }
      } else {
        _hasInterviewScheduled = false;
        _nextInterviewDateTime = null;
      }
    } catch (e) {
      print("❌ Error checking scheduled interviews: $e");
    }
  }

  void _showInterviewReminder(DateTime interviewTime) {
    final formattedTime =
        "${interviewTime.hour.toString().padLeft(2, '0')}:${interviewTime.minute.toString().padLeft(2, '0')}";

    flutterLocalNotificationsPlugin.show(
      0,
      "เตือนการสัมภาษณ์",
      "คุณมีการสัมภาษณ์ AI ในวันนี้เวลา $formattedTime น.",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'interview_reminder_channel',
          'Interview Reminders',
          channelDescription: 'Notifications for upcoming AI interviews',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          actions: [
            AndroidNotificationAction(
              'view_details',
              'ดูรายละเอียด',
            ),
          ],
        ),
      ),
    );
  }

  void showInterviewDetails(BuildContext context, DateTime interviewTime) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'รายละเอียดการสัมภาษณ์',
          style: GoogleFonts.kanit(
            fontWeight: FontWeight.bold,
            color: colors.primaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'วันที่: ${interviewTime.day}/${interviewTime.month}/${interviewTime.year}',
              style: GoogleFonts.kanit(),
            ),
            const SizedBox(height: 8),
            Text(
              'เวลา: ${interviewTime.hour.toString().padLeft(2, '0')}:${interviewTime.minute.toString().padLeft(2, '0')} น.',
              style: GoogleFonts.kanit(),
            ),
            const SizedBox(height: 8),
            Text(
              'ประเภท: สัมภาษณ์ประเมินความเสี่ยงด้วย AI',
              style: GoogleFonts.kanit(),
            ),
            const SizedBox(height: 16),
            Text(
              'เมื่อถึงเวลาสัมภาษณ์ กรุณาเข้าสู่แอพพลิเคชันเพื่อรับการสัมภาษณ์โดยอัตโนมัติ',
              style: GoogleFonts.kanit(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ตกลง',
              style: GoogleFonts.kanit(color: colors.accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> storeInterviewDetailsForLater(DateTime interviewTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'pending_interview_details', interviewTime.toIso8601String());

    _hasPendingInterviewDetails = true;
  }

  Future<void> startScheduledInterview() async {
    if (!_hasInterviewScheduled || _nextInterviewDateTime == null) return;

    final now = DateTime.now();
    final interviewTime = _nextInterviewDateTime!;
    final diffMinutes = now.difference(interviewTime).inMinutes.abs();
    if (diffMinutes <= 5) {
      try {
        final QuerySnapshot interviewsSnapshot = await FirebaseFirestore
            .instance
            .collection('scheduled_interviews')
            .where('user_id', isEqualTo: userId)
            .where('status', isEqualTo: 'scheduled')
            .where('completed', isEqualTo: false)
            .orderBy('interview_datetime')
            .limit(1)
            .get();

        if (interviewsSnapshot.docs.isNotEmpty) {
          final interviewDoc = interviewsSnapshot.docs.first;
          await FirebaseFirestore.instance
              .collection('scheduled_interviews')
              .doc(interviewDoc.id)
              .update({
            'status': 'in_progress',
          });
          await resetChat(isInterview: true);
          showSnackBar(
              "🎙️ การสัมภาษณ์ AI เริ่มขึ้นแล้ว กรุณาตอบคำถามเพื่อประเมินความเสี่ยง");
        }
      } catch (e) {
        print("❌ Error starting scheduled interview: $e");
      }
    }
  }

  Future<void> completeInterviewIfScheduled(
      String riskLevel, String userName) async {
    try {
      final QuerySnapshot interviewsSnapshot = await FirebaseFirestore.instance
          .collection('scheduled_interviews')
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'in_progress')
          .where('completed', isEqualTo: false)
          .limit(1)
          .get();

      if (interviewsSnapshot.docs.isNotEmpty) {
        final interviewDoc = interviewsSnapshot.docs.first;
        await FirebaseFirestore.instance
            .collection('scheduled_interviews')
            .doc(interviewDoc.id)
            .update({
          'status': 'completed',
          'completed': true,
          'completion_date': FieldValue.serverTimestamp(),
          'risk_level': riskLevel,
        });

        await FirebaseFirestore.instance.collection('nurse_notifications').add({
          'nurse_id': interviewDoc['nurse_id'],
          'title': 'การสัมภาษณ์ AI เสร็จสมบูรณ์',
          'message':
              'ผู้ใช้ $userName ได้ทำการสัมภาษณ์ AI เสร็จสมบูรณ์แล้ว ผลการประเมินความเสี่ยง: $riskLevel',
          'type': 'interview_completed',
          'read': false,
          'created_at': FieldValue.serverTimestamp(),
          'data': {
            'interview_id': interviewDoc.id,
            'user_id': userId,
            'user_name': userName,
            'risk_level': riskLevel,
          },
        });
        _hasInterviewScheduled = false;
        _nextInterviewDateTime = null;
      }
    } catch (e) {
      print("❌ Error completing scheduled interview: $e");
    }
  }
}
