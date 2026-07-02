import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/patient.dart';
import '../../../providers/database_provider.dart';
import '../../../theme/app_theme.dart';

class EditPatientBottomSheet extends ConsumerStatefulWidget {
  final Patient patient;
  const EditPatientBottomSheet({super.key, required this.patient});

  @override
  ConsumerState<EditPatientBottomSheet> createState() =>
      _EditPatientBottomSheetState();
}

class _EditPatientBottomSheetState
    extends ConsumerState<EditPatientBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _medHistoryController;
  late DateTime _selectedDob;
  late String _selectedGender;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient.fullName);
    _phoneController = TextEditingController(text: widget.patient.phone);
    _addressController = TextEditingController(
      text: widget.patient.homeAddress,
    );
    _medHistoryController = TextEditingController(
      text: widget.patient.medicalHistory,
    );
    _selectedDob = widget.patient.dob;
    _selectedGender = widget.patient.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _medHistoryController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedPatient = widget.patient.copyWith(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      homeAddress: _addressController.text.trim(),
      medicalHistory: _medHistoryController.text.trim(),
      dob: _selectedDob,
      gender: _selectedGender,
    );

    await ref.read(databaseRepositoryProvider).updatePatient(updatedPatient);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient records updated'),
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
                  Text('Edit Patient Profile', style: textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter patient\'s name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // DOB and Gender
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDob,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
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
                            _selectedDob = date;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        'DOB: ${DateFormat('MM/dd/yyyy').format(_selectedDob)}',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      value: _selectedGender,
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (String? val) {
                        if (val != null) {
                          setState(() {
                            _selectedGender = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Home Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Home Address',
                  prefixIcon: Icon(
                    Icons.home_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                keyboardType: TextInputType.streetAddress,
              ),
              const SizedBox(height: 16),

              // Medical History
              TextFormField(
                controller: _medHistoryController,
                decoration: const InputDecoration(
                  labelText: 'Medical History / Warnings',
                  prefixIcon: Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _save,
                child: const Text('Update Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
