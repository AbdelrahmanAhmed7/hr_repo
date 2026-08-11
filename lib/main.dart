import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mediconsult_internal/firebase_options.dart';
import 'package:mediconsult_internal/src/core/services/push_notification_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'src/core/services/service_locator.dart';
import 'src/core/routing/app_router.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/theme/app_colors.dart';
import 'src/core/network/dio_client.dart';
import 'src/shared/components/custom_toast.dart';
import 'src/core/widgets/network_connectivity_banner.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://0416def9efce235ecc836209ad62434c@o4511145037594624.ingest.us.sentry.io/4511145046769664';
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();

      await setupServiceLocator();

      // Note: DeviceFingerprintService no longer requires startup init.
      // Fingerprint is generated lazily from authenticated User ID + Phone on first use.

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await PushNotificationService.instance.initialize();

      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: AppColors.backgroundSecondary,
          systemNavigationBarIconBrightness: Brightness.dark,
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      );

      runApp(MainApp());
    },
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  StreamSubscription<AuthError>? _authErrorSubscription;
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();

    _authErrorSubscription = DioClient.authErrorStream.listen((error) {
      if (!mounted) return;

      final context =
          AppRouter.router.routerDelegate.navigatorKey.currentContext;
      if (context == null || !context.mounted) {
        return;
      }

      if (error == AuthError.unauthorized) {
        AppRouter.router.go('/login');
      } else if (error == AuthError.forbidden) {
        CustomToast.showError('ليس لديك صلاحية للوصول إلى هذا المورد');
      }
    });
  }

  @override
  void dispose() {
    _authErrorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MediConsult Internal',
      theme: AppTheme.lightTheme,

      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      routerConfig: AppRouter.router,
      builder: (context, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            if (AppRouter.router.canPop()) {
              AppRouter.router.pop();
              return;
            }

            final now = DateTime.now();
            if (_lastBackPress == null ||
                now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
              _lastBackPress = now;
              final scaffoldContext =
                  AppRouter.router.routerDelegate.navigatorKey.currentContext;
              if (scaffoldContext != null && scaffoldContext.mounted) {
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  const SnackBar(
                    content: Text('اضغط مرة أخرى للخروج'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            } else {
              SystemNavigator.pop();
            }
          },
          child: SafeArea(
            top: false,
            child: NetworkConnectivityBanner(child: child ?? const SizedBox()),
          ),
        );
      },
    );
  }
}