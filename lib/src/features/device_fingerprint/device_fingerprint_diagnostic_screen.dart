import 'package:flutter/material.dart';
import 'package:mediconsult_internal/src/core/theme/app_colors.dart';
import 'package:mediconsult_internal/src/core/utils/device_fingerprint.dart';
import 'package:mediconsult_internal/src/core/utils/app_exception.dart';

class DeviceFingerprintDiagnosticScreen extends StatefulWidget {
  const DeviceFingerprintDiagnosticScreen({super.key});

  @override
  State<DeviceFingerprintDiagnosticScreen> createState() =>
      _DeviceFingerprintDiagnosticScreenState();
}

class _DeviceFingerprintDiagnosticScreenState
    extends State<DeviceFingerprintDiagnosticScreen> {
  Map<String, dynamic>? _diagnostics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final data = await DeviceFingerprintService().getDiagnostics();
      setState(() {
        _diagnostics = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = AppException.from(e).message;
        _isLoading = false;
      });
    }
  }

  Future<void> _resetFingerprint() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد'),
        content: const Text(
          'هل تريد إعادة تعيين البصمة لهذا المستخدم؟ سيتم إنشاؤها مجددًا من User ID + رقم الموبايل.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final userId = _diagnostics?['userId']?.toString();
      await DeviceFingerprintService().clearFingerprint(userId: userId);
      await _loadDiagnostics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تشخيص بصمة المستخدم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDiagnostics,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _diagnostics == null
                    ? const Center(child: Text('لا توجد بيانات'))
                    : _buildContent(),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _resetFingerprint,
          icon: const Icon(Icons.restart_alt, color: Colors.white),
          label: const Text(
            'إعادة تعيين بصمة المستخدم الحالي',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 64),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ أثناء تحميل البيانات',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDiagnostics,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final d = _diagnostics!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات بصمة المستخدم',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'الصيغة: ${d['fingerprintFormat'] ?? '{userId}_{phone}'}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          _buildCard('البصمة', d['fingerprint']),
          _buildCard('المصدر', d['source']),
          _buildCard('User ID', d['userId']),
          _buildCard('رقم الموبايل (مخفي)', d['phone']),
          _buildCard('مستخدم مسجل؟', d['isAuthenticated'] == true ? 'نعم' : 'لا'),
          _buildCard('تاريخ الإنشاء', d['generatedAt']),
        ],
      ),
    );
  }

  Widget _buildCard(String title, dynamic value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value?.toString() ?? 'غير متاح',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
