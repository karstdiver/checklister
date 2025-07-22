import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/services/acceptance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Log screen view for analytics
    AnalyticsService().logScreenView(screenName: 'UpgradeScreen');

    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.translate('upgrade')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Icon(Icons.workspace_premium, size: 80, color: Colors.amber),
            const SizedBox(height: 24),
            Text(
              TranslationService.translate('upgrade_benefits_title'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              TranslationService.translate('upgrade_benefits_desc'),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                AnalyticsService().logCustomEvent(name: 'upgrade_button_tap');
                // TODO: Implement upgrade flow (e.g., open purchase dialog)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      TranslationService.translate('upgrade_coming_soon'),
                    ),
                  ),
                );
              },
              child: Text(TranslationService.translate('upgrade_now')),
            ),
            const SizedBox(height: 16),
          ],
        ),
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
