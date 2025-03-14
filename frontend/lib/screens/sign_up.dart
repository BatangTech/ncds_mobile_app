import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/widget/snack_bar.dart';
import 'package:frontend/screens/chat_screen.dart';
import 'package:frontend/services/auth_service.dart';

import '../components/signup/form_section.dart';
import '../components/signup/header_section.dart';
import '../components/signup/login_redirect.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  bool isLoading = false;
  
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void signUpUser() async {
    setState(() {
      isLoading = true;
    });
    
    String res = await AuthService().signUpUser(
      email: emailController.text,
      password: passwordController.text,
      name: nameController.text,
    );

    if (res == "success") {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await startChat();
      
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => ChatScreen(userId: userId),
      ));
    } else {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, res);
    }
  }

  Future<void> startChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String userId = user.uid;
    final String apiUrl = "http://10.0.2.2:8080/start_chat?user_id=$userId";

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("AI: ${data['response']}");
    } else {
      print("❌ Error: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                HeaderSection(context: context),
                const SizedBox(height: 24),
                FormSection(
                  nameController: nameController,
                  emailController: emailController,
                  passwordController: passwordController,
                  isLoading: isLoading,
                  onSignUp: signUpUser,
                ),
                const SizedBox(height: 16),
                LoginRedirect(context: context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}