import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/services/acceptance_service.dart';
import '../../../core/domain/user_tier.dart';
import '../../../core/domain/pricing_tiers_config.dart';
import '../../../core/services/pricing_tiers_management_service.dart';
import '../../../core/providers/privilege_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpgradeScreen extends ConsumerStatefulWidget {
  final String? sourceFeature;
  final UserTier? targetTier;

  const UpgradeScreen({super.key, this.sourceFeature, this.targetTier});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  PricingTiersConfig? _pricingConfig;
  bool _isLoading = true;
  String? _errorMessage;
  UserTier? _selectedTier;

  @override
  void initState() {
    super.initState();
    _loadPricingConfig();
  }

  Future<void> _loadPricingConfig() async {
    try {
      final config = await PricingTiersManagementService.getPricingTiers();
      setState(() {
        _pricingConfig = config;
        _isLoading = false;
        // Set default selected tier based on target or current tier
        _selectedTier = widget.targetTier ?? _getNextTier();
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  UserTier _getNextTier() {
    final privileges = ref.read(privilegeProvider);
    final currentTier = privileges?.tier ?? UserTier.anonymous;

    switch (currentTier) {
      case UserTier.anonymous:
        return UserTier.free;
      case UserTier.free:
        return UserTier.premium;
      case UserTier.premium:
        return UserTier.pro;
      case UserTier.pro:
        return UserTier.pro; // Already at max tier
    }
  }

  @override
  Widget build(BuildContext context) {
    // Log screen view for analytics
    AnalyticsService().logScreenView(screenName: 'UpgradeScreen');

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(TranslationService.translate('upgrade')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(TranslationService.translate('upgrade')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                TranslationService.translate('error_loading_pricing'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPricingConfig,
                child: Text(TranslationService.translate('retry')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.translate('upgrade')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroSection(),
            const SizedBox(height: 32),
            _buildTierComparison(),
            const SizedBox(height: 32),
            _buildPricingSection(),
            const SizedBox(height: 32),
            _buildUpgradeButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    final privileges = ref.watch(privilegeProvider);
    final currentTier = privileges?.tier ?? UserTier.anonymous;

    return Column(
      children: [
        Icon(Icons.workspace_premium, size: 80, color: Colors.amber),
        const SizedBox(height: 24),
        Text(
          _getHeroTitle(currentTier),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _getHeroDescription(currentTier),
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        if (widget.sourceFeature != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              '✨ ${widget.sourceFeature}',
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTierComparison() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TranslationService.translate('feature_comparison'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFeatureTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTable() {
    final features = [
      {'name': 'checklists', 'free': '5', 'premium': '50', 'pro': '∞'},
      {
        'name': 'sessions',
        'free': 'basic',
        'premium': 'advanced',
        'pro': 'team',
      },
      {'name': 'ai_features', 'free': '❌', 'premium': '✅', 'pro': '✅'},
      {'name': 'export', 'free': '❌', 'premium': '✅', 'pro': '✅'},
      {'name': 'analytics', 'free': '❌', 'premium': '✅', 'pro': '✅'},
      {'name': 'priority_support', 'free': '❌', 'premium': '✅', 'pro': '✅'},
    ];

    return Table(
      border: TableBorder.all(color: Colors.grey[300]!),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[100]),
          children: [
            _buildTableHeader('Feature'),
            _buildTableHeader('Free'),
            _buildTableHeader('Premium'),
            _buildTableHeader('Pro'),
          ],
        ),
        ...features.map(
          (feature) => TableRow(
            children: [
              _buildTableCell(feature['name']!),
              _buildTableCell(feature['free']!),
              _buildTableCell(feature['premium']!),
              _buildTableCell(feature['pro']!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        TranslationService.translate(text),
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text, textAlign: TextAlign.center),
    );
  }

  Widget _buildPricingSection() {
    if (_pricingConfig == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TranslationService.translate('pricing_plans'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._pricingConfig!.tiers.entries.map((entry) {
              final tier = entry.value;
              final isSelected = _isTierSelected(tier.name);

              return _buildPricingCard(tier, isSelected);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard(TierConfig tier, bool isSelected) {
    return Card(
      color: isSelected ? Colors.blue[50] : null,
      child: InkWell(
        onTap: () => _selectTier(tier.name),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Radio<UserTier>(
                value: _getTierFromName(tier.name),
                groupValue: _selectedTier,
                onChanged: (value) => _selectTier(tier.name),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tier.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${tier.price}/${tier.billingCycle}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    if (tier.popular)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          TranslationService.translate('popular'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeButton() {
    return ElevatedButton(
      onPressed: _selectedTier != null ? _handleUpgrade : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        _getUpgradeButtonText(),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getHeroTitle(UserTier currentTier) {
    switch (currentTier) {
      case UserTier.anonymous:
        return TranslationService.translate('signup_for_free_account');
      case UserTier.free:
        return TranslationService.translate('upgrade_to_premium');
      case UserTier.premium:
        return TranslationService.translate('upgrade_to_pro');
      case UserTier.pro:
        return TranslationService.translate('you_have_max_tier');
    }
  }

  String _getHeroDescription(UserTier currentTier) {
    switch (currentTier) {
      case UserTier.anonymous:
        return TranslationService.translate('signup_description');
      case UserTier.free:
        return TranslationService.translate('upgrade_premium_description');
      case UserTier.premium:
        return TranslationService.translate('upgrade_pro_description');
      case UserTier.pro:
        return TranslationService.translate('max_tier_description');
    }
  }

  String _getUpgradeButtonText() {
    final privileges = ref.read(privilegeProvider);
    final currentTier = privileges?.tier ?? UserTier.anonymous;

    switch (currentTier) {
      case UserTier.anonymous:
        return TranslationService.translate('signup_free');
      case UserTier.free:
        return TranslationService.translate('upgrade_now');
      case UserTier.premium:
        return TranslationService.translate('upgrade_to_pro');
      case UserTier.pro:
        return TranslationService.translate('already_max_tier');
    }
  }

  bool _isTierSelected(String tierName) {
    if (_selectedTier == null) return false;
    return _getTierFromName(tierName) == _selectedTier;
  }

  UserTier _getTierFromName(String tierName) {
    switch (tierName.toLowerCase()) {
      case 'free':
        return UserTier.free;
      case 'premium':
        return UserTier.premium;
      case 'pro':
        return UserTier.pro;
      default:
        return UserTier.free;
    }
  }

  void _selectTier(String tierName) {
    setState(() {
      _selectedTier = _getTierFromName(tierName);
    });
  }

  void _handleUpgrade() {
    AnalyticsService().logCustomEvent(name: 'upgrade_button_tap');

    // TODO: Implement actual upgrade flow
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(TranslationService.translate('upgrade_coming_soon')),
      ),
    );
  }
}

class _AcceptanceStatusSwitch extends StatefulWidget {
  @override
  State<_AcceptanceStatusSwitch> createState() =>
      _AcceptanceStatusSwitchState();
}

class _AcceptanceStatusSwitchState extends State<_AcceptanceStatusSwitch> {
  bool _accepted = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await AcceptanceService.loadAcceptance();
    setState(() {
      _accepted =
          status.privacyAccepted &&
          status.tosAccepted &&
          status.acceptedVersion >= AcceptanceService.currentPolicyVersion;
      _loading = false;
    });
  }

  Future<void> _setAcceptance(bool value) async {
    setState(() => _loading = true);
    if (value) {
      await AcceptanceService.saveAcceptance(
        privacyAccepted: true,
        tosAccepted: true,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('privacyAccepted');
      await prefs.remove('tosAccepted');
      await prefs.remove('acceptedVersion');
      await prefs.remove('acceptedAt');
    }
    await _loadStatus();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Acceptance set (DEV ONLY)'
                : 'Acceptance cleared (DEV ONLY)',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Row(
      children: [
        Switch(value: _accepted, onChanged: (v) => _setAcceptance(v)),
        const SizedBox(width: 12),
        Text(
          _accepted ? 'Acceptance: ON' : 'Acceptance: OFF',
          style: TextStyle(
            color: _accepted ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
