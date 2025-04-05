import 'package:flutter/material.dart';
import 'package:frontend/components/signup/input_field.dart';
import 'package:google_fonts/google_fonts.dart';

class FormSection extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController phoneController;
  final TextEditingController ncdsController;
  final bool isLoading;
  final Function(String) onSignUp;

  const FormSection({
    Key? key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.phoneController,
    required this.ncdsController,
    required this.isLoading,
    required this.onSignUp,
  }) : super(key: key);

  @override
  State<FormSection> createState() => _FormSectionState();
}

class _FormSectionState extends State<FormSection> {
  bool _obscurePassword = true;
  final List<String> _ncdsList = [
    'โรคเบาหวาน',
    'โรคความดันโลหิตสูง',
    'โรคหัวใจและหลอดเลือด',
    'โรคทางเดินหายใจเรื้อรัง',
    'โรคมะเร็ง',
    'โรคอ้วน',
  ];

  List<String> _selectedNCDs = [];

  @override
  void initState() {
    super.initState();
    widget.ncdsController.text =
        _selectedNCDs.isEmpty ? "None" : _selectedNCDs.join(", ");
  }

  void _handleSignUp() {
    if (widget.nameController.text.isEmpty) {
      _showErrorMessage("Please enter your full name");
      return;
    }
    if (widget.emailController.text.isEmpty) {
      _showErrorMessage("Please enter your email");
      return;
    }
    if (widget.phoneController.text.isEmpty) {
      _showErrorMessage("Please enter your phone number");
      return;
    }
    if (widget.passwordController.text.isEmpty) {
      _showErrorMessage("Please enter your password");
      return;
    }

    try {
      widget.onSignUp('');
      _showSuccessMessage("Registration successful!");
    } catch (e) {
      _showErrorMessage(e.toString());
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message, style: const TextStyle(fontSize: 16))),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(message, style: const TextStyle(fontSize: 16)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InputField(
          controller: widget.nameController,
          hintText: "Full Name",
          icon: Icons.person_outline,
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 16),
        InputField(
          controller: widget.emailController,
          hintText: "Email Address",
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        InputField(
          controller: widget.phoneController,
          hintText: "Phone Number",
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: widget.passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: "Password",
              hintStyle: GoogleFonts.poppins(color: Colors.black38),
              prefixIcon:
                  const Icon(Icons.lock_outline, color: Color(0xFF6C63FF)),
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                child: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.black38,
                ),
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.medical_services_outlined,
                      color: Color(0xFF6C63FF)),
                  const SizedBox(width: 12),
                  Text(
                    "Select Underlying NCDs (if any)",
                    style: GoogleFonts.poppins(color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text("None", style: GoogleFonts.poppins()),
                    selected: _selectedNCDs.isEmpty,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedNCDs.clear();
                        }
                        widget.ncdsController.text = "None";
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFFE0DEFF),
                    checkmarkColor: const Color(0xFF6C63FF),
                    side: const BorderSide(color: Color(0xFF6C63FF), width: 1),
                  ),
                  ..._ncdsList.map((ncd) {
                    return FilterChip(
                      label: Text(ncd, style: GoogleFonts.poppins()),
                      selected: _selectedNCDs.contains(ncd),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedNCDs.add(ncd);
                          } else {
                            _selectedNCDs.remove(ncd);
                          }

                          if (_selectedNCDs.isEmpty) {
                            widget.ncdsController.text = "None";
                          } else {
                            widget.ncdsController.text =
                                _selectedNCDs.join(", ");
                          }
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFFE0DEFF),
                      checkmarkColor: const Color(0xFF6C63FF),
                      side:
                          const BorderSide(color: Color(0xFF6C63FF), width: 1),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : _handleSignUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: widget.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    "Create Account",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
