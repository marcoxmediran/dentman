import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/dentist.dart';
import '../../models/treatment.dart';
import '../../providers/database_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/dentist_metric_card.dart';

class DentistDetailScreen extends ConsumerStatefulWidget {
  final Dentist dentist;
  const DentistDetailScreen({super.key, required this.dentist});

  @override
  ConsumerState<DentistDetailScreen> createState() => _DentistDetailScreenState();
}

class _DentistDetailScreenState extends ConsumerState<DentistDetailScreen> {
  String _timeframe = 'All Time'; // 'All Time', 'Monthly', 'Yearly'
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  final List<String> _months = const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  List<int> get _years {
    final currentYear = DateTime.now().year;
    return List.generate(10, (index) => currentYear - index);
  }

  @override
  Widget build(BuildContext context) {
    final treatmentsState = ref.watch(allTreatmentsStreamProvider);
    final patientsState = ref.watch(patientsStreamProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: Text(widget.dentist.name),
      ),
      body: treatmentsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading treatments: $err')),
        data: (allTreatments) {
          return patientsState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading patients: $err')),
            data: (patients) {
              // 1. Filter treatments by dentist name
              final dentistTreatments = allTreatments
                  .where((t) => t.dentistName.trim().toLowerCase() == widget.dentist.name.trim().toLowerCase())
                  .toList();

              // 2. Filter by timeframe
              final filteredTreatments = dentistTreatments.where((t) {
                if (_timeframe == 'All Time') {
                  return true;
                } else if (_timeframe == 'Monthly') {
                  return t.date.year == _selectedYear && t.date.month == _selectedMonth;
                } else if (_timeframe == 'Yearly') {
                  return t.date.year == _selectedYear;
                }
                return true;
              }).toList();

              // 3. Compute Metrics
              final totalBillings = filteredTreatments.fold<double>(0.0, (sum, t) => sum + t.cost);
              final treatmentCount = filteredTreatments.length;
              final avgCost = treatmentCount > 0 ? totalBillings / treatmentCount : 0.0;

              // 4. Compute Category Breakdown
              final categoryCounts = <String, int>{};
              final categoryBillings = <String, double>{};
              for (var t in filteredTreatments) {
                categoryCounts[t.category] = (categoryCounts[t.category] ?? 0) + 1;
                categoryBillings[t.category] = (categoryBillings[t.category] ?? 0.0) + t.cost;
              }
              final sortedCategories = categoryCounts.keys.toList()
                ..sort((a, b) => categoryCounts[b]!.compareTo(categoryCounts[a]!));

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Header card
                    Container(
                      color: AppTheme.primaryBlue,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                              widget.dentist.name.isNotEmpty
                                  ? widget.dentist.name.split(' ').last.substring(0, 1).toUpperCase()
                                  : 'D',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.dentist.name,
                            style: textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.dentist.isActive
                                  ? AppTheme.successGreen.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: widget.dentist.isActive ? AppTheme.successGreen : Colors.white24,
                              ),
                            ),
                            child: Text(
                              widget.dentist.isActive ? 'Active Doctor' : 'Inactive Roster',
                              style: TextStyle(
                                color: widget.dentist.isActive ? Colors.white : Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Timeframe Selector Row
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment<String>(
                                value: 'All Time',
                                label: Text('All Time'),
                                icon: Icon(Icons.all_inclusive),
                              ),
                              ButtonSegment<String>(
                                value: 'Monthly',
                                label: Text('Monthly'),
                                icon: Icon(Icons.calendar_month),
                              ),
                              ButtonSegment<String>(
                                value: 'Yearly',
                                label: Text('Yearly'),
                                icon: Icon(Icons.calendar_today),
                              ),
                            ],
                            selected: {_timeframe},
                            onSelectionChanged: (newSelection) {
                              setState(() {
                                _timeframe = newSelection.first;
                              });
                            },
                            style: SegmentedButton.styleFrom(
                              selectedBackgroundColor: AppTheme.primaryBlue,
                              selectedForegroundColor: Colors.white,
                              side: const BorderSide(color: AppTheme.primaryBlue),
                            ),
                          ),
                          
                          // Conditional dropdowns based on selected timeframe
                          if (_timeframe == 'Monthly' || _timeframe == 'Yearly') ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_timeframe == 'Monthly') ...[
                                  // Month Selector
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        value: _selectedMonth,
                                        items: List.generate(12, (index) {
                                          return DropdownMenuItem<int>(
                                            value: index + 1,
                                            child: Text(_months[index]),
                                          );
                                        }),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              _selectedMonth = val;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                // Year Selector
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _selectedYear,
                                      items: _years.map((year) {
                                        return DropdownMenuItem<int>(
                                          value: year,
                                          child: Text('$year'),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedYear = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Metrics Cards Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: DentistMetricCard(
                              title: 'Total Billings',
                              value: NumberFormat.currency(symbol: '₱').format(totalBillings),
                              icon: Icons.monetization_on_outlined,
                              color: AppTheme.successGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DentistMetricCard(
                              title: 'Treatments',
                              value: '$treatmentCount',
                              icon: Icons.check_circle_outline,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: DentistMetricCard(
                        title: 'Average Billings per Treatment',
                        value: NumberFormat.currency(symbol: '₱').format(avgCost),
                        icon: Icons.analytics_outlined,
                        color: AppTheme.secondaryGold,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Category Breakdown Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Treatment Type Breakdown',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (treatmentCount == 0)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16.0),
                                    child: Text(
                                      'No categories logged in this timeframe',
                                      style: TextStyle(color: AppTheme.textMuted),
                                    ),
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: sortedCategories.length,
                                  itemBuilder: (context, index) {
                                    final cat = sortedCategories[index];
                                    final count = categoryCounts[cat]!;
                                    final billings = categoryBillings[cat]!;
                                    final pct = count / treatmentCount;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                cat,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                '$count (${(pct * 100).toStringAsFixed(0)}%)',
                                                style: const TextStyle(
                                                  color: AppTheme.textMuted,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(4),
                                                  child: LinearProgressIndicator(
                                                    value: pct,
                                                    minHeight: 8,
                                                    backgroundColor: Colors.grey.shade100,
                                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                                      AppTheme.primaryBlue,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                NumberFormat.compactSimpleCurrency(name: 'PHP').format(billings),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Log of Treatments
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.assignment_outlined, color: AppTheme.primaryBlue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Treatment Log',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (filteredTreatments.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Column(
                            children: [
                              Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                'No treatments recorded in this period',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredTreatments.length,
                        itemBuilder: (context, index) {
                          final Treatment treatment = filteredTreatments[index];
                          // Find patient name
                          final match = patients.where((p) => p.id == treatment.patientId);
                          final patientName = match.isNotEmpty ? match.first.fullName : 'Unknown Patient';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryBlue.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          treatment.category,
                                          style: const TextStyle(
                                            color: AppTheme.primaryBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        NumberFormat.currency(symbol: '₱').format(treatment.cost),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.successGreen,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 14, color: AppTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        patientName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat.yMMMd().format(treatment.date),
                                        style: textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  if (treatment.notes.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      treatment.notes,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
