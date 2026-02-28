import 'dart:async';
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
  var fakeProducts = <FakeProduct>[].obs;
  var categories = <String>[].obs;
  var currentTabIndex = 0.obs;

  // ── Bottom tab ───────────────────────────────────────────────────────────────
  var currentBottomTab = 0.obs;
  late PageController feedPageController;
  late ScrollController tabScrollController;
  final List<GlobalKey> tabKeys = List.generate(10, (index) => GlobalKey());

  // ── Hero Banner ──────────────────────────────────────────────────────────────
  late PageController bannerPageController;
  var currentBannerPage = 0.obs;
  Timer? _bannerTimer;

  // ── Flash Sale Countdown ─────────────────────────────────────────────────────
  var flashSaleHours = 12.obs;
  var flashSaleMinutes = 36.obs;
  var flashSaleSeconds = 30.obs;
  Timer? _countdownTimer;

  // ── Section product helpers ───────────────────────────────────────────────────
  List<FakeProduct> get flashSaleProducts => fakeProducts.length >= 6
      ? fakeProducts.sublist(0, 6)
      : fakeProducts.toList();

  List<FakeProduct> get dailyDealsProducts => fakeProducts.length >= 9
      ? fakeProducts.sublist(3, 9)
      : fakeProducts.toList();

  List<FakeProduct> get popularCategoryProducts => fakeProducts.length >= 12
      ? fakeProducts.sublist(0, 12)
      : fakeProducts.toList();

  List<FakeProduct> get forYouProducts {
    switch (currentBottomTab.value) {
      case 1: // Hot Deals
        return fakeProducts.length >= 10
            ? fakeProducts.sublist(0, 10)
            : fakeProducts.toList();
      case 2: // Voucher Max
        return fakeProducts.length >= 8
            ? fakeProducts.sublist(
                4,
                12 > fakeProducts.length ? fakeProducts.length : 12,
              )
            : fakeProducts.toList();
      case 3: // Daraz Lo
        return fakeProducts.length >= 6
            ? fakeProducts.sublist(
                2,
                8 > fakeProducts.length ? fakeProducts.length : 8,
              )
            : fakeProducts.toList();
      default: // For You
        return fakeProducts.toList();
    }
  }

  // ── Tab controller ───────────────────────────────────────────────────────────
  TabController? tabController;

  // ── Horizontal swipe animation ───────────────────────────────────────────────
  late AnimationController dragAnimationController;
  var dragOffset = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    bannerPageController = PageController();
    feedPageController = PageController();
    tabScrollController = ScrollController();
    dragAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    fetchFakeProducts();
    _startCountdown();
  }

  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final next = (currentBannerPage.value + 1) % 3;
      currentBannerPage.value = next;
      if (bannerPageController.hasClients) {
        bannerPageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (flashSaleSeconds.value > 0) {
        flashSaleSeconds.value--;
      } else if (flashSaleMinutes.value > 0) {
        flashSaleMinutes.value--;
        flashSaleSeconds.value = 59;
      } else if (flashSaleHours.value > 0) {
        flashSaleHours.value--;
        flashSaleMinutes.value = 59;
        flashSaleSeconds.value = 59;
      }
    });
  }

  // ── GET: Fetch all fake products ────────────────────────────────────────────
  Future<void> fetchFakeProducts({int limit = 20}) async {
    isLoadingFakeProducts.value = true;
    final result = await FakestoreService.getFakeProducts(limit: limit);
    fakeProducts.value = result;
    final seen = <String>{};
    categories.value = result.map((p) => p.category).where(seen.add).toList();
    currentTabIndex.value = 0;
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
    _startBannerAutoScroll();
  }

  // ── Pull-to-refresh ─────────────────────────────────────────────────────────
  Future<void> onRefresh() async {
    isRefreshing.value = true;
    await fetchFakeProducts();
    isRefreshing.value = false;
  }

  // ── Tab ─────────────────────────────────────────────────────────────────────
  void onTabTapped(int index) {
    if (index == currentTabIndex.value) return;
    currentTabIndex.value = index;
  }

  void onBottomTabTapped(int index) {
    if (index == currentBottomTab.value) return;
    currentBottomTab.value = index;
    if (feedPageController.hasClients) {
      feedPageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    _scrollToTab(index);
  }

  void onFeedPageChanged(int index) {
    currentBottomTab.value = index;
    _scrollToTab(index);
  }

  void _scrollToTab(int index) {
    if (index >= 0 && index < tabKeys.length) {
      final context = tabKeys[index].currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  List<FakeProduct> getProductsByTab(int tabIndex) {
    switch (tabIndex) {
      case 1: // Hot Deals - 70% off ones
        return fakeProducts.where((p) => discountPercent(p) >= 60).toList();
      case 2: // Voucher Max
        return fakeProducts.where((p) => p.id % 2 == 0).toList();
      case 3: // Daraz Lo
        return fakeProducts.reversed.toList();
      case 4: // Beauty
        return fakeProducts.where((p) => p.category == 'jewelery').toList();
      case 5: // Fashion
        return fakeProducts
            .where((p) => p.category.contains('clothing'))
            .toList();
      case 6: // Electronics
        return fakeProducts.where((p) => p.category == 'electronics').toList();
      case 7: // Jewelry
        return fakeProducts.where((p) => p.category == 'jewelery').toList();
      case 8: // Men's Clothing
        return fakeProducts
            .where((p) => p.category == "men's clothing")
            .toList();
      case 9: // Women's Clothing
        return fakeProducts
            .where((p) => p.category == "women's clothing")
            .toList();
      default: // For You
        return fakeProducts.toList();
    }
  }

  // ── Fake discount % seeded by product id ────────────────────────────────────
  int discountPercent(FakeProduct p) {
    final discounts = [
      36,
      70,
      58,
      67,
      66,
      48,
      72,
      65,
      55,
      40,
      80,
      35,
      60,
      45,
      50,
    ];
    return discounts[p.id % discounts.length];
  }

  double originalPrice(FakeProduct p) {
    final disc = discountPercent(p);
    return p.price / (1 - disc / 100);
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
    _bannerTimer?.cancel();
    _countdownTimer?.cancel();
    bannerPageController.dispose();
    feedPageController.dispose();
    tabScrollController.dispose();
    tabController?.dispose();
    dragAnimationController.dispose();
    super.onClose();
  }
}
