import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/dentist.dart';
import '../../providers/database_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addDentist() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final newDentist = Dentist(id: '', name: name);
      
      try {
        final repo = ref.read(databaseRepositoryProvider);
        await repo.addDentist(newDentist);
        _nameController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name added successfully!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add dentist: $e'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteDentist(Dentist dentist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Dentist'),
        content: Text(
          'Are you sure you want to remove ${dentist.name}? Historical treatment records will keep their name, but you will not be able to select them for new treatments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(databaseRepositoryProvider);
        await repo.deleteDentist(dentist.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${dentist.name} removed successfully.'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove dentist: $e'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dentistsAsync = ref.watch(dentistsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card / Info panel
            Card(
              elevation: 0,
              color: AppTheme.primaryBlue.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.1)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.primaryBlue,
                      size: 28,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dentist Directory',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage the roster of dentists active in this clinic. These names populate the selector when logging treatments.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Form to Add Dentist
            Text(
              'Add New Dentist',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'e.g., Dr. Elizabeth Blackwell',
                            prefixIcon: Icon(Icons.person_outline),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _addDentist,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // List of Dentists
            Text(
              'Active Dentists',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            dentistsAsync.when(
              data: (dentists) {
                if (dentists.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: AppTheme.textMuted.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No dentists in directory',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Add a dentist above to get started.',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dentists.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final dentist = dentists[index];
                    final initials = dentist.name.length >= 5
                        ? dentist.name.replaceAll('Dr. ', '').substring(0, 1).toUpperCase()
                        : (dentist.name.isNotEmpty ? dentist.name[0].toUpperCase() : 'D');

                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                          foregroundColor: AppTheme.primaryBlue,
                          child: Text(
                            initials,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          dentist.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppTheme.errorRed,
                          ),
                          onPressed: () => _deleteDentist(dentist),
                          tooltip: 'Remove Dentist',
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Card(
                color: AppTheme.errorRed.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.errorRed),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Error loading dentists: $err',
                          style: const TextStyle(color: AppTheme.errorRed),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
