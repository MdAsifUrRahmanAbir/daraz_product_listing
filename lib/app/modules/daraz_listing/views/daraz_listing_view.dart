import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/daraz_listing_controller.dart';
import 'widgets/sticky_tab_bar_delegate.dart';
import '../../../data/models/product_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DarazListingView extends GetView<DarazListingController> {
  const DarazListingView({super.key});

  @override
  Widget build(BuildContext context) {
    // We get screen width for drag thresholds
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingCategories.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }

          return GestureDetector(
            // Catch horizontal drags for the entire scrollable area
            onHorizontalDragUpdate: controller.handleHorizontalDragUpdate,
            onHorizontalDragEnd: (details) =>
                controller.handleHorizontalDragEnd(details, screenWidth),
            child: RefreshIndicator(
              onRefresh: controller.onRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 1. Collapsible Header (Daraz Banner / Search)
                  SliverAppBar(
                    expandedHeight: 200.0,
                    pinned: true,
                    floating: false,
                    flexibleSpace: FlexibleSpaceBar(
                      title: const Text('Daraz Style'),
                      background: Image.network(
                        'https://fakestoreapi.com/icons/logo.png', // Or some banner
                        fit: BoxFit.contain,
                        color: Colors.white.withValues(alpha: 0.1),
                        colorBlendMode: BlendMode.darken,
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.person),
                        onPressed: () {
                          if (controller.user.value != null) {
                            Get.snackbar(
                              'Profile',
                              'Logged in as ${controller.user.value!.username}',
                            );
                          } else {
                            Get.snackbar('Profile', 'Not logged in yet');
                          }
                        },
                      ),
                    ],
                  ),

                  // 2. Sticky Tab Bar
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: StickyTabBarDelegate(
                      TabBar(
                        isScrollable: true,
                        controller: TabController(
                          length: controller.categories.length,
                          vsync: controller,
                          initialIndex: controller.currentTabIndex.value,
                        ),
                        onTap: controller.onTabTapped,
                        tabs: controller.categories
                            .map((cat) => Tab(text: cat.toUpperCase()))
                            .toList(),
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),

                  // 3. Grid of Products for the Active Category
                  if (controller.isLoadingProducts.value)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    _buildAnimatedProductGrid(context, screenWidth),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAnimatedProductGrid(BuildContext context, double screenWidth) {
    if (controller.categories.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    final currentCategory =
        controller.categories[controller.currentTabIndex.value];
    final products = controller.products[currentCategory] ?? [];

    if (products.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text("No products.")),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(8.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
        ),
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          final product = products[index];
          return AnimatedBuilder(
            animation: controller.dragAnimationController,
            builder: (context, child) {
              // Determine horizontal offset for this item
              double dx = controller.dragOffset.value;
              return Transform.translate(
                offset: Offset(dx, 0),
                child: _ProductCard(product: product),
              );
            },
          );
        }, childCount: products.length),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: CachedNetworkImage(
                imageUrl: product.image,
                fit: BoxFit.contain,
                width: double.infinity,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product.price}',
                  style: const TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    Text(
                      ' ${product.rating.rate} (${product.rating.count})',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
