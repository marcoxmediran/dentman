import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/patient.dart';
import '../../../models/treatment.dart';
import '../../../providers/database_provider.dart';
import '../../../theme/app_theme.dart';
import 'add_treatment_bottom_sheet.dart';

class PatientTreatmentsTab extends ConsumerWidget {
  final Patient patient;

  const PatientTreatmentsTab({super.key, required this.patient});

  void _showAddTreatmentDialog(
    BuildContext context,
    String patientId, {
    Treatment? treatment,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AddTreatmentBottomSheet(patientId: patientId, treatment: treatment),
    );
  }

  void _confirmDeleteTreatment(
    BuildContext context,
    WidgetRef ref,
    Treatment treatment,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Treatment Record'),
        content: const Text(
          'Are you sure you want to delete this treatment record? This action cannot be undone.',
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
                  .deleteTreatment(treatment.id, treatment.patientId);

              // We check context.mounted since this is an async gap in a StatelessWidget context
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Treatment record deleted'),
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
    final treatmentsState = ref.watch(
      patientTreatmentsStreamProvider(patient.id),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Total stats summary and log button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              treatmentsState.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (treatments) {
                  final totalSpent = treatments.fold<double>(
                    0,
                    (sum, t) => sum + t.cost,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total: ${treatments.length} treatments',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Total Cost: ₱${totalSpent.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddTreatmentDialog(context, patient.id),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Log Treatment'),
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
          child: treatmentsState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                Center(child: Text('Error loading treatments: $err')),
            data: (treatments) {
              if (treatments.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_edu,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No treatment records registered.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              _showAddTreatmentDialog(context, patient.id),
                          child: const Text('Add First Treatment'),
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
                itemCount: treatments.length,
                itemBuilder: (context, index) {
                  final treatment = treatments[index];
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  treatment.category,
                                  style: const TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '₱${treatment.cost.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
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
                                        _showAddTreatmentDialog(
                                          context,
                                          treatment.patientId,
                                          treatment: treatment,
                                        );
                                      } else if (value == 'delete') {
                                        _confirmDeleteTreatment(
                                          context,
                                          ref,
                                          treatment,
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
                          const SizedBox(height: 8),
                          if (treatment.notes.isNotEmpty) ...[
                            Text(
                              treatment.notes,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'By ${treatment.dentistName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'MMM d, yyyy',
                                ).format(treatment.date),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
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
