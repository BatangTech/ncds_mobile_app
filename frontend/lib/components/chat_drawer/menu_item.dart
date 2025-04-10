import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color primaryColor;
  final Color textColor;
  final bool isDestructive;
  final String? description;

  const DrawerMenuItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.primaryColor,
    required this.textColor,
    this.isDestructive = false,
    this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor:
                (isDestructive ? primaryColor : primaryColor).withOpacity(0.05),
            highlightColor:
                (isDestructive ? primaryColor : primaryColor).withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  _buildIconContainer(),
                  const SizedBox(width: 16),
                  _buildTitleAndDescription(),
                  _buildArrowIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.2)
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: primaryColor,
        size: 22,
      ),
    );
  }

  Widget _buildTitleAndDescription() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.prompt(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDestructive ? primaryColor : textColor,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 2),
            Text(
              description!,
              style: GoogleFonts.prompt(
                fontSize: 12,
                color: textColor.withOpacity(0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArrowIndicator() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.arrow_forward_ios_rounded,
          color: primaryColor.withOpacity(0.5),
          size: 14,
        ),
      ),
    );
  }
}
