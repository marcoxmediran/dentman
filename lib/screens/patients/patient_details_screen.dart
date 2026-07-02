import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/patient.dart';
import '../../providers/database_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/edit_patient_bottom_sheet.dart';
import 'widgets/patient_treatments_tab.dart';
import 'widgets/patient_appointments_tab.dart';

class PatientDetailsScreen extends ConsumerStatefulWidget {
  final String patientId;
  const PatientDetailsScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends ConsumerState<PatientDetailsScreen>
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
    final patientsState = ref.watch(patientsStreamProvider);
    final textTheme = Theme.of(context).textTheme;

    return patientsState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (patients) {
        // Find current patient
        final patient = patients.firstWhere(
          (p) => p.id == widget.patientId,
          orElse: () => Patient(
            id: '',
            fullName: 'Unknown Patient',
            dob: DateTime.now(),
            gender: '',
            phone: '',
            homeAddress: '',
            medicalHistory: '',
            createdAt: DateTime.now(),
          ),
        );

        if (patient.id.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Patient not found.')),
          );
        }

        final age = DateTime.now().year - patient.dob.year;

        return Scaffold(
          appBar: AppBar(
            title: Text(patient.fullName),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Profile',
                onPressed: () => _showEditPatientDialog(context, patient),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Patient Profile Summary Card
                Container(
                  color: AppTheme.primaryBlue,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Card(
                    elevation: 4,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppTheme.primaryBlue
                                    .withOpacity(0.1),
                                child: Text(
                                  patient.fullName
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patient.fullName,
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${patient.gender} • $age years',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          // Contact Details
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_android,
                                size: 18,
                                color: AppTheme.primaryBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                patient.phone,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(width: 64),
                              const Icon(
                                Icons.calendar_month_outlined,
                                size: 18,
                                color: AppTheme.primaryBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('MM/dd/yyyy').format(patient.dob),
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Icon(
                                Icons.home_outlined,
                                size: 18,
                                color: AppTheme.primaryBlue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  patient.homeAddress.isNotEmpty
                                      ? patient.homeAddress
                                      : 'No address provided',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: patient.homeAddress.isNotEmpty
                                        ? AppTheme.textDark
                                        : AppTheme.textMuted,
                                    fontStyle: patient.homeAddress.isNotEmpty
                                        ? FontStyle.normal
                                        : FontStyle.italic,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          // Medical Alerts Block (Yellow Highlight)
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryGold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.secondaryGold.withOpacity(0.5),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 18,
                                      color: Colors.orange.shade800,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Medical History & Allergies',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  patient.medicalHistory.isNotEmpty
                                      ? patient.medicalHistory
                                      : 'No medical conditions or allergies declared.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade900,
                                    fontStyle: patient.medicalHistory.isNotEmpty
                                        ? FontStyle.normal
                                        : FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Tab Bar for Appointments & Treatments
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primaryBlue,
                    labelColor: AppTheme.primaryBlue,
                    unselectedLabelColor: AppTheme.textMuted,
                    dividerHeight: 0,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    tabs: const [
                      Tab(text: 'Treatments Log'),
                      Tab(text: 'Appointments'),
                    ],
                  ),
                ),

                // 3. Tab Contents
                Container(
                  constraints: BoxConstraints(
                    minHeight: 300,
                    maxHeight: MediaQuery.of(context).size.height - 350,
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      PatientTreatmentsTab(patient: patient),
                      PatientAppointmentsTab(patient: patient),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Dialog to Edit Patient Profile details
  void _showEditPatientDialog(BuildContext context, Patient patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditPatientBottomSheet(patient: patient),
    );
  }
}
