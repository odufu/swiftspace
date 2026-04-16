import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_constants.dart';
import '../error/app_exception.dart';

class UiUtils {
  static void showSuccess(BuildContext context, String message) {
    _showCustomSnackBar(
      context,
      message: message,
      icon: LucideIcons.checkCircle,
      backgroundColor: const Color(0xFFE8F5E9),
      borderColor: AppColors.primaryLight,
      iconColor: AppColors.primaryLight,
      textColor: const Color(0xFF1B5E20),
    );
  }

  static void showError(BuildContext context, dynamic error) {
    String message = error.toString();
    if (error is AppException) {
      message = error.message;
    }
    
    _showCustomSnackBar(
      context,
      message: message,
      icon: LucideIcons.alertCircle,
      backgroundColor: const Color(0xFFFFEBEE),
      borderColor: AppColors.error,
      iconColor: AppColors.error,
      textColor: const Color(0xFFB71C1C),
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showCustomSnackBar(
      context,
      message: message,
      icon: LucideIcons.info,
      backgroundColor: const Color(0xFFE3F2FD),
      borderColor: Colors.blue,
      iconColor: Colors.blue,
      textColor: const Color(0xFF0D47A1),
    );
  }

  static void _showCustomSnackBar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color borderColor,
    required Color iconColor,
    required Color textColor,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();
    
    scaffoldMessenger.showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor.withValues(alpha: 0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: borderColor.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
