import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/treatment.dart';
import '../../../providers/database_provider.dart';
import '../../../theme/app_theme.dart';
import '../../settings/settings_screen.dart';

class AddTreatmentBottomSheet extends ConsumerStatefulWidget {
  final String patientId;
  final Treatment? treatment;
  const AddTreatmentBottomSheet({
    super.key,
    required this.patientId,
    this.treatment,
  });

  @override
  ConsumerState<AddTreatmentBottomSheet> createState() =>
      _AddTreatmentBottomSheetState();
}

class _AddTreatmentBottomSheetState
    extends ConsumerState<AddTreatmentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = 'Cleaning';
  String _selectedDentist = '';
  final _notesController = TextEditingController();
  final _costController = TextEditingController(text: '1000.00');
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.treatment != null) {
      _selectedCategory = widget.treatment!.category;
      _selectedDentist = widget.treatment!.dentistName;
      _notesController.text = widget.treatment!.notes;
      _costController.text = widget.treatment!.cost.toStringAsFixed(2);
      _selectedDate = widget.treatment!.date;
    }
  }

  final List<String> _categories = const [
    'Consultation',
    'Cleaning',
    'Filling',
    'Extraction',
    'Crown',
    'Braces',
    'Braces Adjustment',
    'Full Denture',
    'Fixed Partial Denture',
    'Root Canal',
    'Other',
  ];

  // Helper values to suggest pricing depending on category
  void _onCategoryChanged(String? category) {
    if (category == null) return;
    setState(() {
      _selectedCategory = category;
      // Provide generic pricing hints to make inputting faster
      switch (category) {
        case 'Consultation':
          _costController.text = '500.00';
          break;
        case 'Cleaning':
          _costController.text = '1000.00';
          break;
        case 'Filling':
          _costController.text = '1500.00';
          break;
        case 'Extraction':
          _costController.text = '1000.00';
          break;
        case 'Crown':
          _costController.text = '10000.00';
          break;
        case 'Braces':
          _costController.text = '15000.00';
          break;
        case 'Braces Adjustment':
          _costController.text = '1000.00';
          break;
        case 'Full Denture':
          _costController.text = '18000.00';
          break;
        case 'Fixed Partial Denture':
          _costController.text = '9000.00';
          break;
        case 'Root Canal':
          _costController.text = '10000.00';
          break;
        default:
          _costController.text = '0.00';
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final cost = double.tryParse(_costController.text.trim()) ?? 0.0;

    final treatment = Treatment(
      id: widget.treatment?.id ?? '', // Reused or generated
      patientId: widget.patientId,
      dentistName: _selectedDentist,
      category: _selectedCategory,
      notes: _notesController.text.trim(),
      cost: cost,
      date: _selectedDate,
    );

    if (widget.treatment != null) {
      await ref.read(databaseRepositoryProvider).updateTreatment(treatment);
    } else {
      await ref.read(databaseRepositoryProvider).addTreatment(treatment);
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Treatment logged successfully'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dentistsAsync = ref.watch(dentistsStreamProvider);
    final hasDentists = dentistsAsync.maybeWhen(
      data: (list) {
        if (list.isNotEmpty) return true;
        if (widget.treatment != null && widget.treatment!.dentistName.isNotEmpty) return true;
        return false;
      },
      orElse: () => true,
    );

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
                    widget.treatment != null
                        ? 'Edit Treatment Details'
                        : 'Log Done Treatment',
                    style: textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Treatment Category',
                  prefixIcon: Icon(
                    Icons.category_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                value: _selectedCategory,
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: _onCategoryChanged,
              ),
              const SizedBox(height: 16),

              // Dentist selector
              dentistsAsync.when(
                data: (dentistsList) {
                  final List<String> dentistNames = dentistsList
                      .map((d) => d.name)
                      .toList();

                  if (widget.treatment != null) {
                    final originalDentist = widget.treatment!.dentistName;
                    if (originalDentist.isNotEmpty &&
                        !dentistNames.contains(originalDentist)) {
                      dentistNames.insert(0, originalDentist);
                    }
                  }

                  // If _selectedDentist is not in the list, set it to the first item (if available)
                  if (dentistNames.isNotEmpty &&
                      !dentistNames.contains(_selectedDentist)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedDentist = dentistNames.first;
                        });
                      }
                    });
                  }

                  if (dentistNames.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.errorRed.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppTheme.errorRed,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No dentists registered',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.errorRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You must configure at least one active dentist in the clinic roster before you can log treatments.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context); // Close bottom sheet
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.settings, size: 16),
                            label: const Text('Go to Settings'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final items = dentistNames
                      .map(
                        (name) => DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        ),
                      )
                      .toList();

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Performing Dentist',
                      prefixIcon: Icon(
                        Icons.medical_services_outlined,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    value: _selectedDentist,
                    items: items,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a dentist (configure in Settings)';
                      }
                      return null;
                    },
                    onChanged: (String? val) {
                      if (val != null) {
                        setState(() {
                          _selectedDentist = val;
                        });
                      }
                    },
                  );
                },
                loading: () => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Performing Dentist',
                    prefixIcon: Icon(
                      Icons.medical_services_outlined,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  value: '',
                  items: const [
                    DropdownMenuItem(
                      value: '',
                      child: Text('Loading dentists...'),
                    ),
                  ],
                  onChanged: null,
                ),
                error: (err, stack) => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Performing Dentist',
                    prefixIcon: Icon(
                      Icons.error_outline,
                      color: AppTheme.errorRed,
                    ),
                  ),
                  value: '',
                  items: const [
                    DropdownMenuItem(
                      value: '',
                      child: Text('Error loading dentists'),
                    ),
                  ],
                  onChanged: null,
                ),
              ),
              const SizedBox(height: 16),

              // Treatment Date Picker Field
              OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(1970),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
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
                label: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  alignment: Alignment.centerLeft,
                ),
              ),
              const SizedBox(height: 16),

              // Cost
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Cost (₱)',
                  prefixIcon: Icon(Icons.money, color: AppTheme.primaryBlue),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter cost';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid numeric value';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes / Specific Teeth
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Detailed notes / Treated teeth',
                  hintText: 'e.g., Tooth #14, composite restoration occlusal.',
                  prefixIcon: Icon(
                    Icons.description_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: hasDentists ? _save : null,
                child: const Text('Save Treatment Record'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
