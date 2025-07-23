import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/providers/providers.dart';
import '../../domain/checklist_providers.dart';

final connectivityProvider = StreamProvider<ConnectivityResult>((ref) async* {
  final initial = await Connectivity().checkConnectivity();
  yield initial;
  yield* Connectivity().onConnectivityChanged;
});

class ConnectivityTestPanel extends ConsumerStatefulWidget {
  const ConnectivityTestPanel({super.key});

  @override
  ConsumerState<ConnectivityTestPanel> createState() =>
      _ConnectivityTestPanelState();
}

class _ConnectivityTestPanelState extends ConsumerState<ConnectivityTestPanel> {
  ConnectivityResult? _forcedConnectivity;
  bool _showPanel = false;

  @override
  Widget build(BuildContext context) {
    final currentConnectivity = ref.watch(connectivityProvider);

    return Column(
      children: [
        // Toggle button
        ElevatedButton(
          onPressed: () => setState(() => _showPanel = !_showPanel),
          child: Text(_showPanel ? 'Hide Test Panel' : 'Show Test Panel'),
        ),

        if (_showPanel) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connectivity Test Panel',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current: ${currentConnectivity.asData?.value ?? 'Unknown'}',
                  ),
                  if (_forcedConnectivity != null)
                    Text('Forced: $_forcedConnectivity'),
                  const SizedBox(height: 16),

                  // Test buttons
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            _testConnectivity(ConnectivityResult.wifi),
                        child: const Text('Test WiFi'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            _testConnectivity(ConnectivityResult.mobile),
                        child: const Text('Test Mobile'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            _testConnectivity(ConnectivityResult.none),
                        child: const Text('Test Offline'),
                      ),
                      ElevatedButton(
                        onPressed: () => _testConnectivity(null),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Reload button
                  ElevatedButton(
                    onPressed: _reloadChecklists,
                    child: const Text('Reload Checklists'),
                  ),

                  const SizedBox(height: 8),

                  // Clear local data button (for testing fresh install scenarios)
                  ElevatedButton(
                    onPressed: _clearLocalData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red[800],
                    ),
                    child: const Text('Clear Local Data'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _testConnectivity(ConnectivityResult? connectivity) {
    setState(() {
      _forcedConnectivity = connectivity;
    });

    // Reload checklists with forced connectivity
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      // For offline testing, we want to preserve local data
      // For online testing, we might want to refresh from Firestore
      if (connectivity == ConnectivityResult.none) {
        // Offline test: just load with offline connectivity (preserves local data)
        ref
            .read(checklistNotifierProvider.notifier)
            .loadUserChecklists(currentUser.uid, connectivity: connectivity);
      } else {
        // Online test: refresh from Firestore to get latest data
        ref
            .read(checklistNotifierProvider.notifier)
            .refreshFromFirestore(currentUser.uid);
      }
    }
  }

  void _reloadChecklists() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      ref
          .read(checklistNotifierProvider.notifier)
          .loadUserChecklists(
            currentUser.uid,
            connectivity: _forcedConnectivity,
          );
    }
  }

  void _clearLocalData() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      // Clear local data and reload with current connectivity
      ref
          .read(checklistNotifierProvider.notifier)
          .refreshFromFirestore(currentUser.uid);
    }
  }
}
