import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/chat_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Log out the user on app startup to force login screen
  await FirebaseAuth.instance.signOut();  // เพิ่มการล็อกเอาต์

  await checkPermissions(); 

  runApp(const MyApp());
}

Future<void> checkPermissions() async {
  var microphoneStatus = await Permission.microphone.status;
  if (!microphoneStatus.isGranted) {
    await Permission.microphone.request();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Health Assistant',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator()); // แสดง loading
          }

          if (snapshot.hasData) {
            // ดึง userId จาก FirebaseAuth
            String userId = snapshot.data!.uid;

            // ส่ง userId ไปยัง ChatScreen
            return ChatScreen(userId: userId); // ส่ง userId ไปยัง ChatScreen
          } else {
            return const LoginScreen(); // ถ้าไม่มีข้อมูล (ผู้ใช้ยังไม่ล็อกอิน)
          }
        },
      ),
    );
  }
}
