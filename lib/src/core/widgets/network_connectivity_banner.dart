import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class NetworkConnectivityBanner extends StatefulWidget {
  final Widget child;

  const NetworkConnectivityBanner({super.key, required this.child});

  @override
  State<NetworkConnectivityBanner> createState() =>
      _NetworkConnectivityBannerState();
}

class _NetworkConnectivityBannerState extends State<NetworkConnectivityBanner> {
  bool _isConnected = true;
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _listenToConnectionChanges();
  }

  Future<void> _checkInitialConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  void _listenToConnectionChanges() {
    Connectivity().onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });
  }

  void _hideBanner() {
    if (mounted) {
      setState(() {
        _showBanner = false;
      });
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    bool isConnected =
        result.isNotEmpty && !result.contains(ConnectivityResult.none);

    if (_isConnected != isConnected) {
      setState(() {
        _isConnected = isConnected;
        _showBanner = true;
      });

      final delay = isConnected
          ? const Duration(seconds: 3)
          : const Duration(seconds: 5);
      Future.delayed(delay, _hideBanner);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          widget.child,
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _showBanner ? 0 : -100,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _isConnected ? AppColors.success : AppColors.error,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isConnected
                            ? Icons.wifi_rounded
                            : Icons.wifi_off_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isConnected
                            ? 'تم استعادة الاتصال بالإنترنت'
                            : 'لا يوجد اتصال بالإنترنت',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_isConnected && !_showBanner)
            Positioned(
              top: MediaQuery.of(context).padding.top + 4,
              left: 8,
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
