import 'dart:math' as math;
import 'package:flutter/material.dart';
// import 'package:flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/theme/app_color.dart';
import '../../data/model/task_status_model.dart';

class ActiveTaskCard extends StatefulWidget {
  final TaskStatus? task;
  final String? message;
  // final VoidCallback onCancel;

  const ActiveTaskCard({
    super.key,
    this.task,
    // required this.onCancel,
    this.message,
  });

  @override
  State<ActiveTaskCard> createState() => _ActiveTaskCardState();
}

class _ActiveTaskCardState extends State<ActiveTaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Track previous progress for animation
  double _previousProgress = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(ActiveTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger animation when progress changes
    if (oldWidget.task?.progress != widget.task?.progress) {
      _pulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.task == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: AppColors.cardShadow,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  widget.message == null ? Icons.hourglass_top : Icons.info,
                  color: AppColors.primary,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  widget.message != null
                      ? widget.message!
                      : widget.task!.message,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                ),
              ),
              // GestureDetector(
              //   onTap: widget.onCancel,
              //   child: Icon(
              //     Icons.close,
              //     color: AppColors.textTertiary,
              //     size: 18.sp,
              //   ),
              // ),
            ],
          ),
          SizedBox(height: 12.h),

          // Animated Gradient Circular Progress
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: SizedBox(
                      width: 70.w,
                      height: 70.w,
                      child: _buildGradientCircularProgress(
                        widget.task!.progress,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(width: 16.w),

              // Progress Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Progress',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        '${widget.task!.progress}% Complete',
                        key: ValueKey(widget.task!.progress),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      widget.message == null
                          ? _getRemainingTime(widget.task!.progress)
                          : "",
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradientCircularProgress(int progress) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: _previousProgress / 100, end: progress / 100),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        // Update previous progress when animation completes
        if (value >= progress / 100 && progress != _previousProgress) {
          _previousProgress = progress.toDouble();
        }

        return CustomPaint(
          painter: GradientCircularProgressPainter(
            progress: value,
            gradientColors: const [
              Color(0xFF6366F1),
              Color(0xFF10B981),
              Color(0xFFF59E0B),
            ],
            strokeWidth: 6.w,
          ),
          child: Center(
            child: TweenAnimationBuilder(
              tween: IntTween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 500),
              builder: (context, int value, child) {
                return Text(
                  '$value%',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _getRemainingTime(int progress) {
    if (progress >= 100) return 'Complete!';
    final remaining = 100 - progress;
    final estimatedSeconds = (remaining * 0.6).toInt();
    if (estimatedSeconds < 60) {
      return '~$estimatedSeconds seconds remaining';
    }
    final minutes = estimatedSeconds ~/ 60;
    final seconds = estimatedSeconds % 60;
    return '~$minutes min ${seconds}s remaining';
  }
}

// Custom Painter for Gradient Circular Progress
class GradientCircularProgressPainter extends CustomPainter {
  final double progress;
  final List<Color> gradientColors;
  final double strokeWidth;

  GradientCircularProgressPainter({
    required this.progress,
    required this.gradientColors,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Gradient for progress
    final gradient = SweepGradient(
      center: Alignment.center,
      colors: gradientColors,
      stops: const [0.0, 0.5, 1.0],
      transform: GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
