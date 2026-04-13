import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/gen/assets.gen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onSplashComplete;
  final Duration duration;

  const SplashScreen({
    super.key,
     this.onSplashComplete,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _splashController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Individual animation controllers for each circle
  late AnimationController _jumiaController;
  late AnimationController _jijiController;
  late AnimationController _kongaController;
  
  late Animation<double> _jumiaScale;
  late Animation<double> _jijiScale;
  late Animation<double> _kongaScale;
  
  late Animation<double> _jumiaOpacity;
  late Animation<double> _jijiOpacity;
  late Animation<double> _kongaOpacity;

  @override
  void initState() {
    super.initState();
    
    // Main splash controller
    _splashController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _splashController,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _splashController,
      curve: Curves.easeOutCubic,
    ));
    
    // Jumia animation (first)
    _jumiaController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _jumiaScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _jumiaController, curve: Curves.elasticOut)
    );
    _jumiaOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _jumiaController, curve: Curves.easeOut)
    );
    
    // Jiji animation (second with delay)
    _jijiController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _jijiScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _jijiController, curve: Curves.elasticOut)
    );
    _jijiOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _jijiController, curve: Curves.easeOut)
    );
    
    // Konga animation (third with delay)
    _kongaController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _kongaScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _kongaController, curve: Curves.elasticOut)
    );
    _kongaOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _kongaController, curve: Curves.easeOut)
    );
    
    // Start the splash animation
    _splashController.forward();
    
    // Start circle animations with staggered delays
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _jumiaController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _jijiController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _kongaController.forward();
    });
    
    // Hide splash after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        widget.onSplashComplete!();
      }
    });
  }

  @override
  void dispose() {
    _splashController.dispose();
    _jumiaController.dispose();
    _jijiController.dispose();
    _kongaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _splashController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Welcome Title
                    ShaderMask(
                      shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                      child: Text(
                        'MULA SEARCH',
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Find the best deals across Africa\'s top marketplaces',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 48.h),
                    
                    // Stacked Animated Platform Icons
                    _buildStackedAnimatedPlatformIcons(),
                    
                    SizedBox(height: 48.h),
                    
                    // Circular Progress Indicator
                    SizedBox(
                      width: 40.w,
                      height: 40.w,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStackedAnimatedPlatformIcons() {
    return SizedBox(
      width: 180.w,
      height: 120.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Jumia Logo - Back (animated)
          Positioned(
            left: 0,
            top: 20.h,
            child: AnimatedBuilder(
              animation: _jumiaController,
              builder: (context, child) {
                final scale = _jumiaScale.value.clamp(0.0, 1.0);
                final opacity = _jumiaOpacity.value.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: child,
                  ),
                );
              },
              child: _buildIconCircle(
                imagePath: Assets.images.jumiaLogo.path,
                backgroundColor: Colors.orange,
                size: 80,
              ),
            ),
          ),
          // Jiji Logo - Middle (animated)
          Positioned(
            left: 50.w,
            top: 10.h,
            child: AnimatedBuilder(
              animation: _jijiController,
              builder: (context, child) {
                final scale = _jijiScale.value.clamp(0.0, 1.0);
                final opacity = _jijiOpacity.value.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: child,
                  ),
                );
              },
              child: _buildIconCircle(
                imagePath: Assets.images.jijiLogo.path,
                backgroundColor: Colors.green,
                size: 80,
              ),
            ),
          ),
          // Konga Logo - Front (animated)
          Positioned(
            left: 100.w,
            top: 0,
            child: AnimatedBuilder(
              animation: _kongaController,
              builder: (context, child) {
                final scale = _kongaScale.value.clamp(0.0, 1.0);
                final opacity = _kongaOpacity.value.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: child,
                  ),
                );
              },
              child: _buildIconCircle(
                imagePath: Assets.images.kongaLogo.path,
                backgroundColor: Colors.red,
                size: 80,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconCircle({
    required String imagePath,
    required Color backgroundColor,
    required double size,
  }) {
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3.w,
        ),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.store,
                color: Colors.white,
                size: size * 0.5,
              ),
            );
          },
        ),
      ),
    );
  }
}