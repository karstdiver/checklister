import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/domain/pricing_tiers_config.dart';
import '../../../core/services/pricing_tiers_management_service.dart';
import '../../../core/services/translation_service.dart';

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                TranslationService.translate('pricing_tiers'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              ElevatedButton.icon(
                onPressed: _addNewTier,
                icon: const Icon(Icons.add),
                label: Text(TranslationService.translate('add_tier')),
              ),
            ],
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
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _currentConfig!.regionalPricing.length,
              itemBuilder: (context, index) {
                final currency = _currentConfig!.regionalPricing.keys.elementAt(
                  index,
                );
                final prices = _currentConfig!.regionalPricing[currency]!;
                return _buildRegionalPricingCard(currency, prices);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionalPricingCard(
    String currency,
    Map<String, double> prices,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text('$currency Pricing'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: prices.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(entry.key)),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          initialValue: entry.value.toString(),
                          decoration: InputDecoration(
                            labelText: TranslationService.translate('price'),
                            prefixText: currency,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => _updateRegionalPrice(
                            currency,
                            entry.key,
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

  void _addNewTier() {
    // TODO: Implement add new tier dialog
    _showInfoSnackBar('Add new tier functionality coming soon');
  }

  void _editTier(String tierId, TierConfig tier) {
    // TODO: Implement edit tier dialog
    _showInfoSnackBar('Edit tier functionality coming soon');
  }

  void _deleteTier(String tierId) {
    // TODO: Implement delete tier confirmation
    _showInfoSnackBar('Delete tier functionality coming soon');
  }

  void _addNewPromotion() {
    // TODO: Implement add new promotion dialog
    _showInfoSnackBar('Add new promotion functionality coming soon');
  }

  void _editSpecialOffer(SpecialOffer offer) {
    // TODO: Implement edit special offer dialog
    _showInfoSnackBar('Edit special offer functionality coming soon');
  }

  void _deleteSpecialOffer(String offerId) {
    // TODO: Implement delete special offer confirmation
    _showInfoSnackBar('Delete special offer functionality coming soon');
  }

  void _toggleSpecialOffer(String offerId, bool active) {
    // TODO: Implement toggle special offer
    _showInfoSnackBar('Toggle special offer functionality coming soon');
  }

  void _updateAnnualDiscount(double discount) {
    // TODO: Implement update annual discount
    _showInfoSnackBar('Update annual discount functionality coming soon');
  }

  void _updateTrialDays(int days) {
    // TODO: Implement update trial days
    _showInfoSnackBar('Update trial days functionality coming soon');
  }

  void _updateRegionalPrice(String currency, String tier, double price) {
    // TODO: Implement update regional price
    _showInfoSnackBar('Update regional price functionality coming soon');
  }

  void _saveConfiguration() {
    // TODO: Implement save configuration
    _showInfoSnackBar('Save configuration functionality coming soon');
  }

  void _exportConfiguration() {
    // TODO: Implement export configuration
    _showInfoSnackBar('Export configuration functionality coming soon');
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
