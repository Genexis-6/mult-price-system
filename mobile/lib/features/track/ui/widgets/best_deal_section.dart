import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/core/share/ui/widgets/custom_text.dart';
import 'package:mobile/features/track/data/model/price_tracking_model.dart';
import 'package:mobile/features/track/ui/widgets/best_deal_cards.dart';

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
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
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
              color: isDark ? AppColors.surfaceDark.withOpacity(0.3) : AppColors.surface,
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
                return BestDealCard(
                  deal: deals[index],
                  onTap: () {
                    // Navigate to product details
                  },
                );
              },
            ),
          ),
        SizedBox(height: 8.h),
      ],
    );
  }
}