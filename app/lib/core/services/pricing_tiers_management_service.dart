import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../domain/pricing_tiers_config.dart';

/// Service for managing pricing tiers configuration in Firestore
/// This service can only be used by existing admins
class PricingTiersManagementService {
  static final Logger _logger = Logger();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'pricingTiers';
  static const String _documentId = 'pricing_tiers_config';

  /// Get the current pricing tiers configuration
  static Future<PricingTiersConfig?> getPricingTiers() async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .get();

      if (!doc.exists) {
        _logger.w('⚠️ No pricing tiers configuration found');
        return null;
      }

      final data = doc.data()!;
      final config = PricingTiersConfig.fromFirestore(data);

      _logger.i('✅ Retrieved pricing tiers configuration: ${config.version}');
      return config;
    } catch (e) {
      _logger.e('❌ Error getting pricing tiers: $e');
      return null;
    }
  }

  /// Update the pricing tiers configuration
  static Future<bool> updatePricingTiers(
    PricingTiersConfig config,
    String updatedByUserId,
  ) async {
    try {
      // SECURITY: Verify that the updating user has admin privileges
      if (!await _canManagePricing(updatedByUserId)) {
        _logger.e(
          '❌ User $updatedByUserId lacks permission to update pricing tiers',
        );
        return false;
      }

      // Validate the configuration
      final validationErrors = getValidationErrors(config);
      if (validationErrors.isNotEmpty) {
        _logger.e('❌ Validation errors: ${validationErrors.join(', ')}');
        return false;
      }

      // Update with new metadata
      final updatedConfig = config.copyWith(
        lastUpdated: DateTime.now(),
        updatedBy: updatedByUserId,
      );

      await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .set(updatedConfig.toFirestore());

      _logger.i('✅ Successfully updated pricing tiers configuration');
      return true;
    } catch (e) {
      _logger.e('❌ Error updating pricing tiers: $e');
      return false;
    }
  }

  /// Create a new pricing tiers configuration
  static Future<bool> createPricingTiers(
    PricingTiersConfig config,
    String createdByUserId,
  ) async {
    try {
      // SECURITY: Verify that the creating user has admin privileges
      if (!await _canManagePricing(createdByUserId)) {
        _logger.e(
          '❌ User $createdByUserId lacks permission to create pricing tiers',
        );
        return false;
      }

      // Check if configuration already exists
      final existingDoc = await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .get();

      if (existingDoc.exists) {
        _logger.w('⚠️ Pricing tiers configuration already exists');
        return false;
      }

      // Validate the configuration
      final validationErrors = getValidationErrors(config);
      if (validationErrors.isNotEmpty) {
        _logger.e('❌ Validation errors: ${validationErrors.join(', ')}');
        return false;
      }

      // Create with metadata
      final newConfig = config.copyWith(
        lastUpdated: DateTime.now(),
        updatedBy: createdByUserId,
      );

      await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .set(newConfig.toFirestore());

      _logger.i('✅ Successfully created pricing tiers configuration');
      return true;
    } catch (e) {
      _logger.e('❌ Error creating pricing tiers: $e');
      return false;
    }
  }

  /// Delete the pricing tiers configuration
  static Future<bool> deletePricingTiers(String deletedByUserId) async {
    try {
      // SECURITY: Verify that the deleting user has admin privileges
      if (!await _canManagePricing(deletedByUserId)) {
        _logger.e(
          '❌ User $deletedByUserId lacks permission to delete pricing tiers',
        );
        return false;
      }

      await _firestore.collection(_collectionName).doc(_documentId).delete();

      _logger.i('✅ Successfully deleted pricing tiers configuration');
      return true;
    } catch (e) {
      _logger.e('❌ Error deleting pricing tiers: $e');
      return false;
    }
  }

  /// Update a specific tier
  static Future<bool> updateTier(
    String tierId,
    TierConfig tier,
    String updatedByUserId,
  ) async {
    try {
      // SECURITY: Verify that the updating user has admin privileges
      if (!await _canManagePricing(updatedByUserId)) {
        _logger.e('❌ User $updatedByUserId lacks permission to update tier');
        return false;
      }

      final currentConfig = await getPricingTiers();
      if (currentConfig == null) {
        _logger.e('❌ No pricing tiers configuration found');
        return false;
      }

      final updatedTiers = Map<String, TierConfig>.from(currentConfig.tiers);
      updatedTiers[tierId] = tier;

      final updatedConfig = currentConfig.copyWith(
        tiers: updatedTiers,
        lastUpdated: DateTime.now(),
        updatedBy: updatedByUserId,
      );

      return await updatePricingTiers(updatedConfig, updatedByUserId);
    } catch (e) {
      _logger.e('❌ Error updating tier: $e');
      return false;
    }
  }

  /// Add a new tier
  static Future<bool> addTier(
    String tierId,
    TierConfig tier,
    String addedByUserId,
  ) async {
    try {
      // SECURITY: Verify that the adding user has admin privileges
      if (!await _canManagePricing(addedByUserId)) {
        _logger.e('❌ User $addedByUserId lacks permission to add tier');
        return false;
      }

      final currentConfig = await getPricingTiers();
      if (currentConfig == null) {
        _logger.e('❌ No pricing tiers configuration found');
        return false;
      }

      if (currentConfig.tiers.containsKey(tierId)) {
        _logger.w('⚠️ Tier $tierId already exists');
        return false;
      }

      final updatedTiers = Map<String, TierConfig>.from(currentConfig.tiers);
      updatedTiers[tierId] = tier;

      final updatedConfig = currentConfig.copyWith(
        tiers: updatedTiers,
        lastUpdated: DateTime.now(),
        updatedBy: addedByUserId,
      );

      return await updatePricingTiers(updatedConfig, addedByUserId);
    } catch (e) {
      _logger.e('❌ Error adding tier: $e');
      return false;
    }
  }

  /// Remove a tier
  static Future<bool> removeTier(String tierId, String removedByUserId) async {
    try {
      // SECURITY: Verify that the removing user has admin privileges
      if (!await _canManagePricing(removedByUserId)) {
        _logger.e('❌ User $removedByUserId lacks permission to remove tier');
        return false;
      }

      final currentConfig = await getPricingTiers();
      if (currentConfig == null) {
        _logger.e('❌ No pricing tiers configuration found');
        return false;
      }

      if (!currentConfig.tiers.containsKey(tierId)) {
        _logger.w('⚠️ Tier $tierId does not exist');
        return false;
      }

      final updatedTiers = Map<String, TierConfig>.from(currentConfig.tiers);
      updatedTiers.remove(tierId);

      final updatedConfig = currentConfig.copyWith(
        tiers: updatedTiers,
        lastUpdated: DateTime.now(),
        updatedBy: removedByUserId,
      );

      return await updatePricingTiers(updatedConfig, removedByUserId);
    } catch (e) {
      _logger.e('❌ Error removing tier: $e');
      return false;
    }
  }

  /// Update promotions configuration
  static Future<bool> updatePromotions(
    PromotionsConfig promotions,
    String updatedByUserId,
  ) async {
    try {
      // SECURITY: Verify that the updating user has admin privileges
      if (!await _canManagePricing(updatedByUserId)) {
        _logger.e(
          '❌ User $updatedByUserId lacks permission to update promotions',
        );
        return false;
      }

      final currentConfig = await getPricingTiers();
      if (currentConfig == null) {
        _logger.e('❌ No pricing tiers configuration found');
        return false;
      }

      final updatedConfig = currentConfig.copyWith(
        promotions: promotions,
        lastUpdated: DateTime.now(),
        updatedBy: updatedByUserId,
      );

      return await updatePricingTiers(updatedConfig, updatedByUserId);
    } catch (e) {
      _logger.e('❌ Error updating promotions: $e');
      return false;
    }
  }

  /// Add a special offer
  static Future<bool> addSpecialOffer(
    SpecialOffer offer,
    String addedByUserId,
  ) async {
    try {
      // SECURITY: Verify that the adding user has admin privileges
      if (!await _canManagePricing(addedByUserId)) {
        _logger.e(
          '❌ User $addedByUserId lacks permission to add special offer',
        );
        return false;
      }

      final currentConfig = await getPricingTiers();
      if (currentConfig == null) {
        _logger.e('❌ No pricing tiers configuration found');
        return false;
      }

      final currentOffers = List<SpecialOffer>.from(
        currentConfig.promotions.specialOffers,
      );
      currentOffers.add(offer);

      final updatedPromotions = currentConfig.promotions.copyWith(
        specialOffers: currentOffers,
      );

      final updatedConfig = currentConfig.copyWith(
        promotions: updatedPromotions,
        lastUpdated: DateTime.now(),
        updatedBy: addedByUserId,
      );

      return await updatePricingTiers(updatedConfig, addedByUserId);
    } catch (e) {
      _logger.e('❌ Error adding special offer: $e');
      return false;
    }
  }

  /// Remove a special offer
  static Future<bool> removeSpecialOffer(
    String offerId,
    String removedByUserId,
  ) async {
    try {
      // SECURITY: Verify that the removing user has admin privileges
      if (!await _canManagePricing(removedByUserId)) {
        _logger.e(
          '❌ User $removedByUserId lacks permission to remove special offer',
        );
        return false;
      }

      final currentConfig = await getPricingTiers();
      if (currentConfig == null) {
        _logger.e('❌ No pricing tiers configuration found');
        return false;
      }

      final currentOffers = List<SpecialOffer>.from(
        currentConfig.promotions.specialOffers,
      );
      currentOffers.removeWhere((offer) => offer.id == offerId);

      final updatedPromotions = currentConfig.promotions.copyWith(
        specialOffers: currentOffers,
      );

      final updatedConfig = currentConfig.copyWith(
        promotions: updatedPromotions,
        lastUpdated: DateTime.now(),
        updatedBy: removedByUserId,
      );

      return await updatePricingTiers(updatedConfig, removedByUserId);
    } catch (e) {
      _logger.e('❌ Error removing special offer: $e');
      return false;
    }
  }

  /// Update regional pricing
  static Future<bool> updateRegionalPricing(
    Map<String, Map<String, double>> regionalPricing,
    String updatedByUserId,
  ) async {
    try {
      // SECURITY: Verify that the updating user has admin privileges
      if (!await _canManagePricing(updatedByUserId)) {
        _logger.e(
          '❌ User $updatedByUserId lacks permission to update regional pricing',
        );
        return false;
      }

      final currentConfig = await getPricingTiers();
      if (currentConfig == null) {
        _logger.e('❌ No pricing tiers configuration found');
        return false;
      }

      final updatedConfig = currentConfig.copyWith(
        regionalPricing: regionalPricing,
        lastUpdated: DateTime.now(),
        updatedBy: updatedByUserId,
      );

      return await updatePricingTiers(updatedConfig, updatedByUserId);
    } catch (e) {
      _logger.e('❌ Error updating regional pricing: $e');
      return false;
    }
  }

  /// Set price for a specific currency and tier
  static Future<bool> setCurrencyPrice(
    String currency,
    String tier,
    double price,
    String updatedByUserId,
  ) async {
    try {
      // SECURITY: Verify that the updating user has admin privileges
      if (!await _canManagePricing(updatedByUserId)) {
        _logger.e(
          '❌ User $updatedByUserId lacks permission to set currency price',
        );
        return false;
      }

      final currentConfig = await getPricingTiers();
      if (currentConfig == null) {
        _logger.e('❌ No pricing tiers configuration found');
        return false;
      }

      final updatedRegionalPricing = Map<String, Map<String, double>>.from(
        currentConfig.regionalPricing,
      );

      if (!updatedRegionalPricing.containsKey(currency)) {
        updatedRegionalPricing[currency] = {};
      }

      updatedRegionalPricing[currency]![tier] = price;

      final updatedConfig = currentConfig.copyWith(
        regionalPricing: updatedRegionalPricing,
        lastUpdated: DateTime.now(),
        updatedBy: updatedByUserId,
      );

      return await updatePricingTiers(updatedConfig, updatedByUserId);
    } catch (e) {
      _logger.e('❌ Error setting currency price: $e');
      return false;
    }
  }

  /// Validate pricing tiers configuration
  static bool validatePricingTiers(PricingTiersConfig config) {
    return getValidationErrors(config).isEmpty;
  }

  /// Get validation errors for pricing tiers configuration
  static List<String> getValidationErrors(PricingTiersConfig config) {
    final errors = <String>[];

    // Basic validation
    if (config.id.isEmpty) {
      errors.add('Configuration ID is required');
    }

    if (config.version.isEmpty) {
      errors.add('Version is required');
    }

    if (config.updatedBy.isEmpty) {
      errors.add('Updated by user ID is required');
    }

    // Tiers validation
    if (config.tiers.isEmpty) {
      errors.add('At least one tier is required');
    }

    for (final entry in config.tiers.entries) {
      final tierId = entry.key;
      final tier = entry.value;

      if (tier.name.isEmpty) {
        errors.add('Tier $tierId: Name is required');
      }

      if (tier.price < 0) {
        errors.add('Tier $tierId: Price cannot be negative');
      }

      if (tier.currency.isEmpty) {
        errors.add('Tier $tierId: Currency is required');
      }

      if (tier.billingCycle.isEmpty) {
        errors.add('Tier $tierId: Billing cycle is required');
      }

      if (tier.description.isEmpty) {
        errors.add('Tier $tierId: Description is required');
      }

      // Validate features
      if (tier.features.isEmpty) {
        errors.add('Tier $tierId: At least one feature is required');
      }

      // Validate limits
      if (tier.limits.isEmpty) {
        errors.add('Tier $tierId: At least one limit is required');
      }
    }

    // Promotions validation
    if (config.promotions.annualDiscount < 0 ||
        config.promotions.annualDiscount > 100) {
      errors.add('Annual discount must be between 0 and 100');
    }

    if (config.promotions.trialDays < 0) {
      errors.add('Trial days cannot be negative');
    }

    // Special offers validation
    for (final offer in config.promotions.specialOffers) {
      if (offer.id.isEmpty) {
        errors.add('Special offer: ID is required');
      }

      if (offer.name.isEmpty) {
        errors.add('Special offer ${offer.id}: Name is required');
      }

      if (offer.discount < 0 || offer.discount > 100) {
        errors.add(
          'Special offer ${offer.id}: Discount must be between 0 and 100',
        );
      }

      if (offer.duration.isEmpty) {
        errors.add('Special offer ${offer.id}: Duration is required');
      }

      if (offer.validFrom.isAfter(offer.validTo)) {
        errors.add(
          'Special offer ${offer.id}: Valid from date must be before valid to date',
        );
      }

      if (offer.conditions.isEmpty) {
        errors.add(
          'Special offer ${offer.id}: At least one condition is required',
        );
      }
    }

    return errors;
  }

  /// Check if a user can manage pricing tiers
  static Future<bool> _canManagePricing(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return false;
      }

      final userData = userDoc.data()!;
      final adminRole = userData['adminRole'] as String?;

      return adminRole == 'admin' || adminRole == 'superAdmin';
    } catch (e) {
      _logger.e('❌ Error checking pricing management permissions: $e');
      return false;
    }
  }

  /// Create default pricing tiers configuration
  static PricingTiersConfig createDefaultConfig(String createdByUserId) {
    return PricingTiersConfig(
      id: _documentId,
      version: '1.0',
      lastUpdated: DateTime.now(),
      updatedBy: createdByUserId,
      active: true,
      tiers: {
        'free': TierConfig(
          name: 'Free',
          price: 0,
          currency: 'USD',
          billingCycle: 'monthly',
          features: {
            'maxChecklists': 5,
            'maxItemsPerChecklist': 15,
            'sessionPersistence': true,
            'analytics': false,
            'export': false,
            'sharing': false,
            'customThemes': false,
            'prioritySupport': false,
            'profilePictures': false,
            'itemPhotos': false,
            'aiTemplates': false,
            'achievements': true,
            'achievementSharing': false,
            'achievementLeaderboards': false,
          },
          limits: {
            'checklistsCreated': 5,
            'sessionsCompleted': 10,
            'itemsPerChecklist': 15,
          },
          description: 'Perfect for getting started',
          popular: false,
          recommended: false,
        ),
        'premium': TierConfig(
          name: 'Premium',
          price: 9.99,
          currency: 'USD',
          billingCycle: 'monthly',
          features: {
            'maxChecklists': 50,
            'maxItemsPerChecklist': 100,
            'sessionPersistence': true,
            'analytics': true,
            'export': true,
            'sharing': true,
            'customThemes': false,
            'prioritySupport': false,
            'profilePictures': true,
            'itemPhotos': true,
            'aiTemplates': true,
            'achievements': true,
            'achievementSharing': true,
            'achievementLeaderboards': false,
          },
          limits: {
            'checklistsCreated': 50,
            'sessionsCompleted': 100,
            'itemsPerChecklist': 100,
          },
          description: 'Most popular choice',
          popular: true,
          recommended: true,
        ),
        'pro': TierConfig(
          name: 'Pro',
          price: 19.99,
          currency: 'USD',
          billingCycle: 'monthly',
          features: {
            'maxChecklists': -1,
            'maxItemsPerChecklist': -1,
            'sessionPersistence': true,
            'analytics': true,
            'export': true,
            'sharing': true,
            'customThemes': true,
            'prioritySupport': true,
            'profilePictures': true,
            'itemPhotos': true,
            'aiTemplates': true,
            'achievements': true,
            'achievementSharing': true,
            'achievementLeaderboards': true,
          },
          limits: {
            'checklistsCreated': -1,
            'sessionsCompleted': -1,
            'itemsPerChecklist': -1,
          },
          description: 'For power users and teams',
          popular: false,
          recommended: false,
        ),
      },
      promotions: PromotionsConfig(
        annualDiscount: 20,
        trialDays: 7,
        specialOffers: [
          SpecialOffer(
            id: 'new_user_50_off',
            name: 'New User 50% Off',
            discount: 50,
            duration: '3_months',
            validFrom: DateTime(2024, 1, 1),
            validTo: DateTime(2024, 12, 31),
            conditions: ['new_user', 'first_purchase'],
            active: true,
          ),
        ],
      ),
      regionalPricing: {
        'USD': {'free': 0, 'premium': 9.99, 'pro': 19.99},
        'EUR': {'free': 0, 'premium': 8.99, 'pro': 17.99},
        'GBP': {'free': 0, 'premium': 7.99, 'pro': 15.99},
      },
    );
  }
}
