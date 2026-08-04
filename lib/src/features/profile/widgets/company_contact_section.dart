import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

class CompanyContactSection extends StatelessWidget {
  final String? email;
  final String? phone;
  final String? companyEmail;
  final String? companyPhone;
  final String? companyOath;

  const CompanyContactSection({
    super.key,
    this.email,
    this.phone,
    this.companyEmail,
    this.companyPhone,
    this.companyOath,
  });

  bool get _hasData {
    final hasPersonalEmail = email != null && email!.trim().isNotEmpty && email != 'null';
    final hasPersonalPhone = phone != null && phone!.trim().isNotEmpty && phone != 'null';
    final hasCompanyEmail = companyEmail != null && companyEmail!.trim().isNotEmpty && companyEmail != '0' && companyEmail != 'null';
    final hasCompanyPhone = companyPhone != null && companyPhone!.trim().isNotEmpty && companyPhone != '0' && companyPhone != 'null';
    final hasOath = companyOath != null && companyOath!.trim().isNotEmpty && companyOath != 'null';
    return hasPersonalEmail || hasPersonalPhone || hasCompanyEmail || hasCompanyPhone || hasOath;
  }

  Future<void> _launchEmail(String emailAddress) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasData) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'معلومات التواصل',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Personal Contact Info
                if (email != null && email!.trim().isNotEmpty && email != 'null') ...[
                  _buildContactRow(
                    context,
                    icon: Icons.email_outlined,
                    label: 'البريد الإلكتروني الشخصي',
                    value: email!,
                    onTap: () => _launchEmail(email!),
                  ),
                  const Divider(height: 32),
                ],
                if (phone != null && phone!.trim().isNotEmpty && phone != 'null') ...[
                  _buildContactRow(
                    context,
                    icon: Icons.phone_android_outlined,
                    label: 'رقم الهاتف الشخصي',
                    value: phone!,
                    onTap: () => _launchPhone(phone!),
                  ),
                  if (_hasCompanyData) const Divider(height: 32),
                ],

                // Company Contact Info
                if (companyEmail != null && companyEmail!.trim().isNotEmpty && companyEmail != '0' && companyEmail != 'null') ...[
                  _buildContactRow(
                    context,
                    icon: Icons.business_outlined,
                    label: 'البريد الإلكتروني للشركة',
                    value: companyEmail!,
                    onTap: () => _launchEmail(companyEmail!),
                  ),
                  const Divider(height: 32),
                ],
                if (companyPhone != null && companyPhone!.trim().isNotEmpty && companyPhone != '0' && companyPhone != 'null') ...[
                  _buildContactRow(
                    context,
                    icon: Icons.phone_outlined,
                    label: 'هاتف الشركة',
                    value: companyPhone!,
                    onTap: () => _launchPhone(companyPhone!),
                  ),
                  if (companyOath != null && companyOath!.trim().isNotEmpty && companyOath != 'null') const Divider(height: 32),
                ],
                if (companyOath != null && companyOath!.trim().isNotEmpty && companyOath != 'null') ...[
                  _buildContactRow(
                    context,
                    icon: Icons.support_agent_outlined,
                    label: 'الدعم الفني',
                    value: companyOath!,
                    onTap: null,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  bool get _hasCompanyData {
    return (companyEmail != null && companyEmail!.trim().isNotEmpty && companyEmail != '0' && companyEmail != 'null') ||
           (companyPhone != null && companyPhone!.trim().isNotEmpty && companyPhone != '0' && companyPhone != 'null') ||
           (companyOath != null && companyOath!.trim().isNotEmpty && companyOath != 'null');
  }

  Widget _buildContactRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textTertiary,
            ),
        ],
      ),
    );
  }
}
