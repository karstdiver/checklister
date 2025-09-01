import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();

/// Wear OS specific state
class WearOSState {
  final bool isConnected;
  final bool isSyncing;
  final String? lastSyncTime;
  final String? error;

  const WearOSState({
    this.isConnected = false,
    this.isSyncing = false,
    this.lastSyncTime,
    this.error,
  });

  WearOSState copyWith({
    bool? isConnected,
    bool? isSyncing,
    String? lastSyncTime,
    String? error,
  }) {
    return WearOSState(
      isConnected: isConnected ?? this.isConnected,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      error: error ?? this.error,
    );
  }
}

/// Wear OS state notifier
class WearOSNotifier extends StateNotifier<WearOSState> {
  WearOSNotifier() : super(const WearOSState());

  void setConnected(bool connected) {
    logger.i('⌚ Wear OS connection status: $connected');
    state = state.copyWith(
      isConnected: connected,
      error: connected ? null : state.error,
    );
  }

  void setSyncing(bool syncing) {
    logger.i('⌚ Wear OS sync status: $syncing');
    state = state.copyWith(isSyncing: syncing);
  }

  void setLastSyncTime(String time) {
    logger.i('⌚ Wear OS last sync: $time');
    state = state.copyWith(
      lastSyncTime: time,
      isSyncing: false,
    );
  }

  void setError(String error) {
    logger.e('⌚ Wear OS error: $error');
    state = state.copyWith(
      error: error,
      isSyncing: false,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Wear OS provider
final wearOSProvider = StateNotifierProvider<WearOSNotifier, WearOSState>((ref) {
  return WearOSNotifier();
});

/// Wear OS connection status provider
final wearOSConnectionProvider = Provider<bool>((ref) {
  return ref.watch(wearOSProvider).isConnected;
});

/// Wear OS sync status provider
final wearOSSyncProvider = Provider<bool>((ref) {
  return ref.watch(wearOSProvider).isSyncing;
});
