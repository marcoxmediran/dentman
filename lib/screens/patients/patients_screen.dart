import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/database_provider.dart';
import '../../theme/app_theme.dart';
import 'patient_details_screen.dart';
import 'widgets/add_patient_bottom_sheet.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientsState = ref.watch(patientsStreamProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search patient by name or phone...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),
          const Divider(height: 1),

          // Patients List
          Expanded(
            child: patientsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading patients: $err')),
              data: (patients) {
                // Filter patients
                final filtered = patients.where((p) {
                  final nameMatch = p.fullName.toLowerCase().contains(_searchQuery);
                  final phoneMatch = p.phone.contains(_searchQuery);
                  return nameMatch || phoneMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No patients registered yet' : 'No patients match your search',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final patient = filtered[index];
                    final age = DateTime.now().year - patient.dob.year;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                          child: Text(
                            patient.fullName.trim().substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        title: Text(
                          patient.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${patient.gender} • $age years old (DOB: ${DateFormat('MM/dd/yyyy').format(patient.dob)})'),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 14, color: AppTheme.textMuted),
                                const SizedBox(width: 4),
                                Text(patient.phone, style: textTheme.bodySmall),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppTheme.primaryBlue),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PatientDetailsScreen(patientId: patient.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPatientDialog(context),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Patient'),
      ),
    );
  }

  void _showAddPatientDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddPatientBottomSheet(),
    );
  }
}
