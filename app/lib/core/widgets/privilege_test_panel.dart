import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/privilege_provider.dart';
import '../domain/user_tier.dart';
import '../services/translation_service.dart';

class PrivilegeTestPanel extends ConsumerWidget {
  const PrivilegeTestPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privileges = ref.watch(privilegeProvider);
    final currentTier = privileges?.tier ?? UserTier.anonymous;

    return ExpansionTile(
      title: Row(
        children: [
          Icon(Icons.science, color: Colors.orange),
          const SizedBox(width: 8),
          Text('🧪 Test Privileges (DEV ONLY)'),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Tier: ${_getTierName(currentTier)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Switch to test different privilege levels:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: UserTier.values.map((tier) {
                  final isSelected = currentTier == tier;
                  return FilterChip(
                    label: Text(_getTierName(tier)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _switchToTier(context, ref, tier);
                      }
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.blue[100],
                    checkmarkColor: Colors.blue,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Current Privileges:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildPrivilegeList(privileges),
            ],
          ),
        ),
      ],
    );
  }

  String _getTierName(UserTier tier) {
    switch (tier) {
      case UserTier.anonymous:
        return 'Anonymous';
      case UserTier.free:
        return 'Free';
      case UserTier.premium:
        return 'Premium';
      case UserTier.pro:
        return 'Pro';
    }
  }

  Widget _buildPrivilegeList(UserPrivileges? privileges) {
    if (privileges == null) return const Text('No privileges loaded');

    final features = privileges.features;
    final enabledFeatures = features.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...enabledFeatures.map(
          (feature) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(feature)),
              ],
            ),
          ),
        ),
        if (enabledFeatures.isEmpty)
          Text(
            'No features enabled',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  void _switchToTier(BuildContext context, WidgetRef ref, UserTier tier) {
    final privilegeNotifier = ref.read(privilegeProvider.notifier);

    // For testing, we'll directly update the privilege state
    // In production, this would call the actual upgrade method
    privilegeNotifier.testSwitchTier(tier);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${_getTierName(tier)} tier'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
