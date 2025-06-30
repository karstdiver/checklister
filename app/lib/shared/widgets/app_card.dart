import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.cardColor,
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: elevation == 0 ? null : AppTheme.shadowMedium,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              borderRadius ?? BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppTheme.spacing20),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AppCardHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;

  const AppCardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: AppTheme.spacing12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
