import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/dentist.dart';
import '../../providers/database_provider.dart';
import '../../theme/app_theme.dart';
import 'dentist_detail_screen.dart';
import 'widgets/clinic_overview_card.dart';
import 'widgets/dentist_roster_card.dart';

class DentistsScreen extends ConsumerWidget {
  const DentistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dentistsState = ref.watch(dentistsStreamProvider);
    final treatmentsState = ref.watch(allTreatmentsStreamProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: dentistsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading dentists: $err')),
        data: (dentists) {
          return treatmentsState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading treatments: $err')),
            data: (treatments) {
              // Calculate overall clinic metrics
              final totalClinicEarnings = treatments.fold<double>(0.0, (sum, t) => sum + t.cost);
              final totalClinicTreatments = treatments.length;

              if (dentists.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No dentists registered yet',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add dentists in the Settings tab',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return CustomScrollView(
                slivers: [
                  // Clinic Performance Card
                  SliverToBoxAdapter(
                    child: ClinicOverviewCard(
                      totalClinicEarnings: totalClinicEarnings,
                      totalClinicTreatments: totalClinicTreatments,
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          const Icon(Icons.people, color: AppTheme.primaryBlue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Dentist Performance Roster',
                            style: textTheme.titleMedium?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Dentists List
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final Dentist dentist = dentists[index];
                          // Compute stats for this dentist
                          final dentistTreatments = treatments
                              .where((t) => t.dentistName.trim().toLowerCase() == dentist.name.trim().toLowerCase())
                              .toList();
                          final totalEarnings = dentistTreatments.fold<double>(0.0, (sum, t) => sum + t.cost);
                          final totalCount = dentistTreatments.length;

                          return DentistRosterCard(
                            dentist: dentist,
                            totalEarnings: totalEarnings,
                            totalCount: totalCount,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DentistDetailScreen(dentist: dentist),
                                ),
                              );
                            },
                          );
                        },
                        childCount: dentists.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
