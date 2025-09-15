import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sync connection status
enum SyncConnectionStatus {
  disconnected,
  discovering,
  connecting,
  connected,
  error,
}

/// Sync message types for phone-watch communication
enum SyncMessageType {
  checklistUpdate, // Checklist modified
  itemStatusChange, // Item checked/unchecked
  checklistCreate, // New checklist created
  checklistDelete, // Checklist deleted
  syncRequest, // Request full sync
  syncResponse, // Full sync data
  heartbeat, // Keep connection alive
}

/// Sync message for phone-watch communication
class SyncMessage {
  final String id;
  final SyncMessageType type;
  final String userId;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String deviceId;

  const SyncMessage({
    required this.id,
    required this.type,
    required this.userId,
    required this.data,
    required this.timestamp,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'userId': userId,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'deviceId': deviceId,
    };
  }

  factory SyncMessage.fromJson(Map<String, dynamic> json) {
    return SyncMessage(
      id: json['id'] as String,
      type: SyncMessageType.values.firstWhere((e) => e.name == json['type']),
      userId: json['userId'] as String,
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      deviceId: json['deviceId'] as String,
    );
  }
}

/// Sync state for managing phone-watch connectivity
class SyncState {
  final SyncConnectionStatus connectionStatus;
  final String? connectedDeviceId;
  final String? errorMessage;
  final DateTime lastSyncTime;
  final bool isSyncing;
  final int pendingMessages;

  const SyncState({
    this.connectionStatus = SyncConnectionStatus.disconnected,
    this.connectedDeviceId,
    this.errorMessage,
    required this.lastSyncTime,
    this.isSyncing = false,
    this.pendingMessages = 0,
  });

  SyncState copyWith({
    SyncConnectionStatus? connectionStatus,
    String? connectedDeviceId,
    String? errorMessage,
    DateTime? lastSyncTime,
    bool? isSyncing,
    int? pendingMessages,
  }) {
    return SyncState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      connectedDeviceId: connectedDeviceId ?? this.connectedDeviceId,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingMessages: pendingMessages ?? this.pendingMessages,
    );
  }

  bool get isConnected => connectionStatus == SyncConnectionStatus.connected;
  bool get hasError => connectionStatus == SyncConnectionStatus.error;
  bool get isDiscovering =>
      connectionStatus == SyncConnectionStatus.discovering;
  bool get isConnecting => connectionStatus == SyncConnectionStatus.connecting;
}

/// Sync state notifier for managing phone-watch connectivity
class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier() : super(SyncState(lastSyncTime: DateTime.now()));

  void setConnectionStatus(SyncConnectionStatus status) {
    state = state.copyWith(connectionStatus: status);
  }

  void setConnectedDevice(String deviceId) {
    state = state.copyWith(
      connectionStatus: SyncConnectionStatus.connected,
      connectedDeviceId: deviceId,
    );
  }

  void setError(String errorMessage) {
    state = state.copyWith(
      connectionStatus: SyncConnectionStatus.error,
      errorMessage: errorMessage,
    );
  }

  void setSyncing(bool isSyncing) {
    state = state.copyWith(isSyncing: isSyncing);
  }

  void setPendingMessages(int count) {
    state = state.copyWith(pendingMessages: count);
  }

  void updateLastSyncTime() {
    state = state.copyWith(lastSyncTime: DateTime.now());
  }

  void clearError() {
    state = state.copyWith(
      connectionStatus: SyncConnectionStatus.disconnected,
      errorMessage: null,
    );
  }
}

/// Sync state provider
final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncState>((
  ref,
) {
  return SyncNotifier();
});

