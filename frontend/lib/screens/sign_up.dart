import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/Widget/snack_bar.dart';
import 'package:frontend/screens/chat_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/services/auth_service.dart';

import '../Widget/button.dart';
import '../Widget/text_filed.dart';

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

  void despose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
  }

  void signUpUser() async {
    String res = await AuthService().signUpUser(
      email: emailController.text,
      password: passwordController.text,
      name: nameController.text,
    );

    if (res == "success") {
      setState(() {
        isLoading = true;
      });

      String userId = FirebaseAuth.instance.currentUser!.uid;

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
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                height: height / 2.7,
                child: Image.asset("assets/images/signup.png", height: 289.3),
              ),
              TextFiledInput(
                  textEditingController: nameController,
                  hintText: "Enter your name",
                  icon: Icons.person),
              TextFiledInput(
                  textEditingController: emailController,
                  hintText: "Enter your email",
                  icon: Icons.email),
              TextFiledInput(
                  textEditingController: passwordController,
                  hintText: "Enter your password",
                  isPass: true,
                  icon: Icons.lock),
              MyButton(onTab: signUpUser, text: "Sign Up"),
              SizedBox(height: height / 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(fontSize: 16),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Login",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
