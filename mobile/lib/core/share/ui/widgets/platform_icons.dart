import 'package:flutter/material.dart';
// import 'package:flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/gen/assets.gen.dart';

class AnimatedPlatformIcons extends StatelessWidget {
  const AnimatedPlatformIcons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CreativeIconCircle(
          icon: Icons.shopping_bag_outlined,
          color: Colors.orange,
          delay: 0,
        ),
        SizedBox(width: 8.w),
        _CreativeIconCircle(
          icon: Icons.store_outlined,
          color: Colors.green,
          delay: 200,
        ),
        SizedBox(width: 8.w),
        _CreativeIconCircle(
          icon: Icons.shop_outlined,
          color: Colors.red,
          delay: 400,
        ),
      ],
    );
  }
}

class _CreativeIconCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int delay;

  const _CreativeIconCircle({
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16.sp,
            ),
          ),
        );
      },
    );
  }
}

class StackedPlatformLogos extends StatelessWidget {
  const StackedPlatformLogos({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100.w,
      height: 48.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: _SmallIconCircle(
              imagePath: Assets.images.jumiaLogo.path,
              backgroundColor: Colors.orange,
              size: 40,
            ),
          ),
          Positioned(
            left: 28.w,
            top: 0,
            child: _SmallIconCircle(
              imagePath: Assets.images.jijiLogo.path,
              backgroundColor: Colors.green,
              size: 40,
            ),
          ),
          Positioned(
            left: 56.w,
            top: 0,
            child: _SmallIconCircle(
              imagePath: Assets.images.kongaLogo.path,
              backgroundColor: Colors.red,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallIconCircle extends StatelessWidget {
  final String imagePath;
  final Color backgroundColor;
  final double size;

  const _SmallIconCircle({
    required this.imagePath,
    required this.backgroundColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.w),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}