import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/patient.dart';
import '../../../models/appointment.dart';
import '../../../providers/database_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/appointment_status_badge.dart';
import 'quick_schedule_bottom_sheet.dart';

class PatientAppointmentsTab extends ConsumerWidget {
  final Patient patient;

  const PatientAppointmentsTab({super.key, required this.patient});

  void _showQuickScheduleDialog(BuildContext context, Patient patient, {Appointment? appointment}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickScheduleBottomSheet(patient: patient, appointment: appointment),
    );
  }

  void _updateAppointmentStatus(BuildContext context, WidgetRef ref, Appointment appointment, String newStatus) async {
    final updated = appointment.copyWith(status: newStatus);
    await ref.read(databaseRepositoryProvider).updateAppointment(updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment marked as $newStatus'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmDeleteAppointment(BuildContext context, WidgetRef ref, Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: const Text(
          'Are you sure you want to delete this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(databaseRepositoryProvider)
                  .deleteAppointment(appointment.id);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Appointment deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsState = ref.watch(appointmentsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Schedule History',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              ElevatedButton.icon(
                onPressed: () => _showQuickScheduleDialog(context, patient),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Schedule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: appointmentsState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (appointments) {
              // Filter to this patient's appointments
              final filtered = appointments
                  .where((a) => a.patientId == patient.id)
                  .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No appointments scheduled.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              _showQuickScheduleDialog(context, patient),
                          child: const Text('Schedule First Appointment'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final appointment = filtered[index];
                  final isUpcoming = appointment.status == 'scheduled';
                  final timeStr = DateFormat(
                    'EEE, MMM d, yyyy • h:mm a',
                  ).format(appointment.dateTime);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Row(
                                children: [
                                  AppointmentStatusBadge(status: appointment.status),
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      size: 18,
                                      color: AppTheme.textMuted,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showQuickScheduleDialog(
                                          context,
                                          patient,
                                          appointment: appointment,
                                        );
                                      } else if (value == 'delete') {
                                        _confirmDeleteAppointment(
                                          context,
                                          ref,
                                          appointment,
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 16),
                                            SizedBox(width: 8),
                                            Text('Edit Appointment'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              size: 16,
                                              color: AppTheme.errorRed,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: AppTheme.errorRed,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),

                          if (appointment.notes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Notes: ${appointment.notes}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          if (isUpcoming) ...[
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _updateAppointmentStatus(
                                    context,
                                    ref,
                                    appointment,
                                    'cancelled',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.errorRed,
                                    side: const BorderSide(
                                      color: AppTheme.errorRed,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _updateAppointmentStatus(
                                    context,
                                    ref,
                                    appointment,
                                    'completed',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.successGreen,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                  ),
                                  child: const Text('Mark Completed'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
