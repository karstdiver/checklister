import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_tier.dart';
import '../services/translation_service.dart';
import '../providers/privilege_provider.dart';
import '../../features/settings/presentation/upgrade_screen.dart';
import '../../features/auth/presentation/login_screen.dart';

class TierIndicator extends ConsumerWidget {
  final UserTier tier;
  final double fontSize;
  final double iconSize;
  final EdgeInsetsGeometry? padding;

  const TierIndicator({
    super.key,
    required this.tier,
    this.fontSize = 12,
    this.iconSize = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _handleTierTap(context, ref),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getTierColor(tier),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getTierIcon(tier), color: Colors.white, size: iconSize),
            const SizedBox(width: 6),
            Text(
              getTierDisplayName(tier),
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTierTap(BuildContext context, WidgetRef ref) {
    final privileges = ref.read(privilegeProvider);
    final isAnonymous = privileges?.isAnonymous ?? true;
    final isMaxTier = tier == UserTier.pro;

    // Don't navigate if user is already at max tier
    if (isMaxTier) {
      return;
    }

    // Navigate based on user tier
    if (isAnonymous) {
      // Anonymous users go to signup
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(initialSignUpMode: true),
        ),
      );
    } else {
      // Authenticated users go to upgrade screen
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const UpgradeScreen()));
    }
  }

  static Color _getTierColor(UserTier tier) {
    switch (tier) {
      case UserTier.anonymous:
        return Colors.grey;
      case UserTier.free:
        return Colors.blue;
      case UserTier.premium:
        return Colors.purple;
      case UserTier.pro:
        return Colors.orange;
    }
  }

  static IconData _getTierIcon(UserTier tier) {
    switch (tier) {
      case UserTier.anonymous:
        return Icons.person_outline;
      case UserTier.free:
        return Icons.star_outline;
      case UserTier.premium:
        return Icons.star;
      case UserTier.pro:
        return Icons.star_rounded;
    }
  }

  static String getTierDisplayName(UserTier tier) {
    switch (tier) {
      case UserTier.anonymous:
        return TranslationService.translate('anonymous');
      case UserTier.free:
        return TranslationService.translate('free');
      case UserTier.premium:
        return TranslationService.translate('premium');
      case UserTier.pro:
        return TranslationService.translate('pro');
    }
  }
}
