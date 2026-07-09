import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../models/triage_record.dart';

class TriageCard extends StatelessWidget {
  final TriageRecord record;

  const TriageCard({
    super.key,
    required this.record,
  });

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return const Color(0xFF8B0000); // Dark Red
      case 2:
        return Colors.orange.shade800; // Orange
      case 3:
        return Colors.amber.shade700; // Yellow/Amber
      case 4:
        return Colors.blue.shade700; // Blue
      case 5:
        return Colors.green.shade700; // Green
      default:
        return Colors.grey;
    }
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 1:
        return 'Critical';
      case 2:
        return 'High Risk';
      case 3:
        return 'Moderate';
      case 4:
        return 'Stable';
      case 5:
        return 'Low Risk';
      default:
        return '';
    }
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(record.priority);
    final priorityLabel = _getPriorityLabel(record.priority);
    final isProminent = record.priority == 1 || record.priority == 2;

    // Use customized color tokens
    final cardBgColor = isProminent
        ? AppTheme.primary.withOpacity(0.04)
        : Colors.white;

    return Card(
      elevation: isProminent ? 2.5 : 1,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isProminent ? AppTheme.primary.withOpacity(0.4) : AppTheme.secondaryWhite,
          width: isProminent ? 1.5 : 1.0,
        ),
      ),
      color: cardBgColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section with Priority Badge and Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular Avatar indicating Priority Level
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: priorityColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${record.priority}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.patientName,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppTheme.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              priorityLabel.toUpperCase(),
                              style: TextStyle(
                                color: priorityColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isProminent)
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_rounded,
                                  color: AppTheme.primary,
                                  size: 14,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'URGENT',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Sync status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: record.isSynced
                        ? Colors.green.shade50
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: record.isSynced
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: record.isSynced ? Colors.green.shade600 : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        record.isSynced ? 'Synced' : 'Pending',
                        style: TextStyle(
                          color: record.isSynced ? Colors.green.shade800 : Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Condition Description text
            Text(
              record.conditionDescription,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.tertiary,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            const Divider(color: AppTheme.secondaryWhite, height: 1),
            const SizedBox(height: 10),
            // Bottom Info: transport status & timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      record.status == TriageStatus.inTransit
                          ? Icons.local_shipping_outlined
                          : Icons.access_time_rounded,
                      size: 16,
                      color: AppTheme.tertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      record.status == TriageStatus.inTransit
                          ? 'In Transit'
                          : 'Pending Transport',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.tertiary,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatDateTime(record.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
