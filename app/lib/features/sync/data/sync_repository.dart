import 'dart:async';
import 'package:logger/logger.dart';
import '../domain/sync_state.dart';
import 'nearby_connection_service.dart';
import '../../checklists/domain/checklist.dart';

final Logger logger = Logger();

/// Repository for managing sync operations between phone and watch
class SyncRepository {
  final NearbyConnectionService _connectionService;
  final StreamController<SyncMessage> _syncMessageController =
      StreamController.broadcast();

  Timer? _syncTimer;
  final List<SyncMessage> _pendingMessages = [];

  SyncRepository(this._connectionService) {
    _setupMessageHandling();
  }

  /// Start near-realtime sync (5-10 second intervals)
  void startNearRealtimeSync({Duration interval = const Duration(seconds: 8)}) {
    logger.i(
      '🔄 Starting near-realtime sync with ${interval.inSeconds}s interval',
    );

    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) {
      _processPendingMessages();
    });
  }

  /// Stop near-realtime sync
  void stopNearRealtimeSync() {
    logger.i('🛑 Stopping near-realtime sync');
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Send checklist update to connected device
  Future<void> sendChecklistUpdate(Checklist checklist) async {
    final message = SyncMessage(
      id: '${checklist.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncMessageType.checklistUpdate,
      userId: checklist.userId,
      data: checklist.toJson(),
      timestamp: DateTime.now(),
      deviceId: 'current_device', // Will be replaced with actual device ID
    );

    await _queueMessage(message);
  }

  /// Send item status change to connected device
  Future<void> sendItemStatusChange({
    required String checklistId,
    required ChecklistItem item,
    required String userId,
  }) async {
    final message = SyncMessage(
      id: '${item.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncMessageType.itemStatusChange,
      userId: userId,
      data: {'checklistId': checklistId, 'item': item.toJson()},
      timestamp: DateTime.now(),
      deviceId: 'current_device', // Will be replaced with actual device ID
    );

    await _queueMessage(message);
  }

  /// Send sync request to connected device
  Future<void> requestFullSync(String userId) async {
    final message = SyncMessage(
      id: 'sync_request_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncMessageType.syncRequest,
      userId: userId,
      data: {'requestType': 'full'},
      timestamp: DateTime.now(),
      deviceId: 'current_device',
    );

    await _queueMessage(message);
  }

  /// Send heartbeat to keep connection alive
  Future<void> sendHeartbeat(String userId) async {
    final message = SyncMessage(
      id: 'heartbeat_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncMessageType.heartbeat,
      userId: userId,
      data: {'timestamp': DateTime.now().toIso8601String()},
      timestamp: DateTime.now(),
      deviceId: 'current_device',
    );

    await _queueMessage(message);
  }

  /// Stream of sync messages from connected device
  Stream<SyncMessage> get syncMessageStream => _syncMessageController.stream;

  /// Get pending messages count
  int get pendingMessagesCount => _pendingMessages.length;

  /// Process pending messages (called by timer)
  Future<void> _processPendingMessages() async {
    if (_pendingMessages.isEmpty) return;

    logger.i('📤 Processing ${_pendingMessages.length} pending sync messages');

    final messagesToSend = List<SyncMessage>.from(_pendingMessages);
    _pendingMessages.clear();

    for (final message in messagesToSend) {
      try {
        await _connectionService.sendMessage(message);
        logger.d('✅ Sent message: ${message.type.name}');
      } catch (e) {
        logger.e('❌ Failed to send message: $e');
        // Re-queue failed messages
        _pendingMessages.add(message);
      }
    }
  }

  /// Queue a message for sending
  Future<void> _queueMessage(SyncMessage message) async {
    _pendingMessages.add(message);
    logger.d('📝 Queued message: ${message.type.name}');

    // If this is a critical message, send immediately
    if (message.type == SyncMessageType.itemStatusChange) {
      await _processPendingMessages();
    }
  }

  /// Setup message handling from connection service
  void _setupMessageHandling() {
    _connectionService.messageStream.listen((message) {
      logger.i('📥 Received sync message: ${message.type.name}');
      _syncMessageController.add(message);
    });
  }

  /// Apply conflict resolution using lastWriteWins strategy
  Checklist resolveChecklistConflict(Checklist local, Checklist remote) {
    // Simple lastWriteWins: use the checklist with the most recent timestamp
    if (remote.updatedAt.isAfter(local.updatedAt)) {
      logger.i(
        '🔄 Conflict resolved: using remote checklist (${remote.updatedAt})',
      );
      return remote;
    } else {
      logger.i(
        '🔄 Conflict resolved: using local checklist (${local.updatedAt})',
      );
      return local;
    }
  }

  /// Apply conflict resolution for item status changes
  ChecklistItem resolveItemConflict(ChecklistItem local, ChecklistItem remote) {
    // Simple lastWriteWins: use the item with the most recent completion time
    final localTime = local.completedAt ?? local.skippedAt;
    final remoteTime = remote.completedAt ?? remote.skippedAt;

    if (remoteTime != null && localTime != null) {
      if (remoteTime.isAfter(localTime)) {
        logger.i('🔄 Item conflict resolved: using remote item');
        return remote;
      } else {
        logger.i('🔄 Item conflict resolved: using local item');
        return local;
      }
    } else if (remoteTime != null) {
      logger.i(
        '🔄 Item conflict resolved: using remote item (local has no timestamp)',
      );
      return remote;
    } else {
      logger.i(
        '🔄 Item conflict resolved: using local item (remote has no timestamp)',
      );
      return local;
    }
  }

  /// Clean up resources
  void dispose() {
    _syncTimer?.cancel();
    _syncMessageController.close();
    logger.i('🧹 Sync repository disposed');
  }
}
