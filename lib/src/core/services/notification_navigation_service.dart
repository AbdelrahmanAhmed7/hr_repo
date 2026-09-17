import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/cubit/auth_state.dart';
import '../routing/app_router.dart';
import 'push_notification_service.dart';
import 'service_locator.dart';

/// Owns every navigation triggered by a notification tap.
///
/// This is the single subscriber to [PushNotificationService.onNotificationAction].
/// It is registered once, in [initialize], which must run before `runApp()`
/// (see `main()`). Because the underlying stream is a broadcast stream that
/// drops events while it has no listeners, this early single subscription is
/// what prevents cold-start and background taps from being silently lost.
///
/// Taps are queued until two conditions hold:
///   1. the router has a mounted navigator (i.e. the first frame is rendered),
///   2. the auth/session state is confirmed as authenticated
///      (a tap is never flushed onto a screen that requires login).
/// The queued tap is then flushed exactly once via GoRouter.
class NotificationNavigationService {
  NotificationNavigationService._();
  static final NotificationNavigationService instance =
      NotificationNavigationService._();

  /// Payload keys that may carry an explicit deep-link target.
  static const List<String> _deepLinkKeys = [
    'route',
    'target',
    'screen',
    'deepLink',
  ];

  /// Routes that must never be opened from a notification tap.
  static const Set<String> _blockedRoutes = {
    '/',
    '/login',
    '/forgot-password',
    '/otp-verification',
    '/reset-password',
  };

  StreamSubscription<NotificationAction>? _actionSubscription;
  StreamSubscription<AuthState>? _authSubscription;

  String? _pendingTarget;
  String? _lastDedupeKey;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    _actionSubscription = PushNotificationService.instance.onNotificationAction
        .listen(_onNotificationAction);

    // Flush a queued tap the moment the session state becomes available
    // (covers cold start, and the tap-before-login flow).
    _authSubscription = getIt<AuthCubit>().stream.listen((_) {
      _flushQueuedNavigation();
    });

    if (kDebugMode) debugPrint('[NotificationNav] coordinator ready');
  }

  void _onNotificationAction(NotificationAction action) {
    if (kDebugMode) {
      debugPrint(
        '[NotificationNav] tap received (${action.type}) '
        'actionId=${action.actionId} messageId=${action.messageId} '
        'data=${action.data}',
      );
    }

    final target = _resolveTarget(action);
    if (target == null) {
      if (kDebugMode) debugPrint('[NotificationNav] no route resolved');
      return;
    }

    final dedupeKey = _computeDedupeKey(action);
    if (_lastDedupeKey == dedupeKey) {
      if (kDebugMode) debugPrint('[NotificationNav] duplicate tap ignored');
      return;
    }
    _lastDedupeKey = dedupeKey;
    _pendingTarget = target;

    if (kDebugMode) debugPrint('[NotificationNav] tap queued -> $target');
    _flushQueuedNavigation();
  }

  String? _resolveTarget(NotificationAction action) {
    final data = action.data;

    // 1) Explicit deep-link target carried in the payload, if any.
    for (final key in _deepLinkKeys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        final route = value.startsWith('/') ? value : '/${value.trim()}';
        if (_isAllowedRoute(route)) {
          if (kDebugMode) debugPrint('[NotificationNav] deep link -> $route');
          return route;
        }
      }
    }

    // 2) Type-aware default mapping (payload carries a `type`).
    final type = (data['type'] as String? ?? '').toLowerCase();
    if (type.startsWith('new_') || type.endsWith('_request')) {
      return '/admin/requests';
    }
    if (type.contains('attendance')) return '/attendance';
    if (type.contains('leave')) return '/leaves';

    // 3) Fallback: the notifications screen.
    return '/notifications';
  }

  bool _isAllowedRoute(String route) {
    final path = route.split('?').first;
    if (_blockedRoutes.contains(path)) return false;
    return path.startsWith('/');
  }

  String _computeDedupeKey(NotificationAction action) {
    final messageId = action.messageId;
    if (messageId != null && messageId.isNotEmpty) return 'msg:$messageId';

    final data = action.data;
    final id = data['id'];
    if (id is String && id.isNotEmpty) return 'id:$id';
    if (id is num) return 'id:$id';

    return 'data:${jsonEncode(data)}';
  }

  void _flushQueuedNavigation() {
    if (_pendingTarget == null) return;

    if (!getIt<AuthCubit>().state.isAuthenticated) {
      if (kDebugMode) {
        debugPrint('[NotificationNav] deferred: session not confirmed yet');
      }
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pendingTarget == null) return;

      final navigatorState =
          AppRouter.router.routerDelegate.navigatorKey.currentState;
      if (navigatorState == null) {
        // Router not attached yet (cold start) - retry on the next frame.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _flushQueuedNavigation();
        });
        return;
      }

      final target = _pendingTarget;
      _pendingTarget = null;
      if (kDebugMode) debugPrint('[NotificationNav] navigating -> $target');
      try {
        AppRouter.router.go(target!);
        _lastDedupeKey = null;
      } catch (e) {
        if (kDebugMode) debugPrint('[NotificationNav] navigation failed: $e');
      }
    });
  }

  void dispose() {
    _actionSubscription?.cancel();
    _authSubscription?.cancel();
    _initialized = false;
  }
}