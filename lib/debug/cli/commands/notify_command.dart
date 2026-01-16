import '../../../domain/services/notification_service.dart';
import '../cli_runner.dart';

/// CLI command for notification testing.
///
/// Provides subcommands for testing notification delivery.
/// All output is JSON formatted for AI agent parsing.
class NotifyCommand extends JsonCommand {
  final NotificationService notificationService;

  @override
  final String name = 'notify';

  @override
  final String description = 'Manage and test notifications';

  NotifyCommand(this.notificationService) {
    addSubcommand(_TestCommand(notificationService));
    addSubcommand(_GetTokenCommand(notificationService));
    addSubcommand(_RequestPermissionCommand(notificationService));
  }

  @override
  Future<Map<String, dynamic>> execute() async {
    // This is called when no subcommand is provided
    throw ArgumentError(
      'A subcommand is required: test, get-token, or request-permission',
    );
  }
}

/// Sends a test notification.
class _TestCommand extends JsonCommand {
  final NotificationService notificationService;

  @override
  final String name = 'test';

  @override
  final String description = 'Send a test notification';

  _TestCommand(this.notificationService) {
    argParser.addOption(
      'message',
      abbr: 'm',
      help: 'Test message to send',
      defaultsTo: 'This is a test notification from HexBuzz',
    );
    argParser.addOption(
      'title',
      abbr: 't',
      help: 'Notification title',
      defaultsTo: 'Test Notification',
    );
  }

  @override
  Future<Map<String, dynamic>> execute() async {
    final message = argResults!['message'] as String;
    final title = argResults!['title'] as String;

    try {
      // Note: This is a simplified implementation.
      // In a real scenario, you would need to send via FCM Admin SDK
      // or use the notification service's local notification capabilities.

      // For CLI testing, we'll just verify the service is initialized
      await notificationService.initialize();
      final token = await notificationService.getDeviceToken();

      if (token == null) {
        return {
          'success': false,
          'error': 'No device token available',
          'message': 'Cannot send notification without device token',
        };
      }

      return {
        'success': true,
        'message': 'Test notification would be sent',
        'notification': {'title': title, 'body': message, 'deviceToken': token},
        'note':
            'CLI cannot send actual notifications. Use Cloud Functions or FCM console.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to send test notification',
      };
    }
  }
}

/// Gets the current device FCM token.
class _GetTokenCommand extends JsonCommand {
  final NotificationService notificationService;

  @override
  final String name = 'get-token';

  @override
  final String description = 'Get current device FCM token';

  _GetTokenCommand(this.notificationService);

  @override
  Future<Map<String, dynamic>> execute() async {
    try {
      await notificationService.initialize();
      final token = await notificationService.getDeviceToken();

      if (token == null) {
        return {
          'success': true,
          'hasToken': false,
          'message': 'No device token available',
        };
      }

      return {'success': true, 'hasToken': true, 'token': token};
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to get device token',
      };
    }
  }
}

/// Requests notification permission.
class _RequestPermissionCommand extends JsonCommand {
  final NotificationService notificationService;

  @override
  final String name = 'request-permission';

  @override
  final String description = 'Request notification permission';

  _RequestPermissionCommand(this.notificationService);

  @override
  Future<Map<String, dynamic>> execute() async {
    try {
      await notificationService.initialize();
      final granted = await notificationService.requestPermission();

      return {
        'success': true,
        'granted': granted,
        'message': granted
            ? 'Notification permission granted'
            : 'Notification permission denied',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to request notification permission',
      };
    }
  }
}
