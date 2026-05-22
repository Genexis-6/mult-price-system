// home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/share/ui/widgets/reconnect_banner.dart';
import 'package:mobile/features/home/application/provider/recent_searches_provider.dart';
import 'package:mobile/features/home/data/model/task_status_model.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:mobile/core/share/data/model/product_model.dart';
import 'package:mobile/core/share/ui/widgets/custom_snack_bar.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/features/home/application/provider/home_provider.dart';
import 'package:mobile/features/home/data/model/news_model.dart';
import 'package:mobile/features/home/ui/widgets/widgets.dart';
import 'package:mobile/core/utils/logger_utlis.dart';
import '../../../../core/share/application/provider/news_provider.dart';
import '../../../../core/share/ui/widgets/custom_app_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  double _scrollOffset = 0;
  bool _webSocketActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Check if there's an active task and reconnect WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndReconnectIfNeeded();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    // ✅ DO NOT call _disconnectWebSocket() here
    // The HomeProvider.dispose() will clean up the WebSocket automatically
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // ✅ Don't use ref if the widget is not mounted
    if (!mounted) return;
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - reconnect WebSocket if needed
        ref.read(homeProvider.notifier).reconnectWebSocketIfNeeded();
        logger.d('📱 HomeScreen: App resumed, reconnecting WebSocket if needed');
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App went to background - disconnect WebSocket
        ref.read(homeProvider.notifier).disconnectWebSocket();
        logger.d('📱 HomeScreen: App paused, disconnecting WebSocket');
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _checkAndReconnectIfNeeded() {
    final homeState = ref.read(homeProvider);
    homeState.whenData((state) {
      state.maybeWhen(
        reconnecting: (taskId, query) {
          _webSocketActive = true;
          logger.d('HomeScreen: Active task found, WebSocket will be active');
        },
        taskProcessing: (taskId, query, progress, message) {
          _webSocketActive = true;
          logger.d('HomeScreen: Task processing, WebSocket active');
        },
        taskCreated: (taskId, query) {
          _webSocketActive = true;
          logger.d('HomeScreen: Task created, WebSocket active');
        },
        orElse: () {
          _webSocketActive = false;
        },
      );
    });
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
      child: Scaffold(
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

                // Active Task Card
                homeStateAsync.when(
                  data: (state) {
                    _updateWebSocketState(state);
                    
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
                          ReconnectionBanner(taskId: taskId, query: query),
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
                            CustomSnackbar.info(
                              context: context,
                              message: 'Opening ${product.productName}',
                            );
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

                Consumer(
                  builder: (context, ref, child) {
                    final newsAsync = ref.watch(topHeadlinesProvider);

                    return newsAsync.when(
                      data: (newsList) {
                        if (newsList.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return NewsCarousel(
                          newsList: newsList,
                          onNewsTap: _handleNewsTap,
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => const SizedBox.shrink(),
                    );
                  },
                ),
               
                RecentSearchesWidget(onSearchTap: _handleRecentSearchTap),
                SizedBox(height: 20.h),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _updateWebSocketState(dynamic state) {
    state.maybeWhen(
      reconnecting: (_, __) => _webSocketActive = true,
      taskProcessing: (_, __, ___, ____) => _webSocketActive = true,
      taskCreated: (_, __) => _webSocketActive = true,
      orElse: () => _webSocketActive = false,
    );
  }

  Widget _buildSkeletonActiveTaskCard({
    required String message,
    required bool showProgress,
  }) {
    return Skeletonizer(
      enabled: showProgress,
      effect: const ShimmerEffect(
        duration: Duration(seconds: 1),
      ),
      child: ActiveTaskCard(
        task: TaskStatus(
          taskId: "skeleton",
          status: "loading",
          progress: showProgress ? 45 : 0,
          message: message,
          timestamp: DateTime.now(),
        ),
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

    final homeState = ref.read(homeProvider);
    bool isTaskProcessing = false;

    homeState.when(
      data: (state) {
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

      if (res.success) {
        final resultCount = res.data?['result']?.length ?? 0;
        ref
            .read(recentSearchesProvider.notifier)
            .addRecentSearch(query, resultCount: resultCount);
      }

      CustomSnackbar.info(context: context, message: res.message);
    } finally {
      setState(() => _isLoading = false);
    }
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