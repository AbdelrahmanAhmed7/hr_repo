import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/admin_dashboard_response.dart';

class AdminDepartmentRequestsList extends StatelessWidget {
  final List<AdminRequest> requests;

  const AdminDepartmentRequestsList({
    super.key,
    required this.requests,
  });

  @override
  Widget build(BuildContext context) {
    final pendingRequests = requests.where((r) => r.status == 'Pending').toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'طلبات قسمك',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${pendingRequests.length} معلق',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (requests.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'لا توجد طلبات',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.take(5).length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return _buildRequestCard(context, request);
              },
            ),
          if (requests.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to all requests
                  },
                  child: Text(
                    'عرض الكل (${requests.length})',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, AdminRequest request) {
    IconData typeIcon;
    Color typeColor;
    String typeLabel;

    switch (request.type) {
      case 'Permission':
        typeIcon = Icons.exit_to_app;
        typeColor = const Color(0xFF2196F3);
        typeLabel = 'استئذان';
        break;
      case 'Leave':
        typeIcon = Icons.beach_access;
        typeColor = const Color(0xFF9C27B0);
        typeLabel = 'إجازة';
        break;
      case 'Assignment':
        typeIcon = Icons.assignment;
        typeColor = const Color(0xFFFF9800);
        typeLabel = 'مأمورية';
        break;
      default:
        typeIcon = Icons.help;
        typeColor = AppColors.textSecondary;
        typeLabel = request.type;
    }

    Color statusColor;
    String statusText;

    switch (request.status) {
      case 'Pending':
        statusColor = AppColors.warning;
        statusText = 'معلق';
        break;
      case 'Approved':
        statusColor = AppColors.success;
        statusText = 'مقبول';
        break;
      case 'Rejected':
        statusColor = AppColors.error;
        statusText = 'مرفوض';
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = request.status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      typeLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'الموظف: ${request.userId != null ? request.userId!.substring(0, 8) : 'غير معروف'}...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                if (request.reason != null && request.reason!.isNotEmpty)
                  Text(
                    request.reason!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
