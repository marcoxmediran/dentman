import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/dentist.dart';
import '../../../theme/app_theme.dart';

class DentistRosterCard extends StatelessWidget {
  final Dentist dentist;
  final double totalEarnings;
  final int totalCount;
  final VoidCallback onTap;

  const DentistRosterCard({
    super.key,
    required this.dentist,
    required this.totalEarnings,
    required this.totalCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Profile Initial Circle with unique color
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                child: Text(
                  dentist.name.isNotEmpty
                      ? dentist.name.split(' ').last.substring(0, 1).toUpperCase()
                      : 'D',
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            dentist.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status dot/pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: dentist.isActive
                                ? AppTheme.successGreen.withOpacity(0.1)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            dentist.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: dentist.isActive
                                  ? AppTheme.successGreen
                                  : AppTheme.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Metrics Row
                    Row(
                      children: [
                        // Treatments Count
                        Icon(Icons.assignment_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '$totalCount treatments',
                          style: textTheme.bodySmall,
                        ),
                        const SizedBox(width: 16),
                        // Earnings
                        const Icon(Icons.payments_outlined, size: 14, color: AppTheme.secondaryGold),
                        const SizedBox(width: 4),
                        Text(
                          NumberFormat.compactSimpleCurrency(name: 'PHP').format(totalEarnings),
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
