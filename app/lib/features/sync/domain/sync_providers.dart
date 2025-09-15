import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/nearby_connection_service.dart';
import '../data/sync_repository.dart';

/// Nearby Connection Service provider
final nearbyConnectionServiceProvider = Provider<NearbyConnectionService>((
  ref,
) {
  final service = NearbyConnectionService();

  // Dispose service when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Sync Repository provider
final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final connectionService = ref.watch(nearbyConnectionServiceProvider);
  final repository = SyncRepository(connectionService);

  // Dispose repository when provider is disposed
  ref.onDispose(() {
    repository.dispose();
  });

  return repository;
});

/// Sync state provider (already defined in sync_state.dart)
// final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
//   return SyncNotifier();
// });
