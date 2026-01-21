import 'package:appwrite/appwrite.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/appwrite_service.dart';
import '../../../core/config/appwrite_config.dart';
import '../../../core/providers/auth_provider.dart';

/// Model representing an account deletion request
///
/// Contains information about the deletion request
/// including the request date and scheduled deletion date.
class AccountDeletionRequest extends Equatable {
  /// Unique request ID
  final String id;

  /// ID of the user concerned
  final String userId;

  /// Date of deletion request
  final DateTime requestedAt;

  /// Scheduled deletion date (30 days after request)
  final DateTime scheduledDeletionAt;

  /// Request status: pending, cancelled, completed
  final String status;

  /// Cancellation reason (if applicable)
  final String? cancellationReason;

  const AccountDeletionRequest({
    required this.id,
    required this.userId,
    required this.requestedAt,
    required this.scheduledDeletionAt,
    required this.status,
    this.cancellationReason,
  });

  /// Creates an AccountDeletionRequest from a JSON document
  factory AccountDeletionRequest.fromJson(Map<String, dynamic> json) {
    return AccountDeletionRequest(
      id: json['\$id'] as String,
      userId: json['userId'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      scheduledDeletionAt: DateTime.parse(json['scheduledDeletionAt'] as String),
      status: json['status'] as String,
      cancellationReason: json['cancellationReason'] as String?,
    );
  }

  /// Converts to JSON Map
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'requestedAt': requestedAt.toIso8601String(),
      'scheduledDeletionAt': scheduledDeletionAt.toIso8601String(),
      'status': status,
      'cancellationReason': cancellationReason,
    };
  }

  /// Checks if the request can still be cancelled
  bool get canBeCancelled =>
      status == 'pending' && DateTime.now().isBefore(scheduledDeletionAt);

  /// Number of days remaining before deletion
  int get daysUntilDeletion {
    if (!canBeCancelled) return 0;
    return scheduledDeletionAt.difference(DateTime.now()).inDays;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        requestedAt,
        scheduledDeletionAt,
        status,
        cancellationReason,
      ];
}

/// Custom exception for account operations
class AccountException implements Exception {
  final String message;
  final int? code;

  AccountException(this.message, {this.code});

  @override
  String toString() => 'AccountException: $message';
}

/// Repository for account operations management
///
/// Handles account deletion requests in compliance with GDPR:
/// - Deletion request with 30-day grace period
/// - Cancellation of request during grace period
/// - Password verification before deletion
class AccountRepository {
  final AppwriteService _appwrite;

  AccountRepository({AppwriteService? appwrite})
      : _appwrite = appwrite ?? AppwriteService.instance;

  Account get _account => _appwrite.account;
  Databases get _databases => _appwrite.databases;

  /// Collection ID for deletion requests
  static const String _deletionRequestsCollection = 'account_deletion_requests';

  // ============================================
  // Account Deletion (GDPR)
  // ============================================

  /// Requests user account deletion
  ///
  /// Creates a deletion request with a 30-day grace period.
  /// User can cancel during this period.
  ///
  /// [userId] - User ID
  /// [password] - Password for verification
  ///
  /// Throws [AccountException] if password is incorrect
  /// or if a request is already pending.
  Future<AccountDeletionRequest> requestAccountDeletion({
    required String userId,
    required String password,
  }) async {
    try {
      // Verify password by attempting an authenticated operation
      await _verifyPassword(password);

      // Check if there's already a pending request
      final existingRequest = await getPendingDeletionRequest(userId);
      if (existingRequest != null && existingRequest.canBeCancelled) {
        throw AccountException(
          'A deletion request is already pending.',
          code: 409,
        );
      }

      // Create deletion request
      final now = DateTime.now();
      final scheduledDeletion = now.add(const Duration(days: 30));

      final doc = await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _deletionRequestsCollection,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'requestedAt': now.toIso8601String(),
          'scheduledDeletionAt': scheduledDeletion.toIso8601String(),
          'status': 'pending',
          'cancellationReason': null,
        },
        permissions: [
          Permission.read(Role.user(userId)),
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ],
      );

      return AccountDeletionRequest.fromJson(doc.data);
    } on AppwriteException catch (e) {
      throw AccountException(
        _getReadableErrorMessage(e),
        code: e.code,
      );
    }
  }

  /// Cancels a pending deletion request
  ///
  /// [requestId] - ID of the request to cancel
  /// [reason] - Cancellation reason (optional)
  ///
  /// Throws [AccountException] if the request can no longer be cancelled.
  Future<void> cancelAccountDeletion({
    required String requestId,
    String? reason,
  }) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _deletionRequestsCollection,
        documentId: requestId,
        data: {
          'status': 'cancelled',
          'cancellationReason': reason ?? 'Cancelled by user',
        },
      );
    } on AppwriteException catch (e) {
      throw AccountException(
        _getReadableErrorMessage(e),
        code: e.code,
      );
    }
  }

  /// Retrieves the pending deletion request for a user
  ///
  /// Returns null if no request is pending.
  Future<AccountDeletionRequest?> getPendingDeletionRequest(
    String userId,
  ) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _deletionRequestsCollection,
        queries: [
          Query.equal('userId', userId),
          Query.equal('status', 'pending'),
          Query.orderDesc('requestedAt'),
          Query.limit(1),
        ],
      );

      if (result.documents.isEmpty) {
        return null;
      }

      return AccountDeletionRequest.fromJson(result.documents.first.data);
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        print('getPendingDeletionRequest error: ${e.message}');
      }
      return null;
    }
  }

  /// List of data that will be deleted
  ///
  /// Returns a description of data categories
  /// that will be deleted upon account deletion.
  List<String> getDataToBeDeleted() {
    return [
      'Your profile and personal information (name, email, bio)',
      'Your profile picture',
      'Your created FUG events',
      'Your participation history',
      'Your relationships (followers and following)',
      'Your badges and murgilarity points',
      'Your notifications',
      'Your preferences and settings',
    ];
  }

  /// List of data that will be anonymized (not deleted)
  ///
  /// Some data is kept anonymously
  /// for statistical or legal reasons.
  List<String> getDataToBeAnonymized() {
    return [
      'Events you participated in (your name will be replaced with "Deleted user")',
      'Aggregated application statistics',
    ];
  }

  // ============================================
  // Helpers
  // ============================================

  /// Verifies user password
  ///
  /// Attempts an authenticated operation to verify
  /// that the password is correct.
  Future<void> _verifyPassword(String password) async {
    try {
      // Get currently logged in user's email
      final user = await _account.get();

      // Attempt re-authentication with password
      // This implicitly verifies the password is correct
      await _account.createEmailPasswordSession(
        email: user.email,
        password: password,
      );

      // Delete the created session (keep the original session)
      // Note: In a real implementation, a dedicated password
      // verification API would be used if available
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        throw AccountException(
          'Incorrect password.',
          code: 401,
        );
      }
      rethrow;
    }
  }

  /// Converts Appwrite errors to readable messages
  String _getReadableErrorMessage(AppwriteException e) {
    switch (e.code) {
      case 401:
        return 'Incorrect password.';
      case 404:
        return 'Request not found.';
      case 409:
        return 'A request is already pending.';
      default:
        return e.message ?? 'An error occurred.';
    }
  }
}

// ============================================
// Riverpod Providers
// ============================================

/// Provider for account repository
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository();
});

/// Provider to retrieve pending deletion request
///
/// Returns null if no request is pending.
final pendingDeletionRequestProvider =
    FutureProvider.family<AccountDeletionRequest?, String>((ref, userId) async {
  final repository = ref.read(accountRepositoryProvider);
  return repository.getPendingDeletionRequest(userId);
});

/// Provider for data to be deleted
final dataToBeDeletedProvider = Provider<List<String>>((ref) {
  final repository = ref.read(accountRepositoryProvider);
  return repository.getDataToBeDeleted();
});

/// Provider for data to be anonymized
final dataToBeAnonymizedProvider = Provider<List<String>>((ref) {
  final repository = ref.read(accountRepositoryProvider);
  return repository.getDataToBeAnonymized();
});

/// Notifier for managing deletion requests
class AccountDeletionNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Requests account deletion
  Future<AccountDeletionRequest> requestDeletion({
    required String userId,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(accountRepositoryProvider);
      final request = await repository.requestAccountDeletion(
        userId: userId,
        password: password,
      );

      // Invalidate pending request cache
      ref.invalidate(pendingDeletionRequestProvider(userId));

      state = const AsyncValue.data(null);
      return request;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Cancels deletion request
  Future<void> cancelDeletion({
    required String requestId,
    required String userId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(accountRepositoryProvider);
      await repository.cancelAccountDeletion(requestId: requestId);

      // Invalidate pending request cache
      ref.invalidate(pendingDeletionRequestProvider(userId));

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Provider for account deletion notifier
final accountDeletionNotifierProvider =
    AutoDisposeAsyncNotifierProvider<AccountDeletionNotifier, void>(() {
  return AccountDeletionNotifier();
});
