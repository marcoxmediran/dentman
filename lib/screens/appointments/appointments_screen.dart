import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../providers/database_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/appointment_status_badge.dart';
import 'widgets/add_appointment_bottom_sheet.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsState = ref.watch(appointmentsStreamProvider);

    return Scaffold(
      body: Column(
        children: [
          // Subheader for Filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryBlue,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textMuted,
              dividerHeight: 0,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past History'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main Appointments List
          Expanded(
            child: appointmentsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Error loading appointments: $err')),
              data: (appointments) {
                // Split into upcoming and past
                final upcoming = appointments
                    .where((a) => a.status == 'scheduled')
                    .toList();
                final past = appointments
                    .where((a) => a.status != 'scheduled')
                    .toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAppointmentsList(upcoming, isUpcoming: true),
                    _buildAppointmentsList(past, isUpcoming: false),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAppointmentDialog(context),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Schedule'),
      ),
    );
  }

  Widget _buildAppointmentsList(
    List<Appointment> list, {
    required bool isUpcoming,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming
                  ? Icons.event_available_outlined
                  : Icons.history_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming
                  ? 'No upcoming appointments scheduled'
                  : 'No past appointment history found',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final appointment = list[index];
        final timeStr = DateFormat(
          'EEE, MMM d, yyyy • h:mm a',
        ).format(appointment.dateTime);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        appointment.patientName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    AppointmentStatusBadge(status: appointment.status),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        size: 20,
                        color: AppTheme.textMuted,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditAppointmentDialog(context, appointment);
                        } else if (value == 'delete') {
                          _confirmDeleteAppointment(context, appointment);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edit Details'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppTheme.errorRed,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: AppTheme.errorRed),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
                if (appointment.notes.isNotEmpty) ...[
                  const Divider(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.notes,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          appointment.notes,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (isUpcoming) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            _updateAppointmentStatus(appointment, 'cancelled'),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorRed,
                          side: const BorderSide(color: AppTheme.errorRed),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _updateAppointmentStatus(appointment, 'completed'),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
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
  }

  void _updateAppointmentStatus(
    Appointment appointment,
    String newStatus,
  ) async {
    final updated = appointment.copyWith(status: newStatus);
    await ref.read(databaseRepositoryProvider).updateAppointment(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment marked as $newStatus'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddAppointmentDialog(
    BuildContext context, {
    Appointment? appointment,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAppointmentBottomSheet(appointment: appointment),
    );
  }

  void _showEditAppointmentDialog(
    BuildContext context,
    Appointment appointment,
  ) {
    _showAddAppointmentDialog(context, appointment: appointment);
  }

  void _confirmDeleteAppointment(
    BuildContext context,
    Appointment appointment,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: Text(
          'Are you sure you want to delete the appointment for ${appointment.patientName}?',
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
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Appointment deleted successfully'),
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
}
