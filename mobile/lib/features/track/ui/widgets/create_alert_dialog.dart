import 'package:flutter/material.dart';
// import 'package:flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/share/ui/widgets/custom_button.dart';
import 'package:mobile/core/theme/app_color.dart';
// import 'package:mobile/core/share/ui/widgets/custom_buttons.dart';
import 'package:mobile/core/share/ui/widgets/custom_text.dart';
import 'package:mobile/core/share/ui/widgets/custom_snack_bar.dart';

class CreateAlertDialog extends StatefulWidget {
  const CreateAlertDialog({super.key});

  @override
  State<CreateAlertDialog> createState() => _CreateAlertDialogState();
}

class _CreateAlertDialogState extends State<CreateAlertDialog> {
  final _productController = TextEditingController();
  final _priceController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_alert_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                CustomText(
                  'Create Price Alert',
                  type: TextType.titleLarge,
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                ),
              ],
            ),
            SizedBox(height: 20.h),
            TextField(
              controller: _productController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                hintText: 'e.g., iPhone 15 Pro Max',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Target Price (₦)',
                hintText: 'e.g., 1000000',
                prefixIcon: Icon(Icons.price_change),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'receive@alerts.com',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 24.h),
            CustomButtons.primaryButton(
              onPressed: _createAlert,
              text: 'Create Alert',
              isLoading: _isLoading,
              icon: Icons.notifications_active,
            ),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: CustomText(
                'Cancel',
                type: TextType.bodyMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAlert() async {
    final product = _productController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final email = _emailController.text.trim();

    if (product.isEmpty) {
      CustomSnackbar.warning(context: context, message: 'Please enter product name');
      return;
    }
    if (price == null || price <= 0) {
      CustomSnackbar.warning(context: context, message: 'Please enter valid target price');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      CustomSnackbar.warning(context: context, message: 'Please enter valid email');
      return;
    }

    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _isLoading = false);
    Navigator.pop(context);
    CustomSnackbar.success(
      context: context,
      message: 'Price alert created successfully!',
    );
  }
}