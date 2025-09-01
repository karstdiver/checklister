import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();

class ChecklistProgressIndicator extends StatelessWidget {
  final int completedItems;
  final int totalItems;

  const ChecklistProgressIndicator({
    super.key,
    required this.completedItems,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalItems > 0 ? completedItems / totalItems : 0.0;
    
    return Column(
      children: [
        // Progress bar
        Container(
          width: double.infinity,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Progress text
        Text(
          '$completedItems / $totalItems',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
