import 'package:flutter/material.dart';
// import 'package:flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/theme/app_color.dart';

class GridPatternPainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double spacing;

  GridPatternPainter({
    required this.color,
    required this.opacity,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Dot Pattern Background
class DotPatternPainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double spacing;
  final double dotRadius;

  DotPatternPainter({
    required this.color,
    required this.opacity,
    required this.spacing,
    this.dotRadius = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Simple Styled Scaffold (without animation) - Use this as default
class StyledScaffold extends StatelessWidget {
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final bool useGradientBackground;
  final bool showGridPattern;
  final double gridOpacity;

  const StyledScaffold({
    super.key,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.appBar,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
    this.useGradientBackground = true,
    this.showGridPattern = true,
    this.gridOpacity = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: appBar,
      body: Container(
        decoration: BoxDecoration(
          gradient: useGradientBackground
              ? _getGradient(isDark)
              : null,
          color: !useGradientBackground 
              ? (backgroundColor ?? (isDark ? AppColors.backgroundDark : AppColors.background))
              : null,
        ),
        child: Stack(
          children: [
            // Grid Pattern Background
            if (showGridPattern)
              CustomPaint(
                painter: GridPatternPainter(
                  color: isDark ? Colors.white : Colors.black,
                  opacity: gridOpacity,
                  spacing: 20.w,
                ),
                size: Size.infinite,
              ),
            // Main Content
            body,
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }

  LinearGradient _getGradient(bool isDark) {
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.backgroundDark,
          AppColors.grey900,
          const Color(0xFF1a1a2e),
        ],
        stops: const [0.0, 0.5, 1.0],
      );
    } else {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.background,
          AppColors.grey50,
          const Color(0xFFF0F4F8),
        ],
        stops: const [0.0, 0.5, 1.0],
      );
    }
  }
}

// Gradient Styled Scaffold with optional animated gradient - FIXED
class GradientStyledScaffold extends StatefulWidget {
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool resizeToAvoidBottomInset;
  final bool showGridPattern;
  final bool animatedGradient;

  const GradientStyledScaffold({
    super.key,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.appBar,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = true,
    this.showGridPattern = true,
    this.animatedGradient = false,
  });

  @override
  State<GradientStyledScaffold> createState() => _GradientStyledScaffoldState();
}

class _GradientStyledScaffoldState extends State<GradientStyledScaffold> with SingleTickerProviderStateMixin {
  AnimationController? _gradientController;
  Animation<double>? _gradientAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.animatedGradient) {
      _gradientController = AnimationController(
        duration: const Duration(seconds: 10),
        vsync: this,
      )..repeat(reverse: true);
      _gradientAnimation = Tween<double>(begin: 0, end: 1).animate(_gradientController!);
    }
  }

  @override
  void dispose() {
    _gradientController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget background = Container(
      decoration: BoxDecoration(
        gradient: _getGradient(isDark),
      ),
    );

    if (widget.animatedGradient && _gradientAnimation != null) {
      background = AnimatedBuilder(
        animation: _gradientAnimation!,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: _getAnimatedGradient(isDark),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: widget.appBar,
      body: Stack(
        children: [
          background,
          if (widget.showGridPattern)
            CustomPaint(
              painter: GridPatternPainter(
                color: isDark ? Colors.white : Colors.black,
                opacity: 0.03,
                spacing: 20.w,
              ),
              size: Size.infinite,
            ),
          widget.body,
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      bottomNavigationBar: widget.bottomNavigationBar,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
    );
  }

  LinearGradient _getGradient(bool isDark) {
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.backgroundDark,
          AppColors.grey900,
          const Color(0xFF1a1a2e),
          const Color(0xFF16213e),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      );
    } else {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.background,
          AppColors.grey50,
          const Color(0xFFE8EDF2),
          const Color(0xFFF5F7FA),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      );
    }
  }

  LinearGradient _getAnimatedGradient(bool isDark) {
    final animationValue = _gradientAnimation?.value ?? 0.0;
    
    if (isDark) {
      return LinearGradient(
        begin: Alignment(animationValue, 0),
        end: Alignment(1 - animationValue, 1),
        colors: [
          AppColors.backgroundDark,
          AppColors.grey900,
          const Color(0xFF1a1a2e),
          const Color(0xFF16213e),
        ],
      );
    } else {
      return LinearGradient(
        begin: Alignment(animationValue, 0),
        end: Alignment(1 - animationValue, 1),
        colors: [
          AppColors.background,
          AppColors.grey50,
          const Color(0xFFE8EDF2),
          const Color(0xFFF5F7FA),
        ],
      );
    }
  }
}

// StyledScrollView with gradient and grid
class StyledScrollView extends StatelessWidget {
  final List<Widget> slivers;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;
  final bool useGradientBackground;
  final bool showGridPattern;
  final double gridOpacity;

  const StyledScrollView({
    super.key,
    required this.slivers,
    this.bottomNavigationBar,
    this.appBar,
    this.useGradientBackground = true,
    this.showGridPattern = true,
    this.gridOpacity = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: appBar,
      body: Container(
        decoration: BoxDecoration(
          gradient: useGradientBackground
              ? _getGradient(isDark)
              : null,
          color: !useGradientBackground 
              ? (isDark ? AppColors.backgroundDark : AppColors.background)
              : null,
        ),
        child: Stack(
          children: [
            // Grid Pattern Background
            if (showGridPattern)
              CustomPaint(
                painter: GridPatternPainter(
                  color: isDark ? Colors.white : Colors.black,
                  opacity: gridOpacity,
                  spacing: 20.w,
                ),
                size: Size.infinite,
              ),
            // Main Content
            CustomScrollView(
              slivers: slivers,
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  LinearGradient _getGradient(bool isDark) {
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.backgroundDark,
          AppColors.grey900,
          const Color(0xFF1a1a2e),
        ],
        stops: const [0.0, 0.5, 1.0],
      );
    } else {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.background,
          AppColors.grey50,
          const Color(0xFFF0F4F8),
        ],
        stops: const [0.0, 0.5, 1.0],
      );
    }
  }
}

// Usage Extension for easy access
extension StyledScaffoldExtension on Widget {
  Widget withStyledBackground({
    bool useGradient = true,
    bool showGrid = true,
    double gridOpacity = 0.05,
  }) {
    return StyledScaffold(
      body: this,
      useGradientBackground: useGradient,
      showGridPattern: showGrid,
      gridOpacity: gridOpacity,
    );
  }
}