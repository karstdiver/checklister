import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/domain/pricing_tiers_config.dart';
import '../../../core/services/pricing_tiers_management_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/services/validation_service.dart';

class PricingManagementScreen extends ConsumerStatefulWidget {
  const PricingManagementScreen({super.key});

  @override
  ConsumerState<PricingManagementScreen> createState() =>
      _PricingManagementScreenState();
}

class _PricingManagementScreenState
    extends ConsumerState<PricingManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  PricingTiersConfig? _currentConfig;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPricingConfig();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPricingConfig() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final config = await PricingTiersManagementService.getPricingTiers();
      setState(() {
        _currentConfig = config;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.translate('pricing_management')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: TranslationService.translate('tiers')),
            Tab(text: TranslationService.translate('promotions')),
            Tab(text: TranslationService.translate('regional_pricing')),
            Tab(text: TranslationService.translate('settings')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPricingConfig,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorWidget()
          : _currentConfig == null
          ? _buildNoConfigWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTiersTab(),
                _buildPromotionsTab(),
                _buildRegionalPricingTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
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
          Text(_errorMessage!, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPricingConfig,
            child: Text(TranslationService.translate('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildNoConfigWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.attach_money, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            TranslationService.translate('no_pricing_config'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            TranslationService.translate('create_default_config'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _createDefaultConfig,
            child: Text(TranslationService.translate('create_default')),
          ),
        ],
      ),
    );
  }

  Widget _buildTiersTab() {
    if (_currentConfig == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            TranslationService.translate('pricing_tiers'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _currentConfig!.tiers.length,
              itemBuilder: (context, index) {
                final tierId = _currentConfig!.tiers.keys.elementAt(index);
                final tier = _currentConfig!.tiers[tierId]!;
                return _buildTierCard(tierId, tier);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(String tierId, TierConfig tier) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(tier.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            if (tier.popular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  TranslationService.translate('popular'),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            if (tier.recommended)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  TranslationService.translate('recommended'),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
        subtitle: Text('${tier.price} ${tier.currency}/${tier.billingCycle}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editTier(tierId, tier),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteTier(tierId),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  TranslationService.translate('features'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...tier.features.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('${entry.key}: ${entry.value}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  TranslationService.translate('limits'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...tier.limits.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.block, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text('${entry.key}: ${entry.value}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionsTab() {
    if (_currentConfig == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                TranslationService.translate('promotions'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              ElevatedButton.icon(
                onPressed: _addNewPromotion,
                icon: const Icon(Icons.add),
                label: Text(TranslationService.translate('add_promotion')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationService.translate('global_promotions'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _currentConfig!
                              .promotions
                              .annualDiscount
                              .toString(),
                          decoration: InputDecoration(
                            labelText: TranslationService.translate(
                              'annual_discount_percent',
                            ),
                            suffixText: '%',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => _updateAnnualDiscount(
                            double.tryParse(value) ?? 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: _currentConfig!.promotions.trialDays
                              .toString(),
                          decoration: InputDecoration(
                            labelText: TranslationService.translate(
                              'trial_days',
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) =>
                              _updateTrialDays(int.tryParse(value) ?? 0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            TranslationService.translate('special_offers'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _currentConfig!.promotions.specialOffers.length,
              itemBuilder: (context, index) {
                final offer = _currentConfig!.promotions.specialOffers[index];
                return _buildSpecialOfferCard(offer);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialOfferCard(SpecialOffer offer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(offer.name),
        subtitle: Text('${offer.discount}% off - ${offer.duration} days'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: offer.active,
              onChanged: (value) => _toggleSpecialOffer(offer.id, value),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editSpecialOffer(offer),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteSpecialOffer(offer.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionalPricingTab() {
    if (_currentConfig == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            TranslationService.translate('regional_pricing'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Note: Regional pricing is synchronized with tier pricing. Changes in one will update the other.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildRegionalPricingList()),
        ],
      ),
    );
  }

  Widget _buildRegionalPricingList() {
    // Group tiers by currency
    final tiersByCurrency = <String, List<MapEntry<String, TierConfig>>>{};

    for (final entry in _currentConfig!.tiers.entries) {
      final currency = entry.value.currency;
      if (!tiersByCurrency.containsKey(currency)) {
        tiersByCurrency[currency] = [];
      }
      tiersByCurrency[currency]!.add(entry);
    }

    return ListView.builder(
      itemCount: tiersByCurrency.length,
      itemBuilder: (context, index) {
        final currency = tiersByCurrency.keys.elementAt(index);
        final tiers = tiersByCurrency[currency]!;
        final regionalPrices = _currentConfig!.regionalPricing[currency] ?? {};

        return _buildRegionalPricingCard(currency, regionalPrices, tiers);
      },
    );
  }

  Widget _buildRegionalPricingCard(
    String currency,
    Map<String, double> prices,
    List<MapEntry<String, TierConfig>> tiers,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text('$currency Pricing'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: tiers.map((tierEntry) {
                final tierId = tierEntry.key;
                final tier = tierEntry.value;
                final regionalPrice = prices[tierId] ?? tier.price;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tier.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Tier ID: $tierId',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          initialValue: regionalPrice.toString(),
                          decoration: InputDecoration(
                            labelText: TranslationService.translate('price'),
                            prefixText: currency,
                            helperText: regionalPrice == tier.price
                                ? 'Synced with tier'
                                : 'Different from tier',
                            helperMaxLines: 1,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => _updateRegionalPrice(
                            currency,
                            tierId,
                            double.tryParse(value) ?? 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    if (_currentConfig == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            TranslationService.translate('configuration_settings'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationService.translate('version_info'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Version', _currentConfig!.version),
                  _buildInfoRow(
                    'Last Updated',
                    _currentConfig!.lastUpdated.toString(),
                  ),
                  _buildInfoRow('Updated By', _currentConfig!.updatedBy),
                  _buildInfoRow('Active', _currentConfig!.active.toString()),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveConfiguration,
                          child: Text(
                            TranslationService.translate('save_changes'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _exportConfiguration,
                          child: Text(
                            TranslationService.translate('export_config'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }

  // Action Methods
  Future<void> _createDefaultConfig() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar(
          TranslationService.translate('user_not_authenticated'),
        );
        return;
      }

      final defaultConfig = PricingTiersManagementService.createDefaultConfig(
        currentUser.uid,
      );
      final success = await PricingTiersManagementService.createPricingTiers(
        defaultConfig,
        currentUser.uid,
      );

      if (success) {
        _showSuccessSnackBar(
          TranslationService.translate('default_config_created'),
        );
        await _loadPricingConfig();
      } else {
        _showErrorSnackBar(
          TranslationService.translate('failed_to_create_config'),
        );
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  // TODO: Tier creation is disabled until dynamic tier system is implemented
  // New tiers require integration with privilege system, feature guards, and billing
  void _addNewTier() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tier Creation Not Available'),
        content: Text(
          'Creating new tiers requires additional system changes. '
          'Only existing tiers (Free, Premium, Pro) can be modified at this time.\n\n'
          'This feature will be available in a future update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _editTier(String tierId, TierConfig tier) {
    showDialog(
      context: context,
      builder: (context) => _TierEditDialog(
        tier: tier,
        onSave: (tierConfig) async {
          await _updateExistingTier(tierId, tierConfig);
        },
      ),
    );
  }

  void _deleteTier(String tierId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('delete_tier')),
        content: Text(
          '${TranslationService.translate('delete_tier_confirmation')} "${_currentConfig!.tiers[tierId]!.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDeleteTier(tierId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(TranslationService.translate('delete')),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNewTier(TierConfig tierConfig) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar(
          TranslationService.translate('user_not_authenticated'),
        );
        return;
      }

      final tierId = tierConfig.name.toLowerCase().replaceAll(' ', '_');
      final success = await PricingTiersManagementService.addTier(
        tierId,
        tierConfig,
        currentUser.uid,
      );

      if (success) {
        _showSuccessSnackBar(
          TranslationService.translate('tier_added_successfully'),
        );
        await _loadPricingConfig();
      } else {
        _showErrorSnackBar(TranslationService.translate('failed_to_add_tier'));
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _updateExistingTier(String tierId, TierConfig tierConfig) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar(
          TranslationService.translate('user_not_authenticated'),
        );
        return;
      }

      // First update the tier
      final success = await PricingTiersManagementService.updateTier(
        tierId,
        tierConfig,
        currentUser.uid,
      );

      if (success) {
        // Then synchronize the regional pricing for this tier
        await _synchronizeRegionalPricing(tierId, tierConfig);

        _showSuccessSnackBar(
          TranslationService.translate('tier_updated_successfully'),
        );
        await _loadPricingConfig();
      } else {
        _showErrorSnackBar(
          TranslationService.translate('failed_to_update_tier'),
        );
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _synchronizeRegionalPricing(
    String tierId,
    TierConfig tierConfig,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Update the regional pricing for this tier's currency
      final success = await PricingTiersManagementService.setCurrencyPrice(
        tierConfig.currency,
        tierId,
        tierConfig.price,
        currentUser.uid,
      );

      if (!success) {
        _showErrorSnackBar(
          TranslationService.translate('failed_to_sync_regional_pricing'),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to sync regional pricing: $e');
    }
  }

  Future<void> _performDeleteTier(String tierId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar(
          TranslationService.translate('user_not_authenticated'),
        );
        return;
      }

      final success = await PricingTiersManagementService.removeTier(
        tierId,
        currentUser.uid,
      );

      if (success) {
        _showSuccessSnackBar(
          TranslationService.translate('tier_deleted_successfully'),
        );
        await _loadPricingConfig();
      } else {
        _showErrorSnackBar(
          TranslationService.translate('failed_to_delete_tier'),
        );
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  void _addNewPromotion() {
    showDialog(
      context: context,
      builder: (context) => _SpecialOfferEditDialog(
        offer: null,
        onSave: (offer) async {
          await _saveNewSpecialOffer(offer);
        },
      ),
    );
  }

  void _editSpecialOffer(SpecialOffer offer) {
    showDialog(
      context: context,
      builder: (context) => _SpecialOfferEditDialog(
        offer: offer,
        onSave: (updatedOffer) async {
          await _updateExistingSpecialOffer(offer.id, updatedOffer);
        },
      ),
    );
  }

  void _deleteSpecialOffer(String offerId) {
    final offer = _currentConfig!.promotions.specialOffers.firstWhere(
      (offer) => offer.id == offerId,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('delete_special_offer')),
        content: Text(
          '${TranslationService.translate('delete_special_offer_confirmation')} "${offer.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDeleteSpecialOffer(offerId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(TranslationService.translate('delete')),
          ),
        ],
      ),
    );
  }

  void _toggleSpecialOffer(String offerId, bool active) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar(
          TranslationService.translate('user_not_authenticated'),
        );
        return;
      }

      final currentOffers = List<SpecialOffer>.from(
        _currentConfig!.promotions.specialOffers,
      );
      final offerIndex = currentOffers.indexWhere(
        (offer) => offer.id == offerId,
      );

      if (offerIndex != -1) {
        currentOffers[offerIndex] = currentOffers[offerIndex].copyWith(
          active: active,
        );

        final updatedPromotions = _currentConfig!.promotions.copyWith(
          specialOffers: currentOffers,
        );

        final success = await PricingTiersManagementService.updatePromotions(
          updatedPromotions,
          currentUser.uid,
        );

        if (success) {
          _showSuccessSnackBar(
            active
                ? TranslationService.translate('special_offer_activated')
                : TranslationService.translate('special_offer_deactivated'),
          );
          await _loadPricingConfig();
        } else {
          _showErrorSnackBar(
            TranslationService.translate('failed_to_update_special_offer'),
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  void _updateAnnualDiscount(double discount) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar(
          TranslationService.translate('user_not_authenticated'),
        );
        return;
      }

      final updatedPromotions = _currentConfig!.promotions.copyWith(
        annualDiscount: discount.round(),
      );

      final success = await PricingTiersManagementService.updatePromotions(
        updatedPromotions,
        currentUser.uid,
      );

      if (success) {
        _showSuccessSnackBar(
          TranslationService.translate('annual_discount_updated'),
        );
        await _loadPricingConfig();
      } else {
        _showErrorSnackBar(
          TranslationService.translate('failed_to_update_annual_discount'),
        );
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  void _updateTrialDays(int days) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar(
          TranslationService.translate('user_not_authenticated'),
        );
        return;
      }

      final updatedPromotions = _currentConfig!.promotions.copyWith(
        trialDays: days,
      );

      final success = await PricingTiersManagementService.updatePromotions(
        updatedPromotions,
        currentUser.uid,
      );

      if (success) {
        _showSuccessSnackBar(
          TranslationService.translate('trial_days_updated'),
        );
        await _loadPricingConfig();
      } else {
        _showErrorSnackBar(
          TranslationService.translate('failed_to_update_trial_days'),
        );
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _saveNewSpecialOffer(SpecialOffer offer) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar(
          TranslationService.translate('user_not_authenticated'),
        );
        return;
      }

      final success = await PricingTiersManagementService.addSpecialOffer(
        offer,
        currentUser.uid,
      );

      if (success) {
        _showSuccessSnackBar(
          TranslationService.translate('special_offer_added_successfully'),
        );
        await _loadPricingConfig();
      } else {
        _showErrorSnackBar(
          TranslationService.translate('failed_to_add_special_offer'),
        );
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _updateExistingSpecialOffer(
    String offerId,
    SpecialOffer updatedOffer,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar(
          TranslationService.translate('user_not_authenticated'),
        );
        return;
      }

      final currentOffers = List<SpecialOffer>.from(
        _currentConfig!.promotions.specialOffers,
      );
      final offerIndex = currentOffers.indexWhere(
        (offer) => offer.id == offerId,
      );

      if (offerIndex != -1) {
        currentOffers[offerIndex] = updatedOffer;

        final updatedPromotions = _currentConfig!.promotions.copyWith(
          specialOffers: currentOffers,
        );

        final success = await PricingTiersManagementService.updatePromotions(
          updatedPromotions,
          currentUser.uid,
        );

        if (success) {
          _showSuccessSnackBar(
            TranslationService.translate('special_offer_updated_successfully'),
          );
          await _loadPricingConfig();
        } else {
          _showErrorSnackBar(
            TranslationService.translate('failed_to_update_special_offer'),
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _performDeleteSpecialOffer(String offerId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar(
          TranslationService.translate('user_not_authenticated'),
        );
        return;
      }

      final currentOffers = List<SpecialOffer>.from(
        _currentConfig!.promotions.specialOffers,
      );
      currentOffers.removeWhere((offer) => offer.id == offerId);

      final updatedPromotions = _currentConfig!.promotions.copyWith(
        specialOffers: currentOffers,
      );

      final success = await PricingTiersManagementService.updatePromotions(
        updatedPromotions,
        currentUser.uid,
      );

      if (success) {
        _showSuccessSnackBar(
          TranslationService.translate('special_offer_deleted_successfully'),
        );
        await _loadPricingConfig();
      } else {
        _showErrorSnackBar(
          TranslationService.translate('failed_to_delete_special_offer'),
        );
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  void _updateRegionalPrice(String currency, String tier, double price) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar(
          TranslationService.translate('user_not_authenticated'),
        );
        return;
      }

      final success = await PricingTiersManagementService.setCurrencyPrice(
        currency,
        tier,
        price,
        currentUser.uid,
      );

      if (success) {
        // Also update the corresponding tier's price if it matches the currency
        await _synchronizeTierPrice(tier, currency, price);

        _showSuccessSnackBar(
          TranslationService.translate('regional_price_updated'),
        );
        await _loadPricingConfig();
      } else {
        _showErrorSnackBar(
          TranslationService.translate('failed_to_update_regional_price'),
        );
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _synchronizeTierPrice(
    String tierId,
    String currency,
    double price,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Check if the tier exists and has the same currency
      if (_currentConfig?.tiers.containsKey(tierId) == true) {
        final tier = _currentConfig!.tiers[tierId]!;
        if (tier.currency == currency && tier.price != price) {
          // Update the tier's price to match the regional pricing
          final updatedTier = tier.copyWith(price: price);
          await PricingTiersManagementService.updateTier(
            tierId,
            updatedTier,
            currentUser.uid,
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to sync tier price: $e');
    }
  }

  void _saveConfiguration() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar(
          TranslationService.translate('user_not_authenticated'),
        );
        return;
      }

      if (_currentConfig == null) {
        _showErrorSnackBar(
          TranslationService.translate('no_configuration_to_save'),
        );
        return;
      }

      final success = await PricingTiersManagementService.updatePricingTiers(
        _currentConfig!,
        currentUser.uid,
      );

      if (success) {
        _showSuccessSnackBar(
          TranslationService.translate('configuration_saved_successfully'),
        );
        await _loadPricingConfig();
      } else {
        _showErrorSnackBar(
          TranslationService.translate('failed_to_save_configuration'),
        );
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  void _exportConfiguration() {
    if (_currentConfig == null) {
      _showErrorSnackBar(
        TranslationService.translate('no_configuration_to_export'),
      );
      return;
    }

    try {
      final configJson = _currentConfig!.toFirestore();
      final jsonString = const JsonEncoder.withIndent('  ').convert(configJson);

      // For now, just show the JSON in a dialog
      // In a real implementation, you might want to save to file or share
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(TranslationService.translate('export_configuration')),
          content: SingleChildScrollView(
            child: SelectableText(
              jsonString,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(TranslationService.translate('close')),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement actual file export or sharing
                _showInfoSnackBar(
                  'Export functionality will be implemented in the next phase',
                );
                Navigator.of(context).pop();
              },
              child: Text(TranslationService.translate('export')),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to export configuration: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue),
    );
  }
}

class _TierEditDialog extends StatefulWidget {
  final TierConfig? tier;
  final Function(TierConfig) onSave;

  const _TierEditDialog({required this.tier, required this.onSave});

  @override
  State<_TierEditDialog> createState() => _TierEditDialogState();
}

class _TierEditDialogState extends State<_TierEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late String _currency;
  late String _billingCycle;
  late bool _popular;
  late bool _recommended;
  
  // Validation state
  String? _nameError;
  String? _priceError;
  String? _descriptionError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tier?.name ?? '');
    _priceController = TextEditingController(
      text: widget.tier?.price.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.tier?.description ?? '',
    );
    _currency = widget.tier?.currency ?? 'USD';
    _billingCycle = widget.tier?.billingCycle ?? 'monthly';
    _popular = widget.tier?.popular ?? false;
    _recommended = widget.tier?.recommended ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Validation methods
  void _validateName(String value) {
    setState(() {
      _nameError = ValidationService.validateTitle(value);
    });
  }

  void _validatePrice(String value) {
    setState(() {
      if (value.isEmpty) {
        _priceError = TranslationService.translate('price_required');
      } else if (double.tryParse(value) == null) {
        _priceError = TranslationService.translate('invalid_price');
      } else if (double.parse(value) < 0) {
        _priceError = TranslationService.translate('price_must_be_positive');
      } else {
        _priceError = null;
      }
    });
  }

  void _validateDescription(String value) {
    setState(() {
      _descriptionError = ValidationService.validateDescription(value);
    });
  }

  bool _isFormValid() {
    return _nameError == null && 
           _priceError == null && 
           _descriptionError == null &&
           _nameController.text.trim().isNotEmpty &&
           _priceController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.tier != null;

    return AlertDialog(
      title: Text(
        isEditing
            ? TranslationService.translate('edit_tier')
            : TranslationService.translate('add_tier'),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: TranslationService.translate('tier_name'),
                  border: const OutlineInputBorder(),
                  errorText: _nameError,
                  suffixText: '${_nameController.text.length}/50',
                ),
                onChanged: _validateName,
                validator: (value) {
                  return ValidationService.validateTitle(value);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: TranslationService.translate('price'),
                        border: const OutlineInputBorder(),
                        errorText: _priceError,
                        suffixText: '${_priceController.text.length}/10',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: _validatePrice,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return TranslationService.translate('price_required');
                        }
                        if (double.tryParse(value) == null) {
                          return TranslationService.translate('invalid_price');
                        }
                        if (double.parse(value) < 0) {
                          return TranslationService.translate('price_must_be_positive');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
                      items: ['USD', 'EUR', 'GBP', 'CAD', 'AUD'].map((
                        currency,
                      ) {
                        return DropdownMenuItem(
                          value: currency,
                          child: Text(currency),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _currency = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _billingCycle,
                decoration: InputDecoration(
                  labelText: TranslationService.translate('billing_cycle'),
                  border: const OutlineInputBorder(),
                ),
                items: ['monthly', 'yearly', 'weekly'].map((cycle) {
                  return DropdownMenuItem(
                    value: cycle,
                    child: Text(TranslationService.translate(cycle)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _billingCycle = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: TranslationService.translate('description'),
                  border: const OutlineInputBorder(),
                  errorText: _descriptionError,
                  suffixText: '${_descriptionController.text.length}/500',
                ),
                onChanged: _validateDescription,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: Text(TranslationService.translate('popular')),
                      value: _popular,
                      onChanged: (value) {
                        setState(() {
                          _popular = value ?? false;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      title: Text(TranslationService.translate('recommended')),
                      value: _recommended,
                      onChanged: (value) {
                        setState(() {
                          _recommended = value ?? false;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(TranslationService.translate('cancel')),
        ),
        ElevatedButton(
          onPressed: _isFormValid() ? _saveTier : null,
          child: Text(
            isEditing
                ? TranslationService.translate('update')
                : TranslationService.translate('add'),
          ),
        ),
      ],
    );
  }

  void _saveTier() {
    if (_formKey.currentState!.validate() && _isFormValid()) {
      final tierConfig = TierConfig(
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        currency: _currency,
        billingCycle: _billingCycle,
        features: widget.tier?.features ?? {},
        limits: widget.tier?.limits ?? {},
        description: _descriptionController.text.trim(),
        popular: _popular,
        recommended: _recommended,
      );

      widget.onSave(tierConfig);
      Navigator.of(context).pop();
    } else {
      // Show error message if form is invalid
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationService.translate('please_fix_errors')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _SpecialOfferEditDialog extends StatefulWidget {
  final SpecialOffer? offer;
  final Function(SpecialOffer) onSave;

  const _SpecialOfferEditDialog({required this.offer, required this.onSave});

  @override
  State<_SpecialOfferEditDialog> createState() =>
      _SpecialOfferEditDialogState();
}

class _SpecialOfferEditDialogState extends State<_SpecialOfferEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _discountController;
  late TextEditingController _durationController;
  late TextEditingController _conditionsController;
  late DateTime _validFrom;
  late DateTime _validTo;
  late bool _active;
  
  // Validation state
  String? _idError;
  String? _nameError;
  String? _discountError;
  String? _durationError;
  String? _conditionsError;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.offer?.id ?? '');
    _nameController = TextEditingController(text: widget.offer?.name ?? '');
    _discountController = TextEditingController(
      text: widget.offer?.discount.toString() ?? '',
    );
    _durationController = TextEditingController(
      text: widget.offer?.duration ?? '',
    );
    _conditionsController = TextEditingController(
      text: widget.offer?.conditions.join(', ') ?? '',
    );
    _validFrom = widget.offer?.validFrom ?? DateTime.now();
    _validTo =
        widget.offer?.validTo ?? DateTime.now().add(const Duration(days: 30));
    _active = widget.offer?.active ?? true;
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _discountController.dispose();
    _durationController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  // Validation methods
  void _validateId(String value) {
    setState(() {
      if (value.isEmpty) {
        _idError = TranslationService.translate('offer_id_required');
      } else if (value.length < 3) {
        _idError = TranslationService.translate('offer_id_too_short');
      } else if (value.length > 20) {
        _idError = TranslationService.translate('offer_id_too_long');
      } else {
        _idError = null;
      }
    });
  }

  void _validateName(String value) {
    setState(() {
      _nameError = ValidationService.validateTitle(value);
    });
  }

  void _validateDiscount(String value) {
    setState(() {
      if (value.isEmpty) {
        _discountError = TranslationService.translate('discount_required');
      } else if (double.tryParse(value) == null) {
        _discountError = TranslationService.translate('invalid_discount');
      } else if (double.parse(value) < 0 || double.parse(value) > 100) {
        _discountError = TranslationService.translate('discount_range_error');
      } else {
        _discountError = null;
      }
    });
  }

  void _validateDuration(String value) {
    setState(() {
      if (value.isEmpty) {
        _durationError = TranslationService.translate('duration_required');
      } else if (value.length > 50) {
        _durationError = TranslationService.translate('duration_too_long');
      } else {
        _durationError = null;
      }
    });
  }

  void _validateConditions(String value) {
    setState(() {
      if (value.length > 200) {
        _conditionsError = TranslationService.translate('conditions_too_long');
      } else {
        _conditionsError = null;
      }
    });
  }

  bool _isFormValid() {
    return _idError == null && 
           _nameError == null && 
           _discountError == null &&
           _durationError == null &&
           _conditionsError == null &&
           _idController.text.trim().isNotEmpty &&
           _nameController.text.trim().isNotEmpty &&
           _discountController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.offer != null;

    return AlertDialog(
      title: Text(
        isEditing
            ? TranslationService.translate('edit_special_offer')
            : TranslationService.translate('add_special_offer'),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: TranslationService.translate('offer_id'),
                  border: const OutlineInputBorder(),
                  errorText: _idError,
                  suffixText: '${_idController.text.length}/20',
                ),
                onChanged: _validateId,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return TranslationService.translate('offer_id_required');
                  }
                  if (value.length < 3) {
                    return TranslationService.translate('offer_id_too_short');
                  }
                  if (value.length > 20) {
                    return TranslationService.translate('offer_id_too_long');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: TranslationService.translate('offer_name'),
                  border: const OutlineInputBorder(),
                  errorText: _nameError,
                  suffixText: '${_nameController.text.length}/50',
                ),
                onChanged: _validateName,
                validator: (value) {
                  return ValidationService.validateTitle(value);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _discountController,
                      decoration: InputDecoration(
                        labelText: TranslationService.translate(
                          'discount_percentage',
                        ),
                        border: const OutlineInputBorder(),
                        errorText: _discountError,
                        suffixText: '${_discountController.text.length}/3%',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: _validateDiscount,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return TranslationService.translate(
                            'discount_required',
                          );
                        }
                        final discount = int.tryParse(value);
                        if (discount == null ||
                            discount < 0 ||
                            discount > 100) {
                          return TranslationService.translate(
                            'invalid_discount',
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      decoration: InputDecoration(
                        labelText: TranslationService.translate('duration'),
                        border: const OutlineInputBorder(),
                        errorText: _durationError,
                        suffixText: '${_durationController.text.length}/50',
                      ),
                      onChanged: _validateDuration,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return TranslationService.translate(
                            'duration_required',
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(TranslationService.translate('valid_from')),
                      subtitle: Text(_formatDate(_validFrom)),
                      onTap: () => _selectDate(true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(TranslationService.translate('valid_to')),
                      subtitle: Text(_formatDate(_validTo)),
                      onTap: () => _selectDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _conditionsController,
                decoration: InputDecoration(
                  labelText: TranslationService.translate('conditions'),
                  hintText: TranslationService.translate('conditions_hint'),
                  border: const OutlineInputBorder(),
                  errorText: _conditionsError,
                  suffixText: '${_conditionsController.text.length}/200',
                ),
                onChanged: _validateConditions,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return TranslationService.translate('conditions_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: Text(TranslationService.translate('active')),
                value: _active,
                onChanged: (value) {
                  setState(() {
                    _active = value ?? false;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(TranslationService.translate('cancel')),
        ),
        ElevatedButton(
          onPressed: _isFormValid() ? _saveSpecialOffer : null,
          child: Text(
            isEditing
                ? TranslationService.translate('update')
                : TranslationService.translate('add'),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDate(bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _validFrom : _validTo,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _validFrom = picked;
        } else {
          _validTo = picked;
        }
      });
    }
  }

  void _saveSpecialOffer() {
    if (_formKey.currentState!.validate() && _isFormValid()) {
      if (_validFrom.isAfter(_validTo)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationService.translate('invalid_date_range')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final conditions = _conditionsController.text
          .split(',')
          .map((condition) => condition.trim())
          .where((condition) => condition.isNotEmpty)
          .toList();

      final specialOffer = SpecialOffer(
        id: _idController.text.trim(),
        name: _nameController.text.trim(),
        discount: int.parse(_discountController.text),
        duration: _durationController.text.trim(),
        validFrom: _validFrom,
        validTo: _validTo,
        conditions: conditions,
        active: _active,
      );

      widget.onSave(specialOffer);
      Navigator.of(context).pop();
    }
  }
}
