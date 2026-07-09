import 'package:flutter/material.dart';
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
    final second = dt.second.toString().padLeft(2, '0');
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(record.priority);
    final priorityLabel = _getPriorityLabel(record.priority);
    final isProminent = record.priority == 1 || record.priority == 2;

    // Subtle background tint for Critical (P1) and High Risk (P2)
    final cardBgColor = isProminent
        ? priorityColor.withOpacity(0.06)
        : Theme.of(context).cardColor;

    return Card(
      elevation: isProminent ? 3 : 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isProminent ? priorityColor.withOpacity(0.5) : Colors.grey.shade300,
          width: isProminent ? 1.5 : 0.8,
        ),
      ),
      color: cardBgColor,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored vertical status bar indicator
              Container(
                width: 8,
                color: priorityColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (isProminent) ...[
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: priorityColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Expanded(
                                  child: Text(
                                    record.patientName,
                                    style: TextStyle(
                                      fontWeight: isProminent ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 16,
                                      color: isProminent ? priorityColor : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Priority Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: priorityColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'P${record.priority} - $priorityLabel',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        record.conditionDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Row(
                            children: [
                              Icon(
                                record.status == TriageStatus.inTransit
                                    ? Icons.local_shipping
                                    : Icons.access_time,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                record.status == TriageStatus.inTransit
                                    ? 'In Transit'
                                    : 'Pending',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _formatDateTime(record.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                record.isSynced ? '🟢 ' : '🔴 ',
                                style: const TextStyle(fontSize: 10),
                              ),
                              Text(
                                record.isSynced ? 'Synced' : 'Pending Sync',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: record.isSynced
                                      ? Colors.green.shade700
                                      : const Color(0xFFD32F2F),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
