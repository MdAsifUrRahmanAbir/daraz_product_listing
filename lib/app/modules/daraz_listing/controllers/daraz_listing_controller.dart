import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/fakestore_service.dart';

class DarazListingController extends GetxController
    with GetSingleTickerProviderStateMixin {
  var isLoadingCategories = true.obs;
  var isLoadingProducts = true.obs;
  var isRefreshing = false.obs;

  var categories = <String>[].obs;
  var products = <String, List<Product>>{}.obs; // category -> products

  var currentTabIndex = 0.obs;
  var user = Rxn<UserModel>();

  // For horizontal swipe animation
  late AnimationController dragAnimationController;
  var dragOffset = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    dragAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initData();
  }

  Future<void> _initData() async {
    await fetchCategories();
    if (categories.isNotEmpty) {
      await fetchProductsForCategory(categories[currentTabIndex.value]);
    }
    await _loginAndProfile();
  }

  Future<void> fetchCategories() async {
    isLoadingCategories.value = true;
    final cats = await FakestoreService.getCategories();
    // Use first 3 categories for tabs
    categories.value = cats.take(3).toList();
    isLoadingCategories.value = false;
  }

  Future<void> fetchProductsForCategory(String category) async {
    if (products.containsKey(category) &&
        products[category]!.isNotEmpty &&
        !isRefreshing.value) {
      return;
    }
    isLoadingProducts.value = true;
    final items = await FakestoreService.getProductsByCategory(category);
    products[category] = items;
    isLoadingProducts.value = false;
  }

  Future<void> onRefresh() async {
    isRefreshing.value = true;
    if (categories.isNotEmpty) {
      await fetchProductsForCategory(categories[currentTabIndex.value]);
    }
    isRefreshing.value = false;
  }

  void onTabTapped(int index) {
    if (index == currentTabIndex.value) return;
    currentTabIndex.value = index;
    fetchProductsForCategory(categories[index]);
  }

  void handleHorizontalDragUpdate(DragUpdateDetails details) {
    // Only allow drag if we have multiple tabs
    if (categories.isEmpty) return;

    dragOffset.value += details.delta.dx;
  }

  void handleHorizontalDragEnd(DragEndDetails details, double screenWidth) {
    if (categories.isEmpty) return;

    final velocity = details.primaryVelocity ?? 0;
    final offset = dragOffset.value;

    // Determine if we should switch tab
    bool shouldSwitchLeft = (offset > screenWidth / 3) || (velocity > 300);
    bool shouldSwitchRight = (offset < -screenWidth / 3) || (velocity < -300);

    int targetIndex = currentTabIndex.value;

    if (shouldSwitchLeft && currentTabIndex.value > 0) {
      targetIndex--;
    } else if (shouldSwitchRight &&
        currentTabIndex.value < categories.length - 1) {
      targetIndex++;
    }

    // Animate to final position
    double targetOffset = 0;
    if (targetIndex < currentTabIndex.value) {
      targetOffset = screenWidth;
    } else if (targetIndex > currentTabIndex.value) {
      targetOffset = -screenWidth;
    } else {
      targetOffset = 0;
    }

    final simulation = Tween<double>(begin: offset, end: targetOffset).animate(
      CurvedAnimation(parent: dragAnimationController, curve: Curves.easeOut),
    );

    simulation.addListener(() {
      dragOffset.value = simulation.value;
    });

    simulation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (targetIndex != currentTabIndex.value) {
          currentTabIndex.value = targetIndex;
          fetchProductsForCategory(categories[targetIndex]);
        }
        dragOffset.value = 0.0;
        dragAnimationController.reset();
      }
    });

    dragAnimationController.forward(from: 0.0);
  }

  Future<void> _loginAndProfile() async {
    // Fakestore credentials
    final token = await FakestoreService.login('mor_2314', '83r5^_');
    if (token != null) {
      // Fake profile fetch
      final userModel = await FakestoreService.getProfile(2);
      user.value = userModel;
    }
  }

  @override
  void onClose() {
    dragAnimationController.dispose();
    super.onClose();
  }
}
