import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/ีuserProfile/profile_widgets.dart';

class UserProfileScreen extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;

  const UserProfileScreen({
    Key? key,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
  }) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isEditing = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  List<String> selectedNcds = [];
  final List<String> availableNcds = [
    'โรคเบาหวาน',
    'โรคความดันโลหิตสูง',
    'โรคหัวใจและหลอดเลือด',
    'โรคทางเดินหายใจเรื้อรัง',
    'โรคมะเร็ง',
    'โรคอ้วน',
  ];

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> getUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final userDoc =
            await _firestore.collection("users").doc(currentUser.uid).get();
        if (userDoc.exists) {
          setState(() {
            userData = userDoc.data();
            _nameController.text = userData?['name'] ?? '';
            _emailController.text = userData?['email'] ?? '';
            _phoneController.text = userData?['phone'] ?? '';

            if (userData?['ncds'] is List) {
              selectedNcds = List<String>.from(userData?['ncds'] ?? []);
            } else if (userData?['ncds'] is String &&
                userData?['ncds'].isNotEmpty) {
              selectedNcds = [userData?['ncds']];
            }
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection("users").doc(currentUser.uid).update({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'ncds': selectedNcds,
        });
        await getUserData();
        setState(() {
          isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกข้อมูลสำเร็จ', style: GoogleFonts.prompt()),
            backgroundColor: widget.primaryColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      print("Error updating user data: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
              style: GoogleFonts.prompt()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'โปรไฟล์',
          style: GoogleFonts.prompt(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: widget.textColor),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: widget.textColor, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.close_rounded : Icons.edit_rounded,
                size: 24),
            color: isEditing ? Colors.grey[700] : widget.primaryColor,
            onPressed: () {
              setState(() {
                if (isEditing) {
                  isEditing = false;
                  _nameController.text = userData?['name'] ?? '';
                  _phoneController.text = userData?['phone'] ?? '';
                  if (userData?['ncds'] is List) {
                    selectedNcds = List<String>.from(userData?['ncds'] ?? []);
                  } else if (userData?['ncds'] is String &&
                      userData?['ncds'].isNotEmpty) {
                    selectedNcds = [userData?['ncds']];
                  } else {
                    selectedNcds = [];
                  }
                } else {
                  isEditing = true;
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: widget.primaryColor))
          : userData == null
              ? ProfileEmptyState(
                  primaryColor: widget.primaryColor,
                  textColor: widget.textColor)
              : ProfileContent(
                  userData: userData!,
                  isEditing: isEditing,
                  nameController: _nameController,
                  emailController: _emailController,
                  phoneController: _phoneController,
                  selectedNcds: selectedNcds,
                  availableNcds: availableNcds,
                  primaryColor: widget.primaryColor,
                  accentColor: widget.accentColor,
                  textColor: widget.textColor,
                  updateSelectedNcds: (List<String> updatedNcds) {
                    setState(() {
                      selectedNcds = updatedNcds;
                    });
                  },
                ),
      bottomNavigationBar: isEditing
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: updateUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'บันทึกข้อมูล',
                  style: GoogleFonts.prompt(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
              ),
            )
          : null,
    );
  }
}