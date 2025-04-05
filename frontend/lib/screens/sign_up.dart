import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/chat_screen.dart';
import 'package:frontend/services/auth_service.dart';
import '../components/signup/form_section.dart';
import '../components/signup/header_section.dart';
import '../components/signup/login_redirect.dart';
import '../widgets/snack_bar.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController ncdsController = TextEditingController();
  bool isLoading = false;
  
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    ncdsController.dispose();
    super.dispose();
  }

  Future<String> signUpUser(String errorMessage) async {
    setState(() {
      isLoading = true;
    });
    
    try {
      String res = await AuthService().signUpUser(
        email: emailController.text,
        password: passwordController.text,
        name: nameController.text,
        phone: phoneController.text,
        ncds: ncdsController.text,
      );

      if (res == "success") {
        String userId = FirebaseAuth.instance.currentUser!.uid;
        await startChat();
        
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => ChatScreen(userId: userId),
        ));
        return res;
      } else {
        setState(() {
          isLoading = false;
        });
        showSnackBar(context, res);
        return res;
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      String errorMsg = e.toString();
      showSnackBar(context, errorMsg);
      return errorMsg;
    }
  }

  Future<void> startChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String userId = user.uid;
    final String apiUrl = "http://10.0.2.2:8080/start_chat?user_id=$userId";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("AI: ${data['response']}");
      } else {
        print("❌ Error: ${response.body}");
      }
    } catch (e) {
      print("❌ Connection Error: ${e.toString()}");
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
                  phoneController: phoneController,
                  ncdsController: ncdsController,
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