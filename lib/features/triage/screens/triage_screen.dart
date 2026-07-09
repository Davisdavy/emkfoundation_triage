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

  /// True only when all required fields are non-empty and priority is chosen.
  bool get _isFormReady =>
      _nameController.text.trim().isNotEmpty &&
      _conditionController.text.trim().isNotEmpty &&
      _selectedPriority != null;

  void _onFieldChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Rebuild on every keystroke so the button state is always current.
    _nameController.addListener(_onFieldChanged);
    _conditionController.addListener(_onFieldChanged);

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
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.15),
                                          width: 1.5,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(9),
                                        child: Image.asset(
                                          'assets/logo.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Medic Triage',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 21,
                                              letterSpacing: 0.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Triage Intake Service',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
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
                                    fontSize: 13,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 56,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    children: [
                                      _StatusChip(
                                        label: 'Pending',
                                        icon: Icons.access_time_rounded,
                                        isSelected: _selectedStatus == TriageStatus.pending,
                                        onTap: () => setState(() => _selectedStatus = TriageStatus.pending),
                                      ),
                                      const SizedBox(width: 10),
                                      _StatusChip(
                                        label: 'In Transit',
                                        icon: Icons.local_shipping_outlined,
                                        isSelected: _selectedStatus == TriageStatus.inTransit,
                                        onTap: () => setState(() => _selectedStatus = TriageStatus.inTransit),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Submit Button — disabled until all fields are filled.
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 250),
                                  opacity: _isFormReady && !provider.isLoading ? 1.0 : 0.45,
                                  child: ElevatedButton(
                                    onPressed:
                                        provider.isLoading || !_isFormReady ? null : _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      disabledBackgroundColor: AppTheme.tertiary,
                                      disabledForegroundColor: Colors.white70,
                                    ),
                                    child: provider.isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            _isFormReady
                                                ? 'SUBMIT TRIAGE RECORD'
                                                : 'COMPLETE FORM TO SUBMIT',
                                          ),
                                  ),
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

/// Compact horizontal-scroll toggle chip for Transport Status.
class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondary : AppTheme.secondaryWhite.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.secondary : AppTheme.secondaryWhite,
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.secondary.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.tertiary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppTheme.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
