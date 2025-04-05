import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import '../services/chat_service.dart';

class NotificationService {
  final String userId;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final Function(String) showSnackBar;
  final Function(DateTime) showInterviewDetails;
  final Function() checkScheduledInterviews;
  final ChatService chatService;

  NotificationService({
    required this.userId,
    required this.flutterLocalNotificationsPlugin,
    required this.showSnackBar,
    required this.showInterviewDetails,
    required this.checkScheduledInterviews,
    required this.chatService,
  });

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      _handleNotificationTap(response);
    });
    await FirebaseMessaging.instance.subscribeToTopic('chat_$userId');

    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'fcmToken': token});
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      Map<String, dynamic> data = json.decode(response.payload!);

      if (data.containsKey('type')) {
        if (data['type'] == 'ai_interview_scheduled') {
          checkScheduledInterviews();
        } else if (data['type'] == 'interview_reminder' &&
            data.containsKey('interview_time')) {
          DateTime interviewTime = DateTime.parse(data['interview_time']);
          showInterviewDetails(interviewTime);
        }
      }

      if (response.actionId == 'view_details' &&
          data.containsKey('interview_time')) {
        DateTime interviewTime = DateTime.parse(data['interview_time']);
        showInterviewDetails(interviewTime);
      }
    }
  }

  void handleForegroundMessage(
    RemoteMessage message, {
    required bool isAppInForeground,
    required Function(Map<String, String>) addMessage,
    required Function() scrollToBottom,
  }) {
    if (!isAppInForeground) {
      return;
    }

    if (message.data.containsKey('message_type') &&
        message.data['message_type'] == 'chat' &&
        message.data.containsKey('message')) {
      addMessage({'query': '', 'response': message.data['message']});
      scrollToBottom();
    }

    if (message.data.containsKey('type') &&
        message.data['type'] == 'ai_interview_scheduled') {
      checkScheduledInterviews();
    }

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'chat_channel',
            'Chat Notifications',
            channelDescription: 'Notifications for new chat messages',
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  void handleBackgroundMessage(
    RemoteMessage message, {
    required Function(Map<String, String>) addMessage,
    required Function() scrollToBottom,
  }) {
    print("Background message opened: ${message.messageId}");

    if (message.data.containsKey('messageId')) {
      chatService.fetchSpecificMessage(message.data['messageId']).then((msg) {
        if (msg != null) {
          addMessage({'query': '', 'response': msg});
          scrollToBottom();
        }
      });
    }

    if (message.data.containsKey('type') &&
        message.data['type'] == 'ai_interview_scheduled') {
      checkScheduledInterviews();
    }
  }

  void handleInitialMessage(
    RemoteMessage message, {
    required Function(Map<String, String>) addMessage,
    required Function() scrollToBottom,
  }) {
    print("App opened from notification: ${message.messageId}");

    if (message.data.containsKey('messageId')) {
      chatService.fetchSpecificMessage(message.data['messageId']).then((msg) {
        if (msg != null) {
          addMessage({'query': '', 'response': msg});
          scrollToBottom();
        }
      });
    }

    if (message.data.containsKey('type') &&
        message.data['type'] == 'ai_interview_scheduled') {
      checkScheduledInterviews();
    }
  }
}
