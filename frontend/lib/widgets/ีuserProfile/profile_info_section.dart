import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileInfoSection extends StatelessWidget {
  final Map<String, dynamic> userData;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;

  const ProfileInfoSection({
    Key? key,
    required this.userData,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModernSectionTitle('ข้อมูลส่วนตัว', primaryColor),
          _buildInfoItem('อีเมล', userData['email'] ?? 'ไม่มีข้อมูล', Icons.email_rounded),
          const SizedBox(height: 12),
          _buildInfoItem('เบอร์โทรศัพท์', userData['phone'] ?? 'ไม่มีข้อมูล', Icons.phone_rounded),
          const SizedBox(height: 12),
          NcdsInfoSection(
            ncds: userData.containsKey('ncds') ? (userData['ncds'] is List ? List<String>.from(userData['ncds']) : [userData['ncds']]) : [],
            primaryColor: primaryColor,
            accentColor: accentColor,
            textColor: textColor,
          ),
        ],
      ),
    );
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
            style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w600, color: textColor.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withOpacity(0.1),
                    primaryColor.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.prompt(fontSize: 14, color: textColor.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(Icons.info_outline_rounded, color: primaryColor.withOpacity(0.5), size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NcdsInfoSection extends StatelessWidget {
  final List<String> ncds;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;

  const NcdsInfoSection({
    Key? key,
    required this.ncds,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  child: Icon(Icons.medical_services_rounded, color: accentColor, size: 22),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'โรคประจำตัว',
                      style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
                    ),
                    Text(
                      'Non-Communicable Diseases',
                      style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ncds.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ไม่มีโรคประจำตัว',
                      style: GoogleFonts.prompt(fontSize: 15, color: textColor.withOpacity(0.7)),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: ncds.map((ncd) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ncd,
                          style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
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