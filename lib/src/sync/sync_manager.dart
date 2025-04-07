import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../storage/database_service.dart';
import '../models/article.dart';

/// Manages offline synchronization and conflict resolution
class SyncManager {
  final DatabaseService _db;
  final _connectivity = Connectivity();
  Timer? _syncTimer;
  bool _isSyncing = false;
  
  final _syncController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncController.stream;

  SyncManager(this._db) {
    _initializeSync();
  }

  /// Initializes sync monitoring
  void _initializeSync() {
    // Monitor connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        syncPendingOperations();
      }
    });

    // Schedule periodic sync attempts
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      syncPendingOperations();
    });
  }

  /// Syncs pending operations when online
  Future<void> syncPendingOperations() async {
    if (_isSyncing) return;
    _isSyncing = true;
    
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _syncController.add(SyncStatus(
          isOnline: false,
          message: 'Offline - sync pending',
          pendingOperations: await _getPendingOperationCount(),
        ));
        return;
      }

      _syncController.add(SyncStatus(
        isOnline: true,
        message: 'Syncing...',
        pendingOperations: await _getPendingOperationCount(),
      ));

      // Process pending operations
      final operations = await _db.getPendingOperations();
      for (final op in operations) {
        if (await _processOperation(op)) {
          await _db.markOperationProcessed(op.id);
        }
      }

      _syncController.add(SyncStatus(
        isOnline: true,
        message: 'Sync complete',
        pendingOperations: await _getPendingOperationCount(),
      ));
    } catch (e) {
      _syncController.add(SyncStatus(
        isOnline: true,
        message: 'Sync failed: $e',
        pendingOperations: await _getPendingOperationCount(),
        error: e.toString(),
      ));
    } finally {
      _isSyncing = false;
    }
  }

  /// Processes a single offline operation
  Future<bool> _processOperation(OfflineQueueData operation) async {
    try {
      switch (operation.operation) {
        case 'share_article':
          // Process share operation
          return await _processShareOperation(operation);
          
        case 'update_article':
          // Process article update
          return await _processArticleUpdate(operation);
          
        case 'delete_article':
          // Process article deletion
          return await _processArticleDeletion(operation);
          
        default:
          print('Unknown operation type: ${operation.operation}');
          return false;
      }
    } catch (e) {
      print('Failed to process operation ${operation.id}: $e');
      return false;
    }
  }

  /// Processes a share operation
  Future<bool> _processShareOperation(OfflineQueueData operation) async {
    try {
      final payload = operation.payload;
      // TODO: Implement actual sharing logic
      return true;
    } catch (e) {
      print('Share operation failed: $e');
      return false;
    }
  }

  /// Processes an article update
  Future<bool> _processArticleUpdate(OfflineQueueData operation) async {
    try {
      final payload = operation.payload;
      // TODO: Implement article update sync
      return true;
    } catch (e) {
      print('Article update failed: $e');
      return false;
    }
  }

  /// Processes an article deletion
  Future<bool> _processArticleDeletion(OfflineQueueData operation) async {
    try {
      final payload = operation.payload;
      // TODO: Implement article deletion sync
      return true;
    } catch (e) {
      print('Article deletion failed: $e');
      return false;
    }
  }

  /// Gets the count of pending operations
  Future<int> _getPendingOperationCount() async {
    final operations = await _db.getPendingOperations();
    return operations.length;
  }

  /// Queues an operation for offline processing
  Future<void> queueOperation(String operation, Map<String, dynamic> payload) async {
    await _db.queueOfflineOperation(operation, payload);
    syncPendingOperations();
  }

  /// Forces an immediate sync attempt
  Future<void> forceSyncNow() async {
    await syncPendingOperations();
  }

  void dispose() {
    _syncTimer?.cancel();
    _syncController.close();
  }
}

/// Represents the current sync status
class SyncStatus {
  final bool isOnline;
  final String message;
  final int pendingOperations;
  final String? error;

  SyncStatus({
    required this.isOnline,
    required this.message,
    required this.pendingOperations,
    this.error,
  });
}

/// Represents a conflict between local and remote changes
class SyncConflict {
  final String articleId;
  final Article localVersion;
  final Article remoteVersion;
  final DateTime conflictTime;

  SyncConflict({
    required this.articleId,
    required this.localVersion,
    required this.remoteVersion,
    required this.conflictTime,
  });

  Map<String, dynamic> toJson() => {
    'articleId': articleId,
    'localVersion': localVersion.toJson(),
    'remoteVersion': remoteVersion.toJson(),
    'conflictTime': conflictTime.toIso8601String(),
  };
}
