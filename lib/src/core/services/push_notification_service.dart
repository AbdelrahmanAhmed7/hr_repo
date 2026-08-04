import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/dio_client.dart';
import '../../features/auth/services/auth_storage_service.dart';
import '../utils/device_fingerprint.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) debugPrint('Background message: ${message.messageId}');
  await PushNotificationService.instance.setupFlutterNotifications();
  await PushNotificationService.instance.showNotification(message);
}

/// Production-ready notification service with comprehensive error handling
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isFlutterLocalNotificationsInitialized = false;
  bool _isInitialized = false;

  static const _cachedFcmTokenKey = 'cached_fcm_token';

  /// Stream for notification actions (tap/interaction)
  final _notificationActionController =
      StreamController<NotificationAction>.broadcast();
  Stream<NotificationAction> get onNotificationAction =>
      _notificationActionController.stream;

  /// Stream for FCM token updates
  final _tokenController = StreamController<String>.broadcast();
  Stream<String> get onTokenRefresh => _tokenController.stream;

  String? _currentToken;
  String? get currentToken => _currentToken;

  /// Initialize notification service
  /// Call this in main() before runApp()
  Future<bool> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) debugPrint('PushNotificationService already initialized');
      return true;
    }

    try {
      if (kDebugMode) debugPrint('Initializing PushNotificationService...');

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Request permissions
      final permissionGranted = await _requestPermission();
      if (!permissionGranted) {
        if (kDebugMode) debugPrint('Notification permission denied');
        return false;
      }

      // Setup local notifications
      await setupFlutterNotifications();

      // Setup message handlers
      await _setupMessageHandlers();

      // Get and listen to FCM token
      await _setupTokenHandling();

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('PushNotificationService initialized successfully');
      }
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error initializing PushNotificationService: $e');
      }
      if (kDebugMode) debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      final isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (kDebugMode) {
        debugPrint('Permission status: ${settings.authorizationStatus}');
      }
      return isAuthorized;
    } catch (e) {
      if (kDebugMode) debugPrint('Error requesting permission: $e');
      return false;
    }
  }

  /// Setup flutter local notifications
  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) return;

    try {
      // Android notification channel
      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      // Optional extra channels for future use (won't affect current behavior)
      const promoChannel = AndroidNotificationChannel(
        'promotions',
        'Promotions',
        description: 'Offers and campaigns',
        importance: Importance.high,
      );
      const updatesChannel = AndroidNotificationChannel(
        'updates',
        'Updates',
        description: 'App and policy updates',
        importance: Importance.defaultImportance,
      );

      // Create Android notification channel
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      // Create extra channels (safe no-op if already exists)
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(promoChannel);
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(updatesChannel);

      // Initialize settings for both platforms
      final initializationSettings = InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: <DarwinNotificationCategory>[
            DarwinNotificationCategory(
              'MC_GENERAL',
              actions: <DarwinNotificationAction>[
                DarwinNotificationAction.plain('view', 'View'),
                DarwinNotificationAction.plain('mark_read', 'Mark as read'),
              ],
            ),
          ],
        ),
      );

      // Initialize plugin
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
        onDidReceiveBackgroundNotificationResponse: _handleNotificationTap,
      );

      _isFlutterLocalNotificationsInitialized = true;
      if (kDebugMode) debugPrint('Local notifications initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('Error setting up local notifications: $e');
      rethrow;
    }
  }

  /// Display notification
  Future<void> showNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) {
        if (kDebugMode) debugPrint('Message has no notification payload');
        return;
      }

      // Check platform-specific notification data
      final android = message.notification?.android;
      final data = message.data;

      // Support multiple image field names
      final imageUrl =
          data['image'] as String? ??
          data['imageUrl'] as String? ??
          data['picture'] as String? ??
          android?.imageUrl;

      final largeIconUrl = data['largeIcon'] as String? ?? imageUrl;
      final groupKey = data['group'] as String? ?? 'mc_general_group';
      final colorHex = data['color'] as String?;
      final channelId = data['channel'] as String? ?? 'high_importance_channel';
      final channelName = channelId == 'promotions'
          ? 'Promotions'
          : channelId == 'updates'
          ? 'Updates'
          : 'High Importance Notifications';

      // Auto-enable big picture if image URL exists
      final forceBigPicture =
          (data['forceBigPicture'] == 'true') ||
          (imageUrl != null && imageUrl.isNotEmpty);

      if (kDebugMode) debugPrint('Notification Image URL: $imageUrl');
      if (kDebugMode) debugPrint('Force Big Picture: $forceBigPicture');

      // Load large icon once
      ByteArrayAndroidBitmap? largeIconBitmap;
      if (largeIconUrl != null && largeIconUrl.isNotEmpty) {
        try {
          largeIconBitmap = ByteArrayAndroidBitmap(
            await _downloadBytes(largeIconUrl),
          );
          if (kDebugMode) debugPrint('Large icon loaded successfully');
        } catch (e) {
          if (kDebugMode) debugPrint('Failed to load large icon: $e');
        }
      }

      // Prepare notification details
      StyleInformation styleInfo;
      if (forceBigPicture && imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final bigPicture = ByteArrayAndroidBitmap(
            await _downloadBytes(imageUrl),
          );
          styleInfo = BigPictureStyleInformation(
            bigPicture,
            largeIcon: largeIconBitmap,
            contentTitle: notification.title,
            summaryText: notification.body,
            hideExpandedLargeIcon: false,
          );
          if (kDebugMode) debugPrint('Big picture style loaded successfully');
        } catch (e) {
          if (kDebugMode) debugPrint('Failed to load big picture: $e');
          styleInfo = BigTextStyleInformation(
            notification.body ?? '',
            contentTitle: notification.title,
            summaryText: data['summary'],
          );
        }
      } else {
        styleInfo = BigTextStyleInformation(
          notification.body ?? '',
          contentTitle: notification.title,
          summaryText: data['summary'],
        );
      }

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: 'This channel is used for notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            styleInformation: styleInfo,
            showWhen: true,
            ticker: notification.title,
            largeIcon: largeIconBitmap,
            color: colorHex != null ? _parseColor(colorHex) : null,
            groupKey: groupKey,
            actions: <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'view',
                'View',
                showsUserInterface: true,
                cancelNotification: true,
              ),
              const AndroidNotificationAction(
                'mark_read',
                'Mark as read',
                showsUserInterface: false,
                cancelNotification: true,
              ),
            ],
          );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // FIX 2: Use unique ID based on timestamp to avoid overwriting notifications
      final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

      // Show notification
      await _localNotifications.show(
        notificationId,
        notification.title,
        notification.body,
        notificationDetails,
        payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
      );

      if (kDebugMode) debugPrint('Notification shown: ${notification.title}');
    } catch (e) {
      if (kDebugMode) debugPrint('Error showing notification: $e');
    }
  }

  // ---- Helpers for rich notifications (Android) ----

  // FIX 1: Added connection timeout + close timeout + client cleanup
  Future<Uint8List> _downloadBytes(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close().timeout(const Duration(seconds: 10));
      return consolidateHttpClientResponseBytes(res);
    } on TimeoutException {
      if (kDebugMode) debugPrint('Image download timed out: $url');
      rethrow;
    } finally {
      client.close();
    }
  }

  Color _parseColor(String hex) {
    final normalized = hex.replaceFirst('#', '');
    final value = int.parse(normalized, radix: 16);
    return Color(normalized.length == 6 ? (0xFF000000 | value) : value);
  }

  /// Setup message handlers for different app states
  Future<void> _setupMessageHandlers() async {
    try {
      // Foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        if (kDebugMode) debugPrint('Foreground message: ${message.messageId}');
        showNotification(message);
      });

      // Background messages (app in background, user taps notification)
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (kDebugMode) {
          debugPrint('Notification opened (background): ${message.messageId}');
        }
        _handleMessageOpen(message);
      });

      // Terminated state (app was closed, user taps notification)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          debugPrint(
            'App opened from notification: ${initialMessage.messageId}',
          );
        }
        // Delay to ensure app is fully initialized
        Future.delayed(const Duration(seconds: 1), () {
          _handleMessageOpen(initialMessage);
        });
      }

      if (kDebugMode) debugPrint('Message handlers setup complete');
    } catch (e) {
      if (kDebugMode) debugPrint('Error setting up message handlers: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final storedToken = await AuthStorageService.getToken();
      if (storedToken == null || storedToken.isEmpty) {
        if (kDebugMode) {
          debugPrint('Skipping FCM token sync: user not authenticated');
        }
        return;
      }

      final deviceInfo = await DeviceFingerprintService().getFingerprint();

      final dio = DioClient().dio;
      await dio.post(
        '/api/Auth/fcm-token',
        data: {'token': token, 'deviceInfo': deviceInfo},
      );

      if (kDebugMode) debugPrint('FCM token synced with backend');
    } catch (e) {
      if (kDebugMode) debugPrint('Error syncing FCM token with backend: $e');
    }
  }

  /// Setup FCM token handling
  Future<void> _setupTokenHandling() async {
    try {
      // Get initial token
      _currentToken = await _messaging.getToken();
      if (_currentToken != null) {
        if (kDebugMode) debugPrint('FCM Token: $_currentToken');
        _tokenController.add(_currentToken!);

        // FIX 3: Only send token to backend if it changed
        final prefs = await SharedPreferences.getInstance();
        final cachedToken = prefs.getString(_cachedFcmTokenKey);
        if (cachedToken != _currentToken) {
          await _sendTokenToBackend(_currentToken!);
          await prefs.setString(_cachedFcmTokenKey, _currentToken!);
          if (kDebugMode) debugPrint('FCM token changed — synced with backend');
        } else {
          if (kDebugMode) {
            debugPrint('FCM token unchanged — skipping backend sync');
          }
        }
      }

      // Listen to token refresh
      _messaging.onTokenRefresh.listen((token) async {
        if (kDebugMode) debugPrint('Token refreshed: $token');
        _currentToken = token;
        _tokenController.add(token);

        // Always sync on refresh since Firebase only fires this when token actually changes
        await _sendTokenToBackend(token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cachedFcmTokenKey, token);
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error setting up token handling: $e');
    }
  }

  Future<void> syncTokenWithBackend() async {
    if (_currentToken == null || _currentToken!.isEmpty) return;
    await _sendTokenToBackend(_currentToken!);
  }

  /// Handle notification tap
  @pragma('vm:entry-point')
  static void _handleNotificationTap(NotificationResponse response) {
    if (kDebugMode) debugPrint('Notification tapped: ${response.id}');

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        instance._notificationActionController.add(
          NotificationAction(
            type: NotificationActionType.tap,
            data: data,
            actionId: response.actionId,
          ),
        );
      } catch (e) {
        if (kDebugMode) debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Handle message open (from FCM directly)
  void _handleMessageOpen(RemoteMessage message) {
    _notificationActionController.add(
      NotificationAction(
        type: NotificationActionType.open,
        data: message.data,
        messageId: message.messageId,
      ),
    );
  }

  /// Subscribe to topic
  Future<bool> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) debugPrint('Subscribed to topic: $topic');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error subscribing to topic: $e');
      return false;
    }
  }

  /// Unsubscribe from topic
  Future<bool> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      // FIX 4: Was missing debugPrint call
      if (kDebugMode) debugPrint('Unsubscribed from topic: $topic');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error unsubscribing from topic: $e');
      return false;
    }
  }

  /// Delete FCM token
  Future<bool> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _currentToken = null;
      // Clear cached token on delete
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedFcmTokenKey);
      if (kDebugMode) debugPrint('FCM token deleted');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting token: $e');
      return false;
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      if (kDebugMode) debugPrint('All notifications cancelled');
    } catch (e) {
      if (kDebugMode) debugPrint('Error cancelling notifications: $e');
    }
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      if (kDebugMode) debugPrint('Notification $id cancelled');
    } catch (e) {
      if (kDebugMode) debugPrint('Error cancelling notification: $e');
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _localNotifications.pendingNotificationRequests();
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting pending notifications: $e');
      return [];
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isIOS) {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } else if (Platform.isAndroid) {
      final plugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await plugin?.areNotificationsEnabled() ?? false;
    }
    return false;
  }

  /// Dispose resources
  void dispose() {
    _notificationActionController.close();
    _tokenController.close();
    _isInitialized = false;
    if (kDebugMode) debugPrint('PushNotificationService disposed');
  }
}

/// Notification action data model
class NotificationAction {
  final NotificationActionType type;
  final Map<String, dynamic> data;
  final String? actionId;
  final String? messageId;

  NotificationAction({
    required this.type,
    required this.data,
    this.actionId,
    this.messageId,
  });

  @override
  String toString() {
    return 'NotificationAction(type: $type, data: $data, actionId: $actionId, messageId: $messageId)';
  }
}

/// Notification action types
enum NotificationActionType {
  tap, // User tapped on notification
  open, // App opened from notification
}
