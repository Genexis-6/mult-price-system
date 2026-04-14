import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/share/ui/widgets/custom_text.dart';
import 'package:mobile/core/share/ui/widgets/custom_snack_bar.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/features/track/application/provider/price_tracking_provider.dart';
import 'package:mobile/features/track/data/model/price_tracking_model.dart';

class UpdateAlertDialog extends ConsumerStatefulWidget {
  final TrackedProduct product;

  const UpdateAlertDialog({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<UpdateAlertDialog> createState() => _UpdateAlertDialogState();
}

class _UpdateAlertDialogState extends ConsumerState<UpdateAlertDialog> {
  final _priceController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _priceController.text = widget.product.targetPrice.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'Update Target Price',
                        type: TextType.titleLarge,
                        color: isDark ? AppColors.textLight : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      CustomText(
                        widget.product.productName,
                        type: TextType.bodySmall,
                        color: AppColors.textSecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Current Price Info
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'Current Best Price',
                        type: TextType.bodySmall,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 4.h),
                      CustomText(
                        widget.product.currentPrice != null
                            ? '₦${_formatPrice(widget.product.currentPrice!)}'
                            : 'Pending',
                        type: TextType.titleMedium,
                        color: widget.product.currentPrice != null &&
                                widget.product.currentPrice! <= widget.product.targetPrice
                            ? Colors.green
                            : (isDark ? AppColors.textLight : AppColors.textPrimary),
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: _getPlatformColor(widget.product.platform).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPlatformIcon(widget.product.platform),
                          color: _getPlatformColor(widget.product.platform),
                          size: 14.sp,
                        ),
                        SizedBox(width: 4.w),
                        CustomText(
                          widget.product.platform.toUpperCase(),
                          type: TextType.bodySmall,
                          color: _getPlatformColor(widget.product.platform),
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Target Price Input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'New Target Price',
                  type: TextType.bodyMedium,
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                SizedBox(height: 8.h),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16.r),
                            bottomLeft: Radius.circular(16.r),
                          ),
                        ),
                        child: CustomText(
                          '₦',
                          type: TextType.titleLarge,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20.sp,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: isDark ? AppColors.textLight : AppColors.textPrimary,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter new target price',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                              fontSize: 16.sp,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Info Message
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blue,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: CustomText(
                      'After updating, we\'ll immediately check the current price for you.',
                      type: TextType.bodySmall,
                      color: Colors.blue,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: CustomText(
                      'Cancel',
                      type: TextType.bodyLarge,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _updateAlert,
                        borderRadius: BorderRadius.circular(12.r),
                        child: Center(
                          child: _isLoading
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 18.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    CustomText(
                                      'Update',
                                      type: TextType.bodyLarge,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAlert() async {
    final priceText = _priceController.text.trim();
    if (priceText.isEmpty) {
      CustomSnackbar.warning(
        context: context,
        message: 'Please enter a target price',
      );
      return;
    }

    final newPrice = double.tryParse(priceText);
    if (newPrice == null || newPrice <= 0) {
      CustomSnackbar.warning(
        context: context,
        message: 'Please enter a valid price',
      );
      return;
    }

    if (newPrice == widget.product.targetPrice) {
      CustomSnackbar.info(
        context: context,
        message: 'Target price is already set to ₦${_formatPrice(newPrice)}',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ref
          .read(priceTrackingProvider.notifier)
          .updateAlert(
            alertId: int.parse(widget.product.id),
            targetPrice: newPrice,
          );

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (success) {
          Navigator.pop(context);
          CustomSnackbar.success(
            context: context,
            message: 'Target price updated to ₦${_formatPrice(newPrice)}',
          );
        } else {
          CustomSnackbar.error(
            context: context,
            message: 'Failed to update target price',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackbar.error(
          context: context,
          message: 'Error: ${e.toString()}',
        );
      }
    }
  }

  String _formatPrice(num price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'jumia':
        return const Color(0xFFFF6B00);
      case 'konga':
        return const Color(0xFFFF0066);
      case 'jiji':
        return const Color(0xFF00D084);
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'jumia':
        return Icons.shopping_bag_rounded;
      case 'konga':
        return Icons.store_rounded;
      case 'jiji':
        return Icons.shopping_cart_rounded;
      default:
        return Icons.shopping_cart_rounded;
    }
  }
}