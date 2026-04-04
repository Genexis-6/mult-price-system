import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/share/data/model/product_model.dart';
import 'package:mobile/core/share/ui/widgets/custom_scafold.dart';
import 'package:mobile/core/share/ui/widgets/custom_snack_bar.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/features/home/application/provider/home_provider.dart';
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
                  isLoading: _isLoading,
                ),
                ActiveTaskCard(
                  task: DummyData.getActiveTask(),
                  onCancel: _cancelTask,
                ),
                NewsCarousel(
                  newsList: DummyData.getNews(),
                  onNewsTap: _handleNewsTap,
                ),
                RecentSearchesChips(
                  searches: DummyData.getRecentSearches(),
                  onSearchTap: _handleRecentSearchTap,
                ),
                // FeaturedProductsList(
                //   products: DummyData.getFeaturedProducts(),
                //   onProductTap: _handleProductTap,
                // ),
                SizedBox(height: 20.h),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSearch() async{
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    try{
      setState(() => _isLoading = true);

      var res = await ref.read(homeProvider.notifier).predict(query: query);
      // ignore: use_build_context_synchronously
      CustomSnackbar.info(context: context, message: res.message);

    }finally{
      setState(() => _isLoading = false);
    }
  }

  void _cancelTask() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Task cancelled'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  void _handleNewsTap(News news) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening: ${news.title}'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleRecentSearchTap(String query) {
    _searchController.text = query;
    _handleSearch();
  }

  void _handleProductTap(Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing: ${product.name}'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
