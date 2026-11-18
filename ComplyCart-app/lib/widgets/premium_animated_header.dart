import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:ui';

class PremiumAnimatedHeader extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool isRoot;
  final VoidCallback? onProfileTap;

  const PremiumAnimatedHeader({
    super.key,
    required this.title,
    this.isRoot = true,
    this.onProfileTap,
  });

  @override
  State<PremiumAnimatedHeader> createState() => _PremiumAnimatedHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 12);
}

class _PremiumAnimatedHeaderState extends State<PremiumAnimatedHeader> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutQuart,
    ));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: widget.preferredSize.height + MediaQuery.of(context).padding.top,
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.7),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.surfaceVariant.withOpacity(0.5),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    children: [
                      if (!widget.isRoot)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                      
                      // AI Pulse
                      FadeTransition(
                        opacity: _pulseAnimation,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary,
                                blurRadius: 6,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      
                      // Title
                      Text(
                        widget.title,
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Profile Action
                      if (widget.onProfileTap != null)
                        InkWell(
                          onTap: widget.onProfileTap,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.xxs),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                size: 22,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
