import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/domain/user_tier.dart';
import '../../../core/providers/privilege_provider.dart';
import '../../../core/services/limit_management_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../shared/widgets/app_card.dart';

class LimitManagementScreen extends ConsumerStatefulWidget {
  const LimitManagementScreen({super.key});

  @override
  ConsumerState<LimitManagementScreen> createState() =>
      _LimitManagementScreenState();
}

class _LimitManagementScreenState extends ConsumerState<LimitManagementScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _systemLimits;
  Map<String, dynamic>? _userOverrides;

  @override
  void initState() {
    super.initState();
    _loadSystemLimits();
  }

  Future<void> _loadSystemLimits() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load system limits
      final limits = await LimitManagementService.getTierLimits(UserTier.free);
      setState(() {
        _systemLimits = limits;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading system limits: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final privileges = ref.watch(privilegeProvider);

    // Check if user has admin privileges
    if (privileges == null || !privileges.canManageSystem) {
      return Scaffold(
        appBar: AppBar(
          title: Text(TranslationService.translate('limit_management')),
          backgroundColor: theme.colorScheme.surface,
        ),
        body: Center(
          child: Text(
            TranslationService.translate('access_denied'),
            style: theme.textTheme.titleLarge,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.translate('limit_management')),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTierLimits(theme),
                  const SizedBox(height: 24),
                  _buildUserOverrides(theme),
                  const SizedBox(height: 24),
                  _buildGlobalSettings(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildTierLimits(ThemeData theme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationService.translate('tier_limits'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Configure default limits for each user tier',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          ...UserTier.values.map((tier) {
            return ListTile(
              title: Text('${tier.name.toUpperCase()} Tier'),
              subtitle: Text('Configure limits for ${tier.name} users'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editTierLimits(tier),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildUserOverrides(ThemeData theme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationService.translate('user_overrides'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Manage individual user limit overrides',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addUserOverride,
            icon: const Icon(Icons.person_add),
            label: Text('Add User Override'),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalSettings(ThemeData theme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Global Settings',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Reset All Limits'),
            subtitle: const Text('Reset all limits to default values'),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetAllLimits,
            ),
          ),
          ListTile(
            title: const Text('Clear Cache'),
            subtitle: const Text('Clear cached limit data'),
            trailing: IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearCache,
            ),
          ),
        ],
      ),
    );
  }

  void _editTierLimits(UserTier tier) {
    showDialog(
      context: context,
      builder: (context) => _TierLimitsDialog(tier: tier),
    );
  }

  void _addUserOverride() {
    showDialog(
      context: context,
      builder: (context) => const _UserOverrideDialog(),
    );
  }

  void _resetAllLimits() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Limits'),
        content: const Text(
          'Are you sure you want to reset all limits to default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performResetAllLimits();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _performResetAllLimits() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Reset to default limits
      final defaultLimits = {
        'tier_limits': {
          'anonymous': {'maxChecklists': 1, 'maxItemsPerChecklist': 3},
          'free': {'maxChecklists': 5, 'maxItemsPerChecklist': 15},
          'premium': {'maxChecklists': 50, 'maxItemsPerChecklist': 100},
          'pro': {'maxChecklists': -1, 'maxItemsPerChecklist': -1},
        },
        'admin_overrides': {},
      };

      await LimitManagementService.updateSystemLimits(defaultLimits);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All limits reset successfully')),
        );
        _loadSystemLimits();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting limits: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearCache() {
    LimitManagementService.clearCache();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cache cleared successfully')));
  }
}

class _TierLimitsDialog extends StatefulWidget {
  final UserTier tier;

  const _TierLimitsDialog({required this.tier});

  @override
  State<_TierLimitsDialog> createState() => _TierLimitsDialogState();
}

class _TierLimitsDialogState extends State<_TierLimitsDialog> {
  final _checklistController = TextEditingController();
  final _itemController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLimits();
  }

  Future<void> _loadCurrentLimits() async {
    try {
      final limits = await LimitManagementService.getTierLimits(widget.tier);
      _checklistController.text = limits['maxChecklists'].toString();
      _itemController.text = limits['maxItemsPerChecklist'].toString();
    } catch (e) {
      print('Error loading current limits: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.tier.name.toUpperCase()} Tier Limits'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _checklistController,
            decoration: const InputDecoration(
              labelText: 'Max Checklists',
              hintText: 'Enter limit (-1 for unlimited)',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _itemController,
            decoration: const InputDecoration(
              labelText: 'Max Items per Checklist',
              hintText: 'Enter limit (-1 for unlimited)',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(TranslationService.translate('cancel')),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveLimits,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveLimits() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final checklistLimit = int.tryParse(_checklistController.text) ?? 5;
      final itemLimit = int.tryParse(_itemController.text) ?? 15;

      // Update the specific tier limits
      final newLimits = {
        'tier_limits': {
          widget.tier.name: {
            'maxChecklists': checklistLimit,
            'maxItemsPerChecklist': itemLimit,
          },
        },
      };

      await LimitManagementService.updateSystemLimits(newLimits);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Limits updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating limits: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _checklistController.dispose();
    _itemController.dispose();
    super.dispose();
  }
}

class _UserOverrideDialog extends StatefulWidget {
  const _UserOverrideDialog();

  @override
  State<_UserOverrideDialog> createState() => _UserOverrideDialogState();
}

class _UserOverrideDialogState extends State<_UserOverrideDialog> {
  final _userIdController = TextEditingController();
  final _checklistController = TextEditingController();
  final _itemController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add User Override'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _userIdController,
            decoration: const InputDecoration(
              labelText: 'User ID',
              hintText: 'Enter user ID',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _checklistController,
            decoration: const InputDecoration(
              labelText: 'Max Checklists (optional)',
              hintText: 'Enter limit (-1 for unlimited)',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _itemController,
            decoration: const InputDecoration(
              labelText: 'Max Items per Checklist (optional)',
              hintText: 'Enter limit (-1 for unlimited)',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Why is this override needed?',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(TranslationService.translate('cancel')),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addOverride,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _addOverride() async {
    if (_userIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _userIdController.text.trim();
      final overrides = <String, int>{};

      if (_checklistController.text.isNotEmpty) {
        overrides['maxChecklists'] =
            int.tryParse(_checklistController.text) ?? 5;
      }

      if (_itemController.text.isNotEmpty) {
        overrides['maxItemsPerChecklist'] =
            int.tryParse(_itemController.text) ?? 15;
      }

      final reason = _reasonController.text.trim().isNotEmpty
          ? _reasonController.text.trim()
          : 'Admin override';

      await LimitManagementService.addUserOverride(userId, overrides, reason);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User override added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding override: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _checklistController.dispose();
    _itemController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}
