import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/daraz_listing_controller.dart';
import 'widgets/sticky_tab_bar_delegate.dart';
import '../model/fake_product_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DarazListingView extends GetView<DarazListingController> {
  const DarazListingView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          // Show full-screen loader while products are loading
          if (controller.isLoadingFakeProducts.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.fakeProducts.isEmpty) {
            return const Center(child: Text('No products found.'));
          }

          return GestureDetector(
            onHorizontalDragUpdate: controller.handleHorizontalDragUpdate,
            onHorizontalDragEnd: (details) =>
                controller.handleHorizontalDragEnd(details, screenWidth),
            child: RefreshIndicator(
              onRefresh: controller.onRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── 1. Collapsible SliverAppBar ──────────────────────────
                  SliverAppBar(
                    expandedHeight: 180.0,
                    pinned: true,
                    floating: false,
                    flexibleSpace: FlexibleSpaceBar(
                      title: const Text(
                        'Daraz Listing',
                        style: TextStyle(fontSize: 16),
                      ),
                      background: ColoredBox(
                        color: Colors.deepOrange.shade50,
                        child: const Center(
                          child: Icon(
                            Icons.store,
                            size: 80,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── 2. Sticky Category Tab Bar ───────────────────────────
                  if (controller.tabController != null)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: StickyTabBarDelegate(
                        TabBar(
                          isScrollable: true,
                          controller: controller.tabController,
                          tabs: controller.categories
                              .map((cat) => Tab(text: cat.toUpperCase()))
                              .toList(),
                          labelColor: Colors.deepOrange,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.deepOrange,
                        ),
                      ),
                    ),

                  // ── 3. Product Grid filtered by active tab ───────────────
                  _buildProductGrid(screenWidth),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProductGrid(double screenWidth) {
    final currentCategory =
        controller.categories[controller.currentTabIndex.value];

    final tabProducts = controller.fakeProducts
        .where((p) => p.category == currentCategory)
        .toList();

    if (tabProducts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('No products in this category.')),
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
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = tabProducts[index];
          return AnimatedBuilder(
            animation: controller.dragAnimationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(controller.dragOffset.value, 0),
                child: _FakeProductCard(product: product),
              );
            },
          );
        }, childCount: tabProducts.length),
      ),
    );
  }
}

// ── Product Card ─────────────────────────────────────────────────────────────
class _FakeProductCard extends StatelessWidget {
  final FakeProduct product;
  const _FakeProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: CachedNetworkImage(
                imageUrl: product.image,
                fit: BoxFit.contain,
                width: double.infinity,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.broken_image),
              ),
            ),
          ),
          // Product info
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
                  '\$${product.price.toStringAsFixed(2)}',
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
