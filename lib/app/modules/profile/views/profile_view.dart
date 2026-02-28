import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/text_widget.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_header_widget.dart';
import '../widgets/profile_body_widget.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : AppColors.scaffoldBackground,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = controller.user.value;
        if (user == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextWidget.body(AppStrings.failedToLoadProfile),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: AppStrings.retry,
                  onPressed: controller.fetchUserProfile,
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            // Profile Header
            ProfileHeaderWidget(onLogout: () => _showLogoutDialog(context)),

            // Use the abstracted body widget for info list and cards
            ProfileBodyWidget(
              controller: controller,
              user: user,
              isDark: isDark,
              onLogout: () => _showLogoutDialog(context),
            ),
          ],
        );
      }),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    Get.defaultDialog(
      title: AppStrings.logout,
      middleText: AppStrings.logoutConfirm,
      textConfirm: AppStrings.yes,
      textCancel: AppStrings.cancel,
      confirmTextColor: Colors.white,
      buttonColor: AppColors.error,
      onConfirm: () {
        Get.back();
        controller.logout();
      },
    );
  }
}
