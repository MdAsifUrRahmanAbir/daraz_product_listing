import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../widgets/text_widget.dart';
import '../controllers/profile_controller.dart';

class ProfileHeaderWidget extends GetView<ProfileController> {
  final VoidCallback onLogout;
  const ProfileHeaderWidget({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final user = controller.user.value!;
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: true,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
      flexibleSpace: FlexibleSpaceBar(

        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: AppSizes.gapMid),
                // Avatar
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSizes.gapSmall),
                TextWidget.headlineMedium(
                  user.fullName,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),

                TextWidget.bodySmall(
                  user.email ?? '',
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
