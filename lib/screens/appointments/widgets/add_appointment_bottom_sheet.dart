import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/patient.dart';
import '../../../models/appointment.dart';
import '../../../providers/database_provider.dart';
import '../../../theme/app_theme.dart';

class AddAppointmentBottomSheet extends ConsumerStatefulWidget {
  final Appointment? appointment;
  const AddAppointmentBottomSheet({super.key, this.appointment});

  @override
  ConsumerState<AddAppointmentBottomSheet> createState() =>
      _AddAppointmentBottomSheetState();
}

class _AddAppointmentBottomSheetState
    extends ConsumerState<AddAppointmentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  Patient? _selectedPatient;
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
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
      patientId: _selectedPatient!.id,
      patientName: _selectedPatient!.fullName,
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
    final patientsState = ref.watch(patientsStreamProvider);
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
                  Text('Schedule Appointment', style: textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Patient Selector
              patientsState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error loading patients: $err'),
                data: (patients) {
                  if (patients.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'No patients registered yet. Create a patient first.',
                        style: TextStyle(
                          color: AppTheme.errorRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  // Initialize selected patient if editing
                  if (widget.appointment != null && _selectedPatient == null) {
                    try {
                      _selectedPatient = patients.firstWhere(
                        (p) => p.id == widget.appointment!.patientId,
                      );
                    } catch (_) {}
                  }

                  return DropdownButtonFormField<Patient>(
                    decoration: const InputDecoration(
                      labelText: 'Select Patient',
                      prefixIcon: Icon(
                        Icons.person,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    value: _selectedPatient,
                    items: patients.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(p.fullName),
                      );
                    }).toList(),
                    onChanged: widget.appointment != null
                        ? null // Disable editing patient during reschedule
                        : (Patient? newValue) {
                            setState(() {
                              _selectedPatient = newValue;
                            });
                          },
                    validator: (value) =>
                        value == null ? 'Patient is required' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Date Picker Field
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
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Time Picker Field
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
                      icon: const Icon(Icons.access_time),
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
                  hintText: 'e.g., Scaling & clean, sensitivity check',
                  prefixIcon: Icon(
                    Icons.description,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Action buttons
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
