import 'package:flutter/material.dart';
import '../../../../core/services/translation_service.dart';

class AddItemRow extends StatelessWidget {
  final VoidCallback onTap;

  const AddItemRow({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Placeholder for checkbox area (empty space to align with other items)
              const SizedBox(
                width: 24, // Same width as checkbox
                height: 24,
              ),
              const SizedBox(width: 12),

              // Add item content
              Expanded(
                child: Row(
                  children: [
                    // Add item text
                    Expanded(
                      child: Text(
                        TranslationService.translate('add_item'),
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Add icon
                    Icon(
                      Icons.add_circle_outline,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ],
                ),
              ),

              // Empty space to align with hamburger menu
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}
