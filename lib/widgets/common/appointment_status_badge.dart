import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppointmentStatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;

  const AppointmentStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 10,
    this.horizontalPadding = 8,
    this.verticalPadding = 4,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    final String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'scheduled':
        bg = AppTheme.primaryBlue.withOpacity(0.1);
        fg = AppTheme.primaryBlue;
        break;
      case 'completed':
        bg = AppTheme.successGreen.withOpacity(0.1);
        fg = AppTheme.successGreen;
        break;
      case 'cancelled':
        bg = AppTheme.errorRed.withOpacity(0.1);
        fg = AppTheme.errorRed;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
