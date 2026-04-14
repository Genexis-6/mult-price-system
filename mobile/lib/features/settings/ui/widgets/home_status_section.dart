import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/share/ui/widgets/custom_text.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/features/home/application/provider/home_provider.dart';
import 'package:mobile/features/home/application/state/home_state.dart';
import 'package:mobile/features/settings/ui/widgets/settings_section_card.dart';

class HomeStatusSection extends ConsumerWidget {
  final bool isDark;

  const HomeStatusSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeStateAsync = ref.watch(homeProvider);

    return SettingsSectionCard(
      isDark: isDark,
      title: 'Home & Search Status',
      icon: Icons.home_rounded,
      children: [
        homeStateAsync.when(
          data: (state) => _buildStateContent(state, isDark, ref),
          loading: () => _buildLoadingState(isDark),
          error: (error, _) => _buildErrorState(error.toString(), isDark, ref),
        ),
      ],
    );
  }

  Widget _buildStateContent(HomeState state, bool isDark, WidgetRef ref) {
    // Use safe cast extensions
    if (state.isInitial) {
      return _buildInfoRow(
        icon: Icons.check_circle_outline,
        label: 'Status',
        value: 'Ready',
        isDark: isDark,
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: CustomText(
            'Idle',
            type: TextType.bodySmall,
            color: Colors.green,
            fontSize: 10.sp,
          ),
        ),
      );
    }

    if (state.isLoading) {
      return _buildLoadingState(isDark);
    }

    if (state.isReconnecting) {
      final reconnectState = state.asReconnecting!;
      return Column(
        children: [
          _buildInfoRow(
            icon: Icons.sync_rounded,
            label: 'Status',
            value: 'Reconnecting',
            isDark: isDark,
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12.w,
                    height: 12.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  CustomText(
                    'Syncing',
                    type: TextType.bodySmall,
                    color: Colors.orange,
                    fontSize: 10.sp,
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          _buildInfoRow(
            icon: Icons.search_rounded,
            label: 'Query',
            value: reconnectState.query,
            isDark: isDark,
            maxLines: 2,
          ),
          Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          _buildInfoRow(
            icon: Icons.assignment_rounded,
            label: 'Task ID',
            value: _formatTaskId(reconnectState.taskId),
            isDark: isDark,
          ),
        ],
      );
    }

    if (state.isTaskCreated) {
      final createdState = state.asTaskCreated!;
      return Column(
        children: [
          _buildInfoRow(
            icon: Icons.play_circle_outline,
            label: 'Status',
            value: 'Task Created',
            isDark: isDark,
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: CustomText(
                'Starting',
                type: TextType.bodySmall,
                color: Colors.blue,
                fontSize: 10.sp,
              ),
            ),
          ),
          Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          _buildInfoRow(
            icon: Icons.search_rounded,
            label: 'Query',
            value: createdState.query,
            isDark: isDark,
            maxLines: 2,
          ),
          Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          _buildInfoRow(
            icon: Icons.assignment_rounded,
            label: 'Task ID',
            value: _formatTaskId(createdState.taskId),
            isDark: isDark,
          ),
        ],
      );
    }

    if (state.isTaskProcessing) {
      final processingState = state.asTaskProcessing!;
      return Column(
        children: [
          _buildInfoRow(
            icon: Icons.pending_actions_rounded,
            label: 'Status',
            value: 'Processing',
            isDark: isDark,
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: CustomText(
                '${processingState.progress}%',
                type: TextType.bodySmall,
                color: Colors.orange,
                fontSize: 10.sp,
              ),
            ),
          ),
          Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          _buildProgressBar(processingState.progress, isDark),
          Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          _buildInfoRow(
            icon: Icons.search_rounded,
            label: 'Query',
            value: processingState.query,
            isDark: isDark,
            maxLines: 2,
          ),
          Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          _buildInfoRow(
            icon: Icons.assignment_rounded,
            label: 'Task ID',
            value: _formatTaskId(processingState.taskId),
            isDark: isDark,
          ),
          Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          _buildInfoRow(
            icon: Icons.info_outline,
            label: 'Message',
            value: processingState.message,
            isDark: isDark,
            maxLines: 2,
          ),
        ],
      );
    }

    if (state.isTaskCompleted) {
      final completedState = state.asTaskCompleted!;
      final resultCount = completedState.result is List ? (completedState.result as List).length : 0;
      return Column(
        children: [
          _buildInfoRow(
            icon: Icons.check_circle_rounded,
            label: 'Status',
            value: 'Completed',
            isDark: isDark,
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: CustomText(
                'Success',
                type: TextType.bodySmall,
                color: Colors.green,
                fontSize: 10.sp,
              ),
            ),
          ),
          Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          _buildInfoRow(
            icon: Icons.search_rounded,
            label: 'Query',
            value: completedState.query,
            isDark: isDark,
            maxLines: 2,
          ),
          Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          _buildInfoRow(
            icon: Icons.assignment_rounded,
            label: 'Task ID',
            value: _formatTaskId(completedState.taskId),
            isDark: isDark,
          ),
          Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          _buildInfoRow(
            icon: Icons.list_alt_rounded,
            label: 'Results',
            value: '$resultCount items found',
            isDark: isDark,
          ),
        ],
      );
    }

    if (state.isTaskFailed) {
      final failedState = state.asTaskFailed!;
      return Column(
        children: [
          _buildInfoRow(
            icon: Icons.error_outline_rounded,
            label: 'Status',
            value: 'Failed',
            isDark: isDark,
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: CustomText(
                'Error',
                type: TextType.bodySmall,
                color: Colors.red,
                fontSize: 10.sp,
              ),
            ),
          ),
          Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          _buildInfoRow(
            icon: Icons.search_rounded,
            label: 'Query',
            value: failedState.query,
            isDark: isDark,
            maxLines: 2,
          ),
          Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          _buildInfoRow(
            icon: Icons.assignment_rounded,
            label: 'Task ID',
            value: _formatTaskId(failedState.taskId),
            isDark: isDark,
          ),
          Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          _buildInfoRow(
            icon: Icons.error_rounded,
            label: 'Error',
            value: failedState.error,
            isDark: isDark,
            maxLines: 3,
            valueColor: Colors.red,
          ),
          Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          _buildActionTile(
            icon: Icons.refresh_rounded,
            title: 'Retry Connection',
            subtitle: 'Attempt to reconnect to task',
            iconColor: Colors.blue,
            isDark: isDark,
            onTap: () {
              ref.read(homeProvider.notifier).reconnectToTask();
            },
          ),
        ],
      );
    }

    if (state.isError) {
      final errorState = state.asError!;
      return _buildErrorState(errorState.message, isDark, ref);
    }

    return _buildInfoRow(
      icon: Icons.help_outline,
      label: 'Status',
      value: 'Unknown',
      isDark: isDark,
    );
  }

  Widget _buildProgressBar(int progress, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              'Progress',
              type: TextType.bodySmall,
              color: AppColors.textSecondary,
              fontSize: 11.sp,
            ),
            CustomText(
              '$progress%',
              type: TextType.bodySmall,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11.sp,
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6.h,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Padding(
      padding: EdgeInsets.all(16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20.w,
            height: 20.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 12.w),
          CustomText(
            'Loading home status...',
            type: TextType.bodyMedium,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark, WidgetRef ref) {
    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.error_outline,
          label: 'Status',
          value: 'Error',
          isDark: isDark,
          valueColor: Colors.red,
        ),
        Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
        _buildInfoRow(
          icon: Icons.warning_rounded,
          label: 'Message',
          value: error,
          isDark: isDark,
          maxLines: 3,
          valueColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Widget? trailing,
    int maxLines = 1,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                label,
                type: TextType.bodySmall,
                color: AppColors.textSecondary,
                fontSize: 11.sp,
              ),
              SizedBox(height: 2.h),
              CustomText(
                value,
                type: TextType.bodyMedium,
                color: valueColor ?? (isDark ? AppColors.textLight : AppColors.textPrimary),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, color: iconColor, size: 16.sp),
      ),
      title: CustomText(
        title,
        type: TextType.bodySmall,
        color: isDark ? AppColors.textLight : AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      subtitle: CustomText(
        subtitle,
        type: TextType.bodySmall,
        color: AppColors.textSecondary,
        fontSize: 10.sp,
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: AppColors.textSecondary,
        size: 12.sp,
      ),
      onTap: onTap,
    );
  }

  String _formatTaskId(String taskId) {
    if (taskId.length > 20) {
      return '${taskId.substring(0, 10)}...${taskId.substring(taskId.length - 6)}';
    }
    return taskId;
  }
}