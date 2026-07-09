import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    // Bind sync completed callback to display a SnackBar in the UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final syncService = Provider.of<SyncService>(context, listen: false);
      syncService.onSyncCompleted = (count) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$count records synchronized successfully'),
              backgroundColor: Colors.green.shade800,
              behavior: SnackBarBehavior.floating,
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
      // Trigger auto sync of pending records when app returns to foreground
      Provider.of<TriageProvider>(context, listen: false).triggerSync();
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPriority == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a priority level'),
          backgroundColor: Colors.redAccent,
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
            const SnackBar(
              content: Text('Record submitted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // If offline or if upload failed but saved locally
          if (!isOnline) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Saved locally. Will sync automatically.'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Record saved locally due to network issue'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }

        // Reset form
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
            backgroundColor: Colors.red,
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
      appBar: AppBar(
        title: const Text(
          'Paramedic Triage Intake',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Connectivity Status Indicator in the app bar
          StreamBuilder<bool>(
            stream: connectivityService.isOnlineStream,
            initialData: true,
            builder: (context, snapshot) {
              final online = snapshot.data ?? true;
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: Chip(
                  avatar: Icon(
                    online ? Icons.wifi : Icons.wifi_off,
                    size: 16,
                    color: online ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                  label: Text(
                    online ? 'Online' : 'Offline Mode',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: online ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                  backgroundColor: online ? Colors.green.shade50 : Colors.red.shade50,
                  side: BorderSide(
                    color: online ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await provider.triggerSync();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Intake Form Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Patient Intake Form',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Patient Name Input
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Patient Name *',
                              hintText: 'Enter patient full name',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                            decoration: InputDecoration(
                              labelText: 'Condition Description *',
                              hintText: 'Describe patient signs, symptoms, injuries...',
                              prefixIcon: const Icon(Icons.description),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Condition description is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Priority Selector
                          PrioritySelector(
                            selectedPriority: _selectedPriority,
                            onPrioritySelected: (priority) {
                              setState(() {
                                _selectedPriority = priority;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          // Transit Status Selector
                          const Text(
                            'Transport Status *',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<TriageStatus>(
                                  title: const Text('Pending'),
                                  value: TriageStatus.pending,
                                  groupValue: _selectedStatus,
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedStatus = val);
                                    }
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<TriageStatus>(
                                  title: const Text('In Transit'),
                                  value: TriageStatus.inTransit,
                                  groupValue: _selectedStatus,
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedStatus = val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Submit Button
                          ElevatedButton(
                            onPressed: provider.isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: provider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text(
                                    'SUBMIT TRIAGE RECORD',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Recent Records Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Triage Records',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sync),
                      tooltip: 'Trigger sync queue manually',
                      onPressed: provider.isLoading ? null : () => provider.triggerSync(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Recent Records List
                provider.records.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: Text(
                            'No triage records captured yet.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
