import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:logger/logger.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  final Logger _logger = Logger();
  bool _isInitialized = false;

  // Initialize analytics service
  Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      _isInitialized = true;
      _logger.d('AnalyticsService initialized successfully');
    } catch (e) {
      _logger.w('AnalyticsService initialization failed: $e');
      _isInitialized = false;
    }
  }

  // Check if analytics is available
  bool get isAvailable => _isInitialized && _analytics != null;

  // Screen tracking
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!isAvailable) {
      _logger.d('Analytics: Screen view skipped - analytics not available');
      return;
    }
    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      _logger.d('Analytics: Screen view logged - $screenName');
    } catch (e) {
      _logger.e('Analytics: Failed to log screen view - $e');
    }
  }

  // Authentication events
  Future<void> logLogin({required String method}) async {
    if (!isAvailable) {
      _logger.d('Analytics: Login skipped - analytics not available');
      return;
    }
    try {
      await _analytics!.logLogin(loginMethod: method);
      _logger.d('Analytics: Login logged - $method');
    } catch (e) {
      _logger.e('Analytics: Failed to log login - $e');
    }
  }

  Future<void> logSignUp({required String method}) async {
    if (!isAvailable) {
      _logger.d('Analytics: Sign up skipped - analytics not available');
      return;
    }
    try {
      await _analytics!.logSignUp(signUpMethod: method);
      _logger.d('Analytics: Sign up logged - $method');
    } catch (e) {
      _logger.e('Analytics: Failed to log sign up - $e');
    }
  }

  Future<void> logLogout() async {
    if (!isAvailable) {
      _logger.d('Analytics: Logout skipped - analytics not available');
      return;
    }
    try {
      await _analytics!.logEvent(name: 'logout');
      _logger.d('Analytics: Logout logged');
    } catch (e) {
      _logger.e('Analytics: Failed to log logout - $e');
    }
  }

  // Checklist events
  Future<void> logChecklistCreated({required String checklistId}) async {
    if (!isAvailable) {
      _logger.d(
        'Analytics: Checklist created skipped - analytics not available',
      );
      return;
    }
    try {
      await _analytics!.logEvent(
        name: 'checklist_created',
        parameters: {'checklist_id': checklistId},
      );
      _logger.d('Analytics: Checklist created logged - $checklistId');
    } catch (e) {
      _logger.e('Analytics: Failed to log checklist created - $e');
    }
  }

  Future<void> logChecklistOpened({required String checklistId}) async {
    if (!isAvailable) {
      _logger.d(
        'Analytics: Checklist opened skipped - analytics not available',
      );
      return;
    }
    try {
      await _analytics!.logEvent(
        name: 'checklist_opened',
        parameters: {'checklist_id': checklistId},
      );
      _logger.d('Analytics: Checklist opened logged - $checklistId');
    } catch (e) {
      _logger.e('Analytics: Failed to log checklist opened - $e');
    }
  }

  Future<void> logItemChecked({
    required String checklistId,
    required String itemId,
    required bool isChecked,
  }) async {
    if (!isAvailable) {
      _logger.d('Analytics: Item checked skipped - analytics not available');
      return;
    }
    try {
      await _analytics!.logEvent(
        name: 'item_checked',
        parameters: {
          'checklist_id': checklistId,
          'item_id': itemId,
          'is_checked': isChecked,
        },
      );
      _logger.d(
        'Analytics: Item checked logged - $checklistId:$itemId:$isChecked',
      );
    } catch (e) {
      _logger.e('Analytics: Failed to log item checked - $e');
    }
  }

  // Custom events
  Future<void> logCustomEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!isAvailable) {
      _logger.d('Analytics: Custom event skipped - analytics not available');
      return;
    }
    try {
      await _analytics!.logEvent(name: name, parameters: parameters);
      _logger.d('Analytics: Custom event logged - $name');
    } catch (e) {
      _logger.e('Analytics: Failed to log custom event - $e');
    }
  }

  // User properties
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (!isAvailable) {
      _logger.d('Analytics: User property skipped - analytics not available');
      return;
    }
    try {
      await _analytics!.setUserProperty(name: name, value: value);
      _logger.d('Analytics: User property set - $name: $value');
    } catch (e) {
      _logger.e('Analytics: Failed to set user property - $e');
    }
  }

  // User ID
  Future<void> setUserId({required String userId}) async {
    if (!isAvailable) {
      _logger.d('Analytics: User ID skipped - analytics not available');
      return;
    }
    try {
      await _analytics!.setUserId(id: userId);
      _logger.d('Analytics: User ID set - $userId');
    } catch (e) {
      _logger.e('Analytics: Failed to set user ID - $e');
    }
  }
}
