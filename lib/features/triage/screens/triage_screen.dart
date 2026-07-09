import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/sync_service.dart';
import '../models/triage_record.dart';
import '../providers/triage_provider.dart';
import '../widgets/priority_selector.dart';
import '../widgets/triage_card.dart';

class TriageScreen extends StatefulWidget {
  const TriageScreen({super.key});

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _conditionController = TextEditingController();
  
  int? _selectedPriority;
  TriageStatus _selectedStatus = TriageStatus.pending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final syncService = Provider.of<SyncService>(context, listen: false);
      syncService.onSyncCompleted = (count) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$count records synchronized successfully'),
              backgroundColor: AppTheme.secondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      };
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Provider.of<TriageProvider>(context, listen: false).triggerSync();
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPriority == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a priority level'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final provider = Provider.of<TriageProvider>(context, listen: false);
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);

    final isOnline = await connectivityService.isOnline;

    try {
      final outcome = await provider.submitTriage(
        patientName: _nameController.text,
        conditionDescription: _conditionController.text,
        priority: _selectedPriority!,
        status: _selectedStatus,
      );

      if (mounted) {
        if (outcome == SubmissionOutcome.uploadedOnline) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Record submitted successfully'),
              backgroundColor: Colors.green.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          if (!isOnline) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Saved locally. Will sync automatically.'),
                backgroundColor: AppTheme.tertiary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Record saved locally due to network issue'),
                backgroundColor: AppTheme.tertiary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }

        _nameController.clear();
        _conditionController.clear();
        setState(() {
          _selectedPriority = null;
          _selectedStatus = TriageStatus.pending;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TriageProvider>(context);
    final connectivityService = Provider.of<ConnectivityService>(context);

    return Scaffold(
      backgroundColor: AppTheme.primaryWhite,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await provider.triggerSync();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Premium Overlapping Red Header Container
                Stack(
                  children: [
                    Container(
                      height: 220,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(36),
                          bottomRight: Radius.circular(36),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nova Poshta',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 24,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'Triage Intake Service',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              // Network status Chip in White
                              StreamBuilder<bool>(
                                stream: connectivityService.isOnlineStream,
                                initialData: true,
                                builder: (context, snapshot) {
                                  final online = snapshot.data ?? true;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          online ? Icons.wifi : Icons.wifi_off,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          online ? 'Online' : 'Offline',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Form overlapping card
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 120, 16, 16),
                      child: Card(
                        elevation: 4,
                        shadowColor: AppTheme.secondary.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.assignment_ind,
                                      color: AppTheme.primary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Patient Registration',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Patient Name Input
                                TextFormField(
                                  controller: _nameController,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  decoration: const InputDecoration(
                                    labelText: 'Patient Name',
                                    hintText: 'Enter patient full name',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Patient name is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Condition Description Input
                                TextFormField(
                                  controller: _conditionController,
                                  maxLines: 3,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  decoration: const InputDecoration(
                                    labelText: 'Condition Description',
                                    hintText: 'Describe patient symptoms, injuries...',
                                    prefixIcon: Icon(Icons.note_alt_outlined),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Condition description is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                // Priority Selector
                                PrioritySelector(
                                  selectedPriority: _selectedPriority,
                                  onPrioritySelected: (priority) {
                                    setState(() {
                                      _selectedPriority = priority;
                                    });
                                  },
                                ),
                                const SizedBox(height: 20),
                                // Transport Status Selector
                                const Text(
                                  'Transport Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryWhite.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.secondaryWhite, width: 1.5),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: RadioListTile<TriageStatus>(
                                          title: const Text(
                                            'Pending',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          value: TriageStatus.pending,
                                          groupValue: _selectedStatus,
                                          activeColor: AppTheme.primary,
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => _selectedStatus = val);
                                            }
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: RadioListTile<TriageStatus>(
                                          title: const Text(
                                            'In Transit',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          value: TriageStatus.inTransit,
                                          groupValue: _selectedStatus,
                                          activeColor: AppTheme.primary,
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => _selectedStatus = val);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Submit Button
                                ElevatedButton(
                                  onPressed: provider.isLoading ? null : _submitForm,
                                  child: provider.isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text('SUBMIT TRIAGE RECORD'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Recent Records Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Triage Records',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.secondary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.sync_rounded, color: AppTheme.tertiary),
                            tooltip: 'Sync records',
                            onPressed: provider.isLoading ? null : () => provider.triggerSync(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      provider.records.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 48.0),
                                child: Text(
                                  'No triage records captured yet.',
                                  style: TextStyle(
                                    color: AppTheme.tertiary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: provider.records.length,
                              itemBuilder: (context, index) {
                                final record = provider.records[index];
                                return TriageCard(record: record);
                              },
                            ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
