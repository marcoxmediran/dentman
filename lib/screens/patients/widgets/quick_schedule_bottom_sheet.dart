import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/patient.dart';
import '../../../models/appointment.dart';
import '../../../providers/database_provider.dart';
import '../../../theme/app_theme.dart';

class QuickScheduleBottomSheet extends ConsumerStatefulWidget {
  final Patient patient;
  final Appointment? appointment;
  const QuickScheduleBottomSheet({
    super.key,
    required this.patient,
    this.appointment,
  });

  @override
  ConsumerState<QuickScheduleBottomSheet> createState() =>
      _QuickScheduleBottomSheetState();
}

class _QuickScheduleBottomSheetState
    extends ConsumerState<QuickScheduleBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.appointment != null) {
      _selectedDate = widget.appointment!.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.appointment!.dateTime);
      _notesController.text = widget.appointment!.notes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final appointmentTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final appointment = Appointment(
      id: widget.appointment?.id ?? '', // Reused or generated
      patientId: widget.patient.id,
      patientName: widget.patient.fullName,
      dateTime: appointmentTime,
      status: widget.appointment?.status ?? 'scheduled',
      notes: _notesController.text.trim(),
    );

    if (widget.appointment != null) {
      await ref.read(databaseRepositoryProvider).updateAppointment(appointment);
    } else {
      await ref.read(databaseRepositoryProvider).addAppointment(appointment);
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.appointment != null
                ? 'Appointment updated successfully'
                : 'Appointment scheduled successfully',
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.appointment != null
                        ? 'Edit Appointment Details'
                        : 'Schedule Appointment',
                    style: textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Scheduling for: ${widget.patient.fullName}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),

              // Date and Time Pickers
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppTheme.primaryBlue,
                                  onPrimary: Colors.white,
                                  onSurface: AppTheme.textDark,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppTheme.primaryBlue,
                                  onPrimary: Colors.white,
                                  onSurface: AppTheme.textDark,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (time != null) {
                          setState(() {
                            _selectedTime = time;
                          });
                        }
                      },
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(_selectedTime.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes Input
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Appointment Notes / Reason',
                  prefixIcon: Icon(
                    Icons.description_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _save,
                child: const Text('Schedule Appointment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
