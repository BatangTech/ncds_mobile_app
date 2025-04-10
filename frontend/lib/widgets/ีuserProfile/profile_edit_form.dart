import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileEditForm extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final List<String> selectedNcds;
  final List<String> availableNcds;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;
  final Function(List<String>) updateSelectedNcds;

  const ProfileEditForm({
    Key? key,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.selectedNcds,
    required this.availableNcds,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
    required this.updateSelectedNcds,
  }) : super(key: key);

  @override
  State<ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends State<ProfileEditForm> {
  late List<String> _currentSelectedNcds;

  @override
  void initState() {
    super.initState();
    _currentSelectedNcds = List<String>.from(widget.selectedNcds);
    debugPrint("Initial selected NCDs: $_currentSelectedNcds");
  }

  @override
  void didUpdateWidget(ProfileEditForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedNcds != widget.selectedNcds) {
      setState(() {
        _currentSelectedNcds = List<String>.from(widget.selectedNcds);
      });
      debugPrint("Updated selected NCDs: $_currentSelectedNcds");
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        "Building ProfileEditForm with selected NCDs: $_currentSelectedNcds");
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModernSectionTitle('ข้อมูลส่วนตัว', widget.primaryColor),
          _buildEditInfoField(
            icon: Icons.email_rounded,
            title: 'อีเมล',
            controller: widget.emailController,
            readOnly: true,
            helperText: 'ไม่สามารถแก้ไขอีเมลได้',
          ),
          const SizedBox(height: 12),
          _buildEditInfoField(
            icon: Icons.phone_rounded,
            title: 'เบอร์โทรศัพท์',
            controller: widget.phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          NcdsEditSection(
            selectedNcds: _currentSelectedNcds,
            availableNcds: widget.availableNcds,
            primaryColor: widget.primaryColor,
            accentColor: widget.accentColor,
            textColor: widget.textColor,
            updateSelectedNcds: _handleNcdsUpdate,
          ),
        ],
      ),
    );
  }

  void _handleNcdsUpdate(List<String> updatedNcds) {
    setState(() {
      _currentSelectedNcds = updatedNcds;
    });
    widget.updateSelectedNcds(updatedNcds);
    debugPrint("NCDs updated: $_currentSelectedNcds");
  }

  Widget _buildModernSectionTitle(String title, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.prompt(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.textColor.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildEditInfoField({
    required IconData icon,
    required String title,
    required TextEditingController controller,
    bool readOnly = false,
    String? helperText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.primaryColor.withOpacity(0.1),
                        widget.primaryColor.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: widget.primaryColor, size: 22),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.prompt(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: widget.textColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              readOnly: readOnly,
              keyboardType: keyboardType,
              style: GoogleFonts.prompt(fontSize: 15, color: widget.textColor),
              decoration: InputDecoration(
                filled: true,
                fillColor: readOnly ? const Color(0xFFF5F5F7) : Colors.white,
                hintText: readOnly ? '' : 'กรอก$title',
                hintStyle:
                    GoogleFonts.prompt(fontSize: 15, color: Colors.grey[400]),
                helperText: helperText,
                helperStyle:
                    GoogleFonts.prompt(fontSize: 12, color: Colors.grey[500]),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: widget.primaryColor, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NcdsEditSection extends StatelessWidget {
  final List<String> selectedNcds;
  final List<String> availableNcds;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;
  final Function(List<String>) updateSelectedNcds;

  const NcdsEditSection({
    Key? key,
    required this.selectedNcds,
    required this.availableNcds,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
    required this.updateSelectedNcds,
  }) : super(key: key);

  bool _isNcdSelected(String ncd) {
    for (String selectedNcd in selectedNcds) {
      if (selectedNcd == ncd) {
        return true;
      }
      if (ncd.startsWith("โรค") && selectedNcd == ncd.substring(3)) {
        return true;
      }
      if (selectedNcd.startsWith("โรค") && ncd == selectedNcd.substring(3)) {
        return true;
      }
      if (selectedNcd.contains(ncd) || ncd.contains(selectedNcd)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("NcdsEditSection - Available NCDs: $availableNcds");
    debugPrint("NcdsEditSection - Selected NCDs: $selectedNcds");
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withOpacity(0.1),
                        accentColor.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.medical_services_rounded,
                      color: accentColor, size: 22),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'โรคประจำตัว (NCDs)',
                      style: GoogleFonts.prompt(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor),
                    ),
                    Text(
                      'Non-Communicable Diseases',
                      style: GoogleFonts.prompt(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: availableNcds.map((ncd) {
                final isSelected = _isNcdSelected(ncd);
                debugPrint("NCD: $ncd, Is Selected: $isSelected");

                return InkWell(
                  onTap: () {
                    List<String> updatedNcds;
                    if (isSelected) {
                      updatedNcds = selectedNcds.where((item) {
                        if (item == ncd) return false;
                        if (item == "โรค$ncd") return false;
                        if (ncd == "โรค$item") return false;
                        return true;
                      }).toList();
                    } else {
                      updatedNcds = [...selectedNcds, ncd];
                    }

                    debugPrint("Updating NCDs to: $updatedNcds");
                    updateSelectedNcds(updatedNcds);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? primaryColor : const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      ncd,
                      style: GoogleFonts.prompt(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : textColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}