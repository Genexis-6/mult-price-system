import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/core/share/ui/widgets/custom_text.dart';
import 'package:mobile/core/utils/logger_utlis.dart';
import 'package:mobile/features/track/data/model/price_tracking_model.dart';
import 'package:mobile/features/track/ui/widgets/best_deal_cards.dart';
import 'package:url_launcher/url_launcher.dart';

class BestDealsSection extends StatelessWidget {
  final List<BestDeal> deals;
  final bool isDark;

  const BestDealsSection({
    super.key,
    required this.deals,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange, Colors.red],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.local_offer_rounded,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  CustomText(
                    'Best Deals For You',
                    type: TextType.titleSmall,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ],
              ),
              if (deals.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: CustomText(
                    'Save up to 30%',
                    type: TextType.bodySmall,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                    fontSize: 11.sp,
                  ),
                ),
            ],
          ),
        ),
        if (deals.isEmpty)
          Container(
            height: 140.h,
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark.withOpacity(0.3)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
            child: Center(
              child: CustomText(
                'No deals available',
                type: TextType.bodyMedium,
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          SizedBox(
            height: 320.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              itemCount: deals.length,
              itemBuilder: (context, index) {
                logger.d(
                  'Deal ${index}: productUrl = ${deals[index].productUrl}',
                );
                return BestDealCard(
                  deal: deals[index],
                  onTap: () {
                    logger.d(
                      'Tapped deal with URL: ${deals[index].productUrl}',
                    );
                    _openProductUrl(context, deals[index]);
                  },
                );
              },
            ),
          ),
        SizedBox(height: 8.h),
      ],
    );
  }

  void _openProductUrl(BuildContext context, BestDeal deal) async {
    if (deal.productUrl != null && deal.productUrl!.isNotEmpty) {
      final Uri url = Uri.parse(deal.productUrl!);
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          // ignore: use_build_context_synchronously
          _showUrlError(context);
        }
      } catch (e) {
        // ignore: use_build_context_synchronously
        _showUrlError(context);
      }
    } else {
      _showUrlError(context);
    }
  }

  void _showUrlError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: CustomText(
                'Product link not available',
                type: TextType.bodyMedium,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }
}
