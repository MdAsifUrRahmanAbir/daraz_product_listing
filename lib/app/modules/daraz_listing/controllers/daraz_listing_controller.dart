import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/fakestore_service.dart';
import '../model/fake_product_model.dart';

class DarazListingController extends GetxController
    with GetTickerProviderStateMixin {
  // ── Loading states ──────────────────────────────────────────────────────────
  var isLoadingFakeProducts = true.obs;
  var isRefreshing = false.obs;

  // ── Data ────────────────────────────────────────────────────────────────────
  /// All products fetched from [FakestoreService.fakeProductsGetUrl]
  var fakeProducts = <FakeProduct>[].obs;

  /// Unique categories derived from [fakeProducts]
  var categories = <String>[].obs;

  var currentTabIndex = 0.obs;

  // ── Tab controller (created once, lives in the controller) ──────────────────
  TabController? tabController;

  // ── Horizontal swipe animation ───────────────────────────────────────────────
  late AnimationController dragAnimationController;
  var dragOffset = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    dragAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    fetchFakeProducts();
  }

  // ── GET: Fetch all fake products ────────────────────────────────────────────
  Future<void> fetchFakeProducts({int limit = 20}) async {
    isLoadingFakeProducts.value = true;
    final result = await FakestoreService.getFakeProducts(limit: limit);
    fakeProducts.value = result;
    // Build unique category list preserving insertion order
    final seen = <String>{};
    categories.value = result.map((p) => p.category).where(seen.add).toList();
    currentTabIndex.value = 0;
    // Recreate TabController with the correct tab count
    tabController?.dispose();
    tabController = TabController(
      length: categories.length,
      vsync: this,
      initialIndex: 0,
    );
    tabController!.addListener(() {
      if (!tabController!.indexIsChanging) {
        currentTabIndex.value = tabController!.index;
      }
    });
    isLoadingFakeProducts.value = false;
  }

  // ── Pull-to-refresh ─────────────────────────────────────────────────────────
  Future<void> onRefresh() async {
    isRefreshing.value = true;
    await fetchFakeProducts();
    isRefreshing.value = false;
  }

  // ── Tab tapped ───────────────────────────────────────────────────────────────
  void onTabTapped(int index) {
    if (index == currentTabIndex.value) return;
    currentTabIndex.value = index;
  }

  // ── Horizontal drag ──────────────────────────────────────────────────────────
  void handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (categories.isEmpty) return;
    dragOffset.value += details.delta.dx;
  }

  void handleHorizontalDragEnd(DragEndDetails details, double screenWidth) {
    if (categories.isEmpty) return;

    final velocity = details.primaryVelocity ?? 0;
    final offset = dragOffset.value;

    bool shouldSwitchLeft = (offset > screenWidth / 3) || (velocity > 300);
    bool shouldSwitchRight = (offset < -screenWidth / 3) || (velocity < -300);

    int targetIndex = currentTabIndex.value;

    if (shouldSwitchLeft && currentTabIndex.value > 0) {
      targetIndex--;
    } else if (shouldSwitchRight &&
        currentTabIndex.value < categories.length - 1) {
      targetIndex++;
    }

    double targetOffset = 0;
    if (targetIndex < currentTabIndex.value) {
      targetOffset = screenWidth;
    } else if (targetIndex > currentTabIndex.value) {
      targetOffset = -screenWidth;
    }

    final simulation = Tween<double>(begin: offset, end: targetOffset).animate(
      CurvedAnimation(parent: dragAnimationController, curve: Curves.easeOut),
    );

    simulation.addListener(() => dragOffset.value = simulation.value);

    simulation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (targetIndex != currentTabIndex.value) {
          currentTabIndex.value = targetIndex;
        }
        dragOffset.value = 0.0;
        dragAnimationController.reset();
      }
    });

    dragAnimationController.forward(from: 0.0);
  }

  @override
  void onClose() {
    tabController?.dispose();
    dragAnimationController.dispose();
    super.onClose();
  }
}
