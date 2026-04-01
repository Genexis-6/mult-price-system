import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/theme.dart';
import '../ui.dart';

class PageNotFound extends StatelessWidget {
  const PageNotFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,

        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animated 404 text - FIXED VERSION
                  _build404Animation(),

                  SizedBox(height: 32.h),

                  // Error icon
                  Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlueGrey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off_outlined,
                      size: 60.sp,
                      color: AppColors.primaryBlueGrey,
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Title
                  CustomText(
                    'Page Not Found',
                    type: TextType.headlineMedium,
                    color: AppColors.textPrimary,
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 16.h),

                  // Description
                  CustomText(
                    'Oops! The page you\'re looking for doesn\'t exist or has been moved.',
                    type: TextType.bodyLarge,
                    color: AppColors.textSecondary,
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 8.h),

                  CustomText(
                    'Please check the URL or navigate back to the homepage.',
                    type: TextType.bodyMedium,
                    color: AppColors.textSecondary,
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 48.h),

                  // Action buttons
                  Column(
                    children: [
                      CustomButtons.primaryButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        text: 'Go Back',
                        icon: Icons.arrow_back,
                      ),

                      SizedBox(height: 16.h),

                      CustomButtons.secondaryButton(
                        onPressed: () {
                          // Navigate to home - adjust route name as needed
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/', (route) => false);
                        },
                        text: 'Go to Homepage',
                        icon: Icons.home,
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Additional help text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomText(
                        'Need help? ',
                        type: TextType.bodySmall,
                        color: AppColors.textSecondary,
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigate to support/contact
                        },
                        child: CustomText(
                          'Contact Support',
                          type: TextType.bodySmall,
                          color: AppColors.accentTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _build404Animation() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic, // Changed from easeOutBack to avoid overshoot
      builder: (context, double value, child) {
        // Clamp the value to ensure it stays between 0 and 1
        final clampedValue = value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: clampedValue,
          child: Opacity(opacity: clampedValue, child: child),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '4',
            style: GoogleFonts.spaceMono(
              fontSize: 120.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlueGrey,
              height: 1,
            ),
          ),
          Container(
            width: 80.w,
            height: 120.h,
            margin: EdgeInsets.symmetric(horizontal: 8.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accentTeal, AppColors.accentDarkTeal],
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentTeal.withOpacity(0.3),
                  blurRadius: 10.r,
                  offset: Offset(0, 5.h),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '0',
                style: GoogleFonts.spaceMono(
                  fontSize: 100.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
          ),
          Text(
            '4',
            style: GoogleFonts.spaceMono(
              fontSize: 120.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlueGrey,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
