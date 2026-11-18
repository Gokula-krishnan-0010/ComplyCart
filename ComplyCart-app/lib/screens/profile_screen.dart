import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_animated_header.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const PremiumAnimatedHeader(
        title: 'Profile',
        isRoot: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      _buildStatsRow(),
                      const SizedBox(height: AppSpacing.xxxl),
                      _buildSettingsList(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 120, bottom: AppSpacing.xxl),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.xxl)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded, size: 60, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Admin User',
            style: AppTextStyles.h2.copyWith(color: Colors.white),
          ),
          Text(
            'admin@complycart.ai • Senior Auditor',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      transform: Matrix4.translationValues(0, -40, 0),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.medium,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statBlock(Icons.qr_code_scanner_rounded, 'Scans', '248'),
          _verticalDivider(),
          _statBlock(Icons.assignment_turned_in_outlined, 'Reports', '182'),
          _verticalDivider(),
          _statBlock(Icons.storefront_rounded, 'Reviewed', '45'),
        ],
      ),
    );
  }

  Widget _statBlock(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTextStyles.h3),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: AppColors.surfaceVariant,
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account Settings', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.md),
        _buildSettingsItem(Icons.person_outline_rounded, 'Account Information'),
        _buildSettingsItem(Icons.notifications_none_rounded, 'Notification Preferences'),
        _buildSettingsItem(Icons.palette_outlined, 'App Theme'),
        _buildSettingsItem(Icons.help_outline_rounded, 'Help & Support'),
        const SizedBox(height: AppSpacing.xl),
        _buildSettingsItem(
          Icons.logout_rounded, 
          'Log Out', 
          isDestructive: true,
          onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthScreen()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, {bool isDestructive = false, VoidCallback? onTap}) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    final iconColor = isDestructive ? AppColors.error : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDestructive ? AppColors.error.withOpacity(0.05) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: isDestructive ? null : AppShadows.soft,
        border: isDestructive ? Border.all(color: AppColors.error.withOpacity(0.1)) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title, 
          style: AppTextStyles.bodyLarge.copyWith(
            color: color,
            fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
          )
        ),
        trailing: isDestructive 
          ? null 
          : const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        onTap: onTap ?? () {},
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
    );
  }
}
