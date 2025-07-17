import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/privilege_provider.dart';
import '../domain/user_tier.dart';
import '../services/translation_service.dart';

class SignupEncouragement extends ConsumerWidget {
  final String title;
  final String message;
  final String? featureName;
  final VoidCallback? onSignupPressed;
  final VoidCallback? onDismiss;

  const SignupEncouragement({
    super.key,
    required this.title,
    required this.message,
    this.featureName,
    this.onSignupPressed,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privileges = ref.watch(privilegeProvider);
    final isAnonymous = privileges?.isAnonymous ?? true;

    if (!isAnonymous) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.purple[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.orange[600], size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
          ),
          if (featureName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '✨ $featureName',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      onSignupPressed ?? () => _showSignupDialog(context),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Sign Up Free'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: onDismiss,
                child: Text(
                  'Maybe Later',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSignupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Your Free Account'),
        content: const Text(
          'Sign up to unlock:\n'
          '• Save and edit your checklists\n'
          '• Session history and progress tracking\n'
          '• Checklist templates\n'
          '• Data backup and sync\n'
          '• Create up to 5 checklists with 15 items each',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }
}

class ProfilePictureEncouragement extends ConsumerWidget {
  final VoidCallback? onSignUp;
  final VoidCallback? onUpgrade;
  final VoidCallback? onDetails;

  const ProfilePictureEncouragement({
    super.key,
    this.onSignUp,
    this.onUpgrade,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privileges = ref.watch(privilegeProvider);
    final currentTier = privileges?.tier ?? UserTier.anonymous;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.camera_alt,
              size: 32,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            _getTitle(currentTier),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            _getDescription(currentTier),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: currentTier == UserTier.anonymous
                  ? onSignUp
                  : onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                currentTier == UserTier.anonymous
                    ? TranslationService.translate('signup')
                    : TranslationService.translate('upgrade'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // Details Button
          if (onDetails != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onDetails,
              child: Text(
                TranslationService.translate('details'),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getTitle(UserTier tier) {
    switch (tier) {
      case UserTier.anonymous:
        return 'Personalize Your Profile';
      case UserTier.free:
        return 'Unlock Profile Pictures';
      case UserTier.premium:
      case UserTier.pro:
        return 'Profile Pictures Available';
    }
  }

  String _getDescription(UserTier tier) {
    switch (tier) {
      case UserTier.anonymous:
        return 'Sign up to add a profile picture and personalize your experience.';
      case UserTier.free:
        return 'Upgrade to Premium to add profile pictures and unlock more personalization features.';
      case UserTier.premium:
      case UserTier.pro:
        return 'You have access to profile pictures and all personalization features.';
    }
  }
}

class ProfilePictureDetailsDialog extends ConsumerWidget {
  final UserTier userTier;

  const ProfilePictureDetailsDialog({super.key, required this.userTier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text(_getDialogTitle()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getDialogContent()),
          const SizedBox(height: 16),
          _buildFeatureList(context),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(TranslationService.translate('close')),
        ),
        if (userTier == UserTier.anonymous || userTier == UserTier.free)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to signup/upgrade flow
            },
            child: Text(
              userTier == UserTier.anonymous
                  ? TranslationService.translate('signup')
                  : TranslationService.translate('upgrade'),
            ),
          ),
      ],
    );
  }

  String _getDialogTitle() {
    switch (userTier) {
      case UserTier.anonymous:
        return 'Why Sign Up?';
      case UserTier.free:
        return 'Premium Features';
      case UserTier.premium:
      case UserTier.pro:
        return 'Your Premium Benefits';
    }
  }

  String _getDialogContent() {
    switch (userTier) {
      case UserTier.anonymous:
        return 'Sign up to unlock these amazing features:';
      case UserTier.free:
        return 'Upgrade to Premium to get access to:';
      case UserTier.premium:
      case UserTier.pro:
        return 'You currently have access to:';
    }
  }

  Widget _buildFeatureList(BuildContext context) {
    final features = _getFeatures();

    return Column(
      children: features
          .map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  List<String> _getFeatures() {
    switch (userTier) {
      case UserTier.anonymous:
        return [
          'Profile pictures and customization',
          'Unlimited checklists',
          'Session persistence',
          'Advanced features',
          'Data backup and sync',
        ];
      case UserTier.free:
        return [
          'Profile pictures',
          'Advanced personalization',
          'Priority support',
          'Custom themes',
          'Export capabilities',
        ];
      case UserTier.premium:
      case UserTier.pro:
        return [
          'Profile pictures ✓',
          'Advanced personalization ✓',
          'Priority support ✓',
          'Custom themes ✓',
          'Export capabilities ✓',
        ];
    }
  }
}
