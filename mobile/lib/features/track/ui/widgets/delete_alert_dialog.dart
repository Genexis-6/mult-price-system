import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/core/share/ui/widgets/custom_text.dart';
import 'package:mobile/core/share/ui/widgets/custom_snack_bar.dart';
import 'package:mobile/features/track/application/provider/price_tracking_provider.dart';

class DeleteAlertDialog extends ConsumerStatefulWidget {
  final int alertId;
  final String productName;

  const DeleteAlertDialog({
    super.key,
    required this.alertId,
    required this.productName,
  });

  @override
  ConsumerState<DeleteAlertDialog> createState() => _DeleteAlertDialogState();
}

class _DeleteAlertDialogState extends ConsumerState<DeleteAlertDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning Icon
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 32.sp,
              ),
            ),
            SizedBox(height: 16.h),
            
            // Title
            CustomText(
              'Delete Alert',
              type: TextType.titleLarge,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 8.h),
            
            // Message
            CustomText(
              'Are you sure you want to delete the price alert for "${widget.productName}"?',
              type: TextType.bodyMedium,
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            SizedBox(height: 8.h),
            
            // Warning
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: CustomText(
                      'This action cannot be undone.',
                      type: TextType.bodySmall,
                      color: Colors.orange,
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
                    onPressed: () => Navigator.pop(context, false),
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red, Colors.red.shade700],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _deleteAlert,
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
                                      Icons.delete_rounded,
                                      color: Colors.white,
                                      size: 18.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    CustomText(
                                      'Delete',
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

  Future<void> _deleteAlert() async {
    setState(() => _isLoading = true);

    try {
      final success = await ref
          .read(priceTrackingProvider.notifier)
          .cancelAlert(widget.alertId);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context, success);
        
        if (success) {
          CustomSnackbar.success(
            context: context,
            message: 'Alert deleted successfully',
          );
        } else {
          CustomSnackbar.error(
            context: context,
            message: 'Failed to delete alert',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context, false);
        CustomSnackbar.error(
          context: context,
          message: 'Error: ${e.toString()}',
        );
      }
    }
  }
}