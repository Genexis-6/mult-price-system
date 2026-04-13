import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/share/ui/widgets/custom_button.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/core/share/ui/widgets/custom_text.dart';
import 'package:mobile/core/share/ui/widgets/custom_snack_bar.dart';
import 'package:mobile/features/track/application/provider/price_tracking_provider.dart';

class CreateAlertDialog extends ConsumerStatefulWidget {
  const CreateAlertDialog({super.key, required this.isFirstTime});
  final bool isFirstTime;

  @override
  ConsumerState<CreateAlertDialog> createState() => _CreateAlertDialogState();
}

class _CreateAlertDialogState extends ConsumerState<CreateAlertDialog> {
  final _productController = TextEditingController();
  final _priceController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCachedEmail();
  }

  @override
  void dispose() {
    _productController.dispose();
    _priceController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadCachedEmail() {
    final notifier = ref.read(priceTrackingProvider.notifier);
    if (notifier.hasCachedEmail()) {
      _emailController.text = notifier.getCachedEmail()!;
    }
  }

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
              readOnly: widget.isFirstTime == false,
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
    final price = _priceController.text.trim();
    final email = _emailController.text.trim();

    // Validate product name
    if (product.isEmpty) {
      CustomSnackbar.warning(
        context: context,
        message: 'Please enter product name',
      );
      return;
    }

    // Validate price
    if (price.isEmpty) {
      CustomSnackbar.warning(
        context: context,
        message: 'Please enter target price',
      );
      return;
    }

    final targetPrice = double.tryParse(price);
    if (targetPrice == null || targetPrice <= 0) {
      CustomSnackbar.warning(
        context: context,
        message: 'Please enter valid target price',
      );
      return;
    }

    // Validate email
    if (email.isEmpty || !email.contains('@')) {
      CustomSnackbar.warning(
        context: context,
        message: 'Please enter valid email',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create alert via provider
      await ref
          .read(priceTrackingProvider.notifier)
          .createAlert(
            productName: product,
            targetPrice: targetPrice,
            email: email,
          );

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);

        if (widget.isFirstTime) {
          CustomSnackbar.success(
            context: context,
            message: '🎉 Welcome! Your first price alert is active!',
          );
        } else {
          CustomSnackbar.success(
            context: context,
            message: '✅ Price alert created successfully!',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackbar.error(
          context: context,
          message: 'Failed to create alert: $e',
        );
      }
    }
  }
}
