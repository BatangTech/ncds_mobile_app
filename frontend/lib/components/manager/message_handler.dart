import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:frontend/services/chat_service.dart';
import 'package:frontend/services/fcm_service.dart';
import 'package:frontend/utils/app_colors.dart';
import '../chat/risk_alert_dialog.dart';

class MessageHandler {
  final String userId;
  final ChatService chatService;
  final FCMService fcmService;
  final Function(String) showSnackBar;
  final Function() scrollToBottom;
  final Function(Map<String, String>) addMessage;
  final Function(String) updateRiskStatus;
  final Function(String) completeInterviewIfScheduled;
  final AppColors colors;

  MessageHandler({
    required this.userId,
    required this.chatService,
    required this.fcmService,
    required this.showSnackBar,
    required this.scrollToBottom,
    required this.addMessage,
    required this.updateRiskStatus,
    required this.completeInterviewIfScheduled,
    required this.colors,
  });

  Future<void> fetchInitialMessage() async {
    try {
      final responseData = await chatService.fetchInitialMessage();
      addMessage({'query': '', 'response': responseData["response"]});
      scrollToBottom();
    } catch (e) {
      print("❌ Error fetching initial message: $e");
    }
  }

  Future<void> processMessage(
    String message,
    BuildContext context, {
    required Function(Function()) setState,
    required Function(bool) isLoading,
  }) async {
    try {
      final responseData = await chatService.sendMessage(message);

      String aiResponse = responseData['response'] ?? "AI ไม่สามารถให้คำตอบได้";

      addMessage({'query': '', 'response': aiResponse});
      isLoading(false);
      scrollToBottom();

      if (responseData.containsKey('next_question') &&
          responseData['next_question'].isNotEmpty) {
        Future.delayed(const Duration(seconds: 1), () {
          addMessage({'query': '', 'response': responseData['next_question']});
          scrollToBottom();
        });
      }

      if (responseData.containsKey('risk_level')) {
        await _handleRiskLevel(responseData['risk_level'], context);
        if (responseData.containsKey('interview_complete') &&
            responseData['interview_complete'] == true) {
          completeInterviewIfScheduled(responseData['risk_level'] ?? 'unknown');
        }
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> _handleRiskLevel(String riskLevel, BuildContext context) async {
    String riskLevelLower = riskLevel.toLowerCase();
    bool isHighRisk = riskLevelLower == "red" ||
        riskLevelLower.contains("สูง") ||
        riskLevelLower.contains("เสี่ยงสูง");
    bool isLowRisk = riskLevelLower == "green" ||
        riskLevelLower.contains("ต่ำ") ||
        riskLevelLower.contains("เสี่ยงต่ำ");

    Color riskColor = isHighRisk
        ? colors.accentColor
        : (isLowRisk ? const Color(0xFF4CAF50) : const Color(0xFFFF9800));
    IconData riskIcon = isHighRisk
        ? Icons.warning_amber_rounded
        : (isLowRisk ? Icons.check_circle : Icons.info_outline);

    addMessage({
      'query': '',
      'response': "📢 ผลการวิเคราะห์สุขภาพของคุณ: $riskLevel",
      'color': riskColor.value.toString()
    });
    scrollToBottom();

    if (isHighRisk || isLowRisk) {
      await updateRiskStatus(riskLevel);

      if (isHighRisk) {
        completeInterviewIfScheduled(riskLevel);

        await fcmService.sendLocalNotification(
          title: "การแจ้งเตือนความเสี่ยงสุขภาพ",
          body:
              "ระบบพบความเสี่ยงสุขภาพระดับสูง กรุณาปรึกษาแพทย์หรือบุคลากรทางการแพทย์",
          importance: Importance.high,
        );
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return RiskAlertDialog(
          riskLevel: riskLevel,
          riskColor: riskColor,
          riskIcon: riskIcon,
          primaryColor: colors.primaryColor,
        );
      },
    );
  }
}
