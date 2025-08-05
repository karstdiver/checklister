import 'package:cloud_firestore/cloud_firestore.dart';

/// Configuration for pricing tiers stored in Firestore
class PricingTiersConfig {
  final String id;
  final String version;
  final DateTime lastUpdated;
  final String updatedBy;
  final bool active;
  final Map<String, TierConfig> tiers;
  final PromotionsConfig promotions;
  final Map<String, Map<String, double>> regionalPricing;

  const PricingTiersConfig({
    required this.id,
    required this.version,
    required this.lastUpdated,
    required this.updatedBy,
    required this.active,
    required this.tiers,
    required this.promotions,
    required this.regionalPricing,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'version': version,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'updatedBy': updatedBy,
      'active': active,
      'tiers': tiers.map((key, value) => MapEntry(key, value.toFirestore())),
      'promotions': promotions.toFirestore(),
      'regionalPricing': regionalPricing,
    };
  }

  /// Create from Firestore document
  factory PricingTiersConfig.fromFirestore(Map<String, dynamic> data) {
    return PricingTiersConfig(
      id: data['id'] ?? '',
      version: data['version'] ?? '1.0',
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      updatedBy: data['updatedBy'] ?? '',
      active: data['active'] ?? true,
      tiers: (data['tiers'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, TierConfig.fromFirestore(value)),
      ),
      promotions: PromotionsConfig.fromFirestore(data['promotions'] ?? {}),
      regionalPricing: _parseRegionalPricing(data['regionalPricing']),
    );
  }

  /// Create a copy with updated fields
  PricingTiersConfig copyWith({
    String? id,
    String? version,
    DateTime? lastUpdated,
    String? updatedBy,
    bool? active,
    Map<String, TierConfig>? tiers,
    PromotionsConfig? promotions,
    Map<String, Map<String, double>>? regionalPricing,
  }) {
    return PricingTiersConfig(
      id: id ?? this.id,
      version: version ?? this.version,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
      active: active ?? this.active,
      tiers: tiers ?? this.tiers,
      promotions: promotions ?? this.promotions,
      regionalPricing: regionalPricing ?? this.regionalPricing,
    );
  }

  /// Helper method to parse regional pricing from Firestore data
  static Map<String, Map<String, double>> _parseRegionalPricing(dynamic data) {
    if (data == null) return {};

    if (data is Map<String, dynamic>) {
      return data.map((currency, prices) {
        if (prices is Map<String, dynamic>) {
          return MapEntry(
            currency,
            prices.map((tier, price) {
              if (price is num) {
                return MapEntry(tier, price.toDouble());
              }
              return MapEntry(tier, 0.0);
            }),
          );
        }
        return MapEntry(currency, <String, double>{});
      });
    }

    return {};
  }
}

/// Configuration for a single pricing tier
class TierConfig {
  final String name;
  final double price;
  final String currency;
  final String billingCycle;
  final Map<String, dynamic> features;
  final Map<String, int> limits;
  final String description;
  final bool popular;
  final bool recommended;

  const TierConfig({
    required this.name,
    required this.price,
    required this.currency,
    required this.billingCycle,
    required this.features,
    required this.limits,
    required this.description,
    required this.popular,
    required this.recommended,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'currency': currency,
      'billingCycle': billingCycle,
      'features': features,
      'limits': limits,
      'description': description,
      'popular': popular,
      'recommended': recommended,
    };
  }

  /// Create from Firestore document
  factory TierConfig.fromFirestore(Map<String, dynamic> data) {
    return TierConfig(
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      billingCycle: data['billingCycle'] ?? 'monthly',
      features: Map<String, dynamic>.from(data['features'] ?? {}),
      limits: Map<String, int>.from(data['limits'] ?? {}),
      description: data['description'] ?? '',
      popular: data['popular'] ?? false,
      recommended: data['recommended'] ?? false,
    );
  }

  /// Create a copy with updated fields
  TierConfig copyWith({
    String? name,
    double? price,
    String? currency,
    String? billingCycle,
    Map<String, dynamic>? features,
    Map<String, int>? limits,
    String? description,
    bool? popular,
    bool? recommended,
  }) {
    return TierConfig(
      name: name ?? this.name,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      features: features ?? this.features,
      limits: limits ?? this.limits,
      description: description ?? this.description,
      popular: popular ?? this.popular,
      recommended: recommended ?? this.recommended,
    );
  }
}

/// Configuration for promotions and special offers
class PromotionsConfig {
  final int annualDiscount;
  final int trialDays;
  final List<SpecialOffer> specialOffers;

  const PromotionsConfig({
    required this.annualDiscount,
    required this.trialDays,
    required this.specialOffers,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'annualDiscount': annualDiscount,
      'trialDays': trialDays,
      'specialOffers': specialOffers
          .map((offer) => offer.toFirestore())
          .toList(),
    };
  }

  /// Create from Firestore document
  factory PromotionsConfig.fromFirestore(Map<String, dynamic> data) {
    return PromotionsConfig(
      annualDiscount: data['annualDiscount'] ?? 0,
      trialDays: data['trialDays'] ?? 0,
      specialOffers:
          (data['specialOffers'] as List<dynamic>?)
              ?.map((offer) => SpecialOffer.fromFirestore(offer))
              .toList() ??
          [],
    );
  }

  /// Create a copy with updated fields
  PromotionsConfig copyWith({
    int? annualDiscount,
    int? trialDays,
    List<SpecialOffer>? specialOffers,
  }) {
    return PromotionsConfig(
      annualDiscount: annualDiscount ?? this.annualDiscount,
      trialDays: trialDays ?? this.trialDays,
      specialOffers: specialOffers ?? this.specialOffers,
    );
  }
}

/// Configuration for a special offer
class SpecialOffer {
  final String id;
  final String name;
  final int discount;
  final String duration;
  final DateTime validFrom;
  final DateTime validTo;
  final List<String> conditions;
  final bool active;

  const SpecialOffer({
    required this.id,
    required this.name,
    required this.discount,
    required this.duration,
    required this.validFrom,
    required this.validTo,
    required this.conditions,
    required this.active,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'discount': discount,
      'duration': duration,
      'validFrom': Timestamp.fromDate(validFrom),
      'validTo': Timestamp.fromDate(validTo),
      'conditions': conditions,
      'active': active,
    };
  }

  /// Create from Firestore document
  factory SpecialOffer.fromFirestore(Map<String, dynamic> data) {
    return SpecialOffer(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      discount: data['discount'] ?? 0,
      duration: data['duration'] ?? '',
      validFrom: (data['validFrom'] as Timestamp).toDate(),
      validTo: (data['validTo'] as Timestamp).toDate(),
      conditions: List<String>.from(data['conditions'] ?? []),
      active: data['active'] ?? false,
    );
  }

  /// Create a copy with updated fields
  SpecialOffer copyWith({
    String? id,
    String? name,
    int? discount,
    String? duration,
    DateTime? validFrom,
    DateTime? validTo,
    List<String>? conditions,
    bool? active,
  }) {
    return SpecialOffer(
      id: id ?? this.id,
      name: name ?? this.name,
      discount: discount ?? this.discount,
      duration: duration ?? this.duration,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      conditions: conditions ?? this.conditions,
      active: active ?? this.active,
    );
  }
}
