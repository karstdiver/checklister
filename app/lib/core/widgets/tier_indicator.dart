import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_tier.dart';
import '../services/translation_service.dart';

class TierIndicator extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
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
    );
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
