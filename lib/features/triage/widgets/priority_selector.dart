import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';

class PrioritySelector extends StatelessWidget {
  final int? selectedPriority;
  final ValueChanged<int> onPrioritySelected;

  const PrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.onPrioritySelected,
  });

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return const Color(0xFF9E0B0B); // Deep hazard Red
      case 2:
        return const Color(0xFFFF6D00); // Hazard Orange
      case 3:
        return Colors.amber.shade700;   // Yellow
      case 4:
        return Colors.blue.shade700;    // Blue
      case 5:
        return Colors.green.shade700;   // Green
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

  String _getPriorityDescription(int priority) {
    switch (priority) {
      case 1:
        return 'Immediate life-threatening condition';
      case 2:
        return 'Urgent, high potential for deterioration';
      case 3:
        return 'Semi-urgent, stable condition';
      case 4:
        return 'Non-urgent, stable signs';
      case 5:
        return 'Minor injuries or illness';
      default:
        return '';
    }
  }

  Widget _buildPriorityButton({
    required int priority,
    required bool isSelected,
    required Color color,
    bool fullWidth = false,
  }) {
    final label = _getPriorityLabel(priority);
    final desc = _getPriorityDescription(priority);
    final isCritical = priority == 1 || priority == 2;

    return InkWell(
      onTap: () => onPrioritySelected(priority),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: isCritical ? 14 : 12,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.4),
            width: isSelected ? 2.5 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: isCritical ? 34 : 26,
              height: isCritical ? 34 : 26,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$priority',
                  style: TextStyle(
                    color: isSelected ? color : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: isCritical ? 16 : 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: isCritical ? 14 : 12,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                      if (isCritical && !isSelected) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.warning_amber_rounded,
                          color: color,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                  if (fullWidth && desc.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white.withOpacity(0.85) : AppTheme.tertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Triage Priority Level *',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppTheme.secondary,
          ),
        ),
        const SizedBox(height: 12),
        // Priority 1 & 2 styled full-width for visual priority and space
        _buildPriorityButton(
          priority: 1,
          isSelected: selectedPriority == 1,
          color: _getPriorityColor(1),
          fullWidth: true,
        ),
        const SizedBox(height: 8),
        _buildPriorityButton(
          priority: 2,
          isSelected: selectedPriority == 2,
          color: _getPriorityColor(2),
          fullWidth: true,
        ),
        const SizedBox(height: 10),
        // Priorities 3-5: horizontal scrollable row so nothing is clipped
        SizedBox(
          height: 66,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final priority = index + 3; // 3, 4, 5
              final isSelected = selectedPriority == priority;
              final color = _getPriorityColor(priority);
              final label = _getPriorityLabel(priority);

              return InkWell(
                onTap: () => onPrioritySelected(priority),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 130,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? color : color.withOpacity(0.4),
                      width: isSelected ? 2.5 : 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : color,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$priority',
                            style: TextStyle(
                              color: isSelected ? color : Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.white : color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
