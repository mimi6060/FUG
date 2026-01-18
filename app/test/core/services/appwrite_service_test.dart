import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/appwrite.dart';
import 'package:fug_app/core/services/appwrite_service.dart';

void main() {
  group('AppwriteService', () {
    setUp(() {
      // Reset le singleton avant chaque test
      AppwriteService.reset();
    });

    tearDown(() {
      // Nettoie apres chaque test
      AppwriteService.reset();
    });

    group('Singleton Pattern', () {
      test('devrait retourner la meme instance avec factory constructor', () {
        // Arrange & Act
        final instance1 = AppwriteService();
        final instance2 = AppwriteService();

        // Assert
        expect(identical(instance1, instance2), isTrue);
      });

      test('devrait retourner la meme instance avec getter statique', () {
        // Arrange & Act
        final instance1 = AppwriteService.instance;
        final instance2 = AppwriteService.instance;

        // Assert
        expect(identical(instance1, instance2), isTrue);
      });

      test('factory et getter statique devraient retourner la meme instance', () {
        // Arrange & Act
        final factoryInstance = AppwriteService();
        final staticInstance = AppwriteService.instance;

        // Assert
        expect(identical(factoryInstance, staticInstance), isTrue);
      });

      test('reset() devrait permettre de creer une nouvelle instance', () {
        // Arrange
        final instance1 = AppwriteService();
        final hashCode1 = instance1.hashCode;

        // Act
        AppwriteService.reset();
        final instance2 = AppwriteService();

        // Assert
        expect(instance2.hashCode, isNot(equals(hashCode1)));
      });
    });

    group('Initialisation', () {
      test('devrait initialiser correctement le client', () {
        // Arrange & Act
        final service = AppwriteService();

        // Assert
        expect(service.client, isNotNull);
        expect(service.client, isA<Client>());
      });

      test('devrait initialiser tous les services Appwrite', () {
        // Arrange & Act
        final service = AppwriteService();

        // Assert
        expect(service.account, isNotNull);
        expect(service.account, isA<Account>());

        expect(service.databases, isNotNull);
        expect(service.databases, isA<Databases>());

        expect(service.realtime, isNotNull);
        expect(service.realtime, isA<Realtime>());

        expect(service.storage, isNotNull);
        expect(service.storage, isA<Storage>());
      });
    });

    group('Getters', () {
      test('client getter devrait retourner le client Appwrite', () {
        // Arrange
        final service = AppwriteService();

        // Act
        final client = service.client;

        // Assert
        expect(client, isNotNull);
        expect(client, isA<Client>());
      });

      test('account getter devrait retourner le service Account', () {
        // Arrange
        final service = AppwriteService();

        // Act
        final account = service.account;

        // Assert
        expect(account, isNotNull);
        expect(account, isA<Account>());
      });

      test('databases getter devrait retourner le service Databases', () {
        // Arrange
        final service = AppwriteService();

        // Act
        final databases = service.databases;

        // Assert
        expect(databases, isNotNull);
        expect(databases, isA<Databases>());
      });

      test('realtime getter devrait retourner le service Realtime', () {
        // Arrange
        final service = AppwriteService();

        // Act
        final realtime = service.realtime;

        // Assert
        expect(realtime, isNotNull);
        expect(realtime, isA<Realtime>());
      });

      test('storage getter devrait retourner le service Storage', () {
        // Arrange
        final service = AppwriteService();

        // Act
        final storage = service.storage;

        // Assert
        expect(storage, isNotNull);
        expect(storage, isA<Storage>());
      });

      test('les getters devraient retourner les memes instances a chaque appel', () {
        // Arrange
        final service = AppwriteService();

        // Act
        final client1 = service.client;
        final client2 = service.client;
        final account1 = service.account;
        final account2 = service.account;

        // Assert
        expect(identical(client1, client2), isTrue);
        expect(identical(account1, account2), isTrue);
      });
    });

    group('URL Generation', () {
      test('getFilePreviewUrl devrait generer une URL valide', () {
        // Arrange
        final service = AppwriteService();
        const bucketId = 'test-bucket';
        const fileId = 'test-file';

        // Act
        final url = service.getFilePreviewUrl(
          bucketId: bucketId,
          fileId: fileId,
        );

        // Assert
        expect(url, contains(bucketId));
        expect(url, contains(fileId));
        expect(url, contains('preview'));
        expect(url, contains('project='));
      });

      test('getFilePreviewUrl devrait inclure width et height si specifies', () {
        // Arrange
        final service = AppwriteService();
        const bucketId = 'test-bucket';
        const fileId = 'test-file';
        const width = 200;
        const height = 150;

        // Act
        final url = service.getFilePreviewUrl(
          bucketId: bucketId,
          fileId: fileId,
          width: width,
          height: height,
        );

        // Assert
        expect(url, contains('width=$width'));
        expect(url, contains('height=$height'));
      });

      test('getFileDownloadUrl devrait generer une URL valide', () {
        // Arrange
        final service = AppwriteService();
        const bucketId = 'test-bucket';
        const fileId = 'test-file';

        // Act
        final url = service.getFileDownloadUrl(
          bucketId: bucketId,
          fileId: fileId,
        );

        // Assert
        expect(url, contains(bucketId));
        expect(url, contains(fileId));
        expect(url, contains('download'));
        expect(url, contains('project='));
      });
    });
  });

  group('AppwriteExceptionHandler Extension', () {
    test('devrait retourner un message lisible pour code 401', () {
      // Arrange
      final exception = AppwriteException('Unauthorized', 401);

      // Act
      final message = exception.readableMessage;

      // Assert
      expect(message, contains('Session expirée'));
    });

    test('devrait retourner un message lisible pour code 403', () {
      // Arrange
      final exception = AppwriteException('Forbidden', 403);

      // Act
      final message = exception.readableMessage;

      // Assert
      expect(message, contains('permissions'));
    });

    test('devrait retourner un message lisible pour code 404', () {
      // Arrange
      final exception = AppwriteException('Not Found', 404);

      // Act
      final message = exception.readableMessage;

      // Assert
      expect(message, contains('non trouvée'));
    });

    test('devrait retourner un message lisible pour code 409', () {
      // Arrange
      final exception = AppwriteException('Conflict', 409);

      // Act
      final message = exception.readableMessage;

      // Assert
      expect(message, contains('existe déjà'));
    });

    test('devrait retourner un message lisible pour code 429', () {
      // Arrange
      final exception = AppwriteException('Too Many Requests', 429);

      // Act
      final message = exception.readableMessage;

      // Assert
      expect(message, contains('Trop de requêtes'));
    });

    test('devrait retourner un message lisible pour code 500', () {
      // Arrange
      final exception = AppwriteException('Server Error', 500);

      // Act
      final message = exception.readableMessage;

      // Assert
      expect(message, contains('Erreur serveur'));
    });

    test('devrait retourner le message original pour un code inconnu', () {
      // Arrange
      const originalMessage = 'Unknown error occurred';
      final exception = AppwriteException(originalMessage, 418);

      // Act
      final message = exception.readableMessage;

      // Assert
      expect(message, equals(originalMessage));
    });

    test('devrait retourner un message par defaut si le message est null', () {
      // Arrange
      final exception = AppwriteException(null, 999);

      // Act
      final message = exception.readableMessage;

      // Assert
      expect(message, equals('Une erreur est survenue.'));
    });
  });
}
