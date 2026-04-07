import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/features/home/application/state/home_state.dart';
// import 'package:mobile/core/share/application/provider/repo_provider.dart';
import 'package:mobile/features/home/data/model/task_status_model.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:mobile/core/share/data/model/product_model.dart';
import 'package:mobile/core/share/ui/widgets/custom_scafold.dart';
import 'package:mobile/core/share/ui/widgets/custom_snack_bar.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/features/home/application/provider/home_provider.dart';
// import 'package:mobile/features/home/application/state/home_state.dart';
import 'package:mobile/features/home/data/model/dummy_data.dart';
import 'package:mobile/features/home/data/model/news_model.dart';
import 'package:mobile/features/home/ui/widgets/widgets.dart';
import '../../../../core/share/ui/widgets/custom_app_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  double _scrollOffset = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeStateAsync = ref.watch(homeProvider);

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        setState(() {
          _scrollOffset = scrollInfo.metrics.pixels;
        });
        return false;
      },
      child: GradientStyledScaffold(
        body: CustomScrollView(
          slivers: [
            CustomAppBar(
              isDark: isDark,
              scrollOffset: _scrollOffset,
              onSearch: _handleSearch,
              searchController: _searchController,
              isLoading: _isLoading,
            ),

            SliverList(
              delegate: SliverChildListDelegate([
                SearchBarWidget(
                  controller: _searchController,
                  onSearch: _handleSearch,
                  readOnly: _isLoading || homeStateAsync.isLoading,
                  isLoading: _isLoading,
                ),

                // Active Task Card - Always visible during task lifecycle
                homeStateAsync.when(
                  data: (state) {
                    return state.when(
                      initial: () => _buildSkeletonActiveTaskCard(
                        message: "No active task",
                        showProgress: false,
                      ),
                      loading: () => _buildSkeletonActiveTaskCard(
                        message: "Initializing...",
                        showProgress: true,
                      ),
                      reconnecting: (taskId, query) =>
                          _buildSkeletonActiveTaskCard(
                            message: "Reconnecting to task...",
                            showProgress: true,
                          ),
                      taskCreated: (taskId, query) =>
                          _buildSkeletonActiveTaskCard(
                            message: "Task created, waiting for updates...",
                            showProgress: false,
                          ),
                      taskProcessing: (taskId, query, progress, message) =>
                          ActiveTaskCard(
                            task: TaskStatus(
                              taskId: taskId,
                              status: 'processing',
                              progress: progress,
                              message: message,
                              timestamp: DateTime.now(),
                            ),
                            // onCancel: () =>
                            //     ref.read(homeProvider.notifier).cancelTask(),
                          ),
                      taskCompleted: (taskId, query, result) {
                        List<Product> products = [];
                        if (result != null && result is List) {
                          products = result
                              .map((json) => Product.fromJson(json))
                              .toList();
                        }
                        return CompletedTaskCard(
                          query: query,
                          products: products,
                          onDismiss: () =>
                              ref.read(homeProvider.notifier).cancelTask(),
                          onProductTap: (product) {
                            // Handle product tap - open URL or show details
                            CustomSnackbar.info(
                              context: context,
                              message: 'Opening ${product.productName}',
                            );
                            // You can launch URL here
                            // launchUrl(Uri.parse(product.productUrl));
                          },
                        );
                      },
                      taskFailed: (taskId, query, error) =>
                          _buildFailedTaskCard(error),
                      error: (message) => _buildErrorCard(message),
                    );
                  },
                  loading: () => _buildSkeletonActiveTaskCard(
                    message: "Loading...",
                    showProgress: true,
                  ),
                  error: (error, _) => _buildErrorCard(error.toString()),
                ),

                NewsCarousel(
                  newsList: DummyData.getNews(),
                  onNewsTap: _handleNewsTap,
                ),
                RecentSearchesChips(
                  searches: DummyData.getRecentSearches(),
                  onSearchTap: _handleRecentSearchTap,
                ),
                SizedBox(height: 20.h),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // Skeleton wrapper for ActiveTaskCard
  Widget _buildSkeletonActiveTaskCard({
    required String message,
    required bool showProgress,
  }) {
    return Skeletonizer(
      enabled: showProgress,
      effect: const ShimmerEffect(
        duration: Duration(seconds: 1),
        // intensity: 0.5,
      ),
      child: ActiveTaskCard(
        task: TaskStatus(
          taskId: "skeleton",
          status: "loading",
          progress: showProgress ? 45 : 0,
          message: message,
          timestamp: DateTime.now(),
        ),
        // onCancel: () {},
        message: message,
      ),
    );
  }

  Widget _buildFailedTaskCard(String error) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.error, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: AppColors.error, size: 32.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Failed',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                Text(
                  error,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(homeProvider.notifier).cancelTask();
            },
            child: Text('Dismiss', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.error, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 32.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              error,
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(homeProvider.notifier).cancelTask();
            },
            child: Text('Dismiss', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // Check if a task is currently processing
    final homeState = ref.read(homeProvider);
    bool isTaskProcessing = false;

    homeState.when(
      data: (state) {
        // Check if task is processing
        isTaskProcessing = state.maybeWhen(
          taskProcessing: (_, _, _, _) => true,
          orElse: () => false,
        );
      },
      loading: () => isTaskProcessing = false,
      error: (_, _) => isTaskProcessing = false,
    );

    if (isTaskProcessing) {
      CustomSnackbar.warning(
        context: context,
        message: 'A task is already in progress. Please wait...',
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      var res = await ref.read(homeProvider.notifier).predict(query: query);
      // ignore: use_build_context_synchronously
      CustomSnackbar.info(context: context, message: res.message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _cancelTask() {
    ref.read(homeProvider.notifier).cancelTask();
  }

  void _handleNewsTap(News news) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening: ${news.title}'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  void _handleRecentSearchTap(String query) {
    _searchController.text = query;
    _handleSearch();
  }
}
