import 'package:flutter/material.dart';
import 'package:mobile/features/track/data/model/price_tracking_model.dart';
// import '../models/price_tracking_model.dart';

class DummyPriceData {
  static List<PriceHistory> getPriceHistory() {
    return [
      PriceHistory(date: DateTime.now().subtract(const Duration(days: 6)), price: 650000, platform: 'jumia'),
      PriceHistory(date: DateTime.now().subtract(const Duration(days: 5)), price: 640000, platform: 'jumia'),
      PriceHistory(date: DateTime.now().subtract(const Duration(days: 4)), price: 620000, platform: 'jumia'),
      PriceHistory(date: DateTime.now().subtract(const Duration(days: 3)), price: 600000, platform: 'jumia'),
      PriceHistory(date: DateTime.now().subtract(const Duration(days: 2)), price: 580000, platform: 'jumia'),
      PriceHistory(date: DateTime.now().subtract(const Duration(days: 1)), price: 550000, platform: 'jumia'),
      PriceHistory(date: DateTime.now(), price: 530000, platform: 'jumia'),
    ];
  }

  static List<TrackedProduct> getJumiaTrackedProducts() {
    return [
      TrackedProduct(
        id: '1',
        productName: 'iPhone 15 Pro Max',
        targetPrice: 1200000,
        currentPrice: 1150000,
        platform: 'jumia',
        imageUrl: 'https://picsum.photos/200/200?random=1',
        priceDifference: 50000,
        isTargetReached: false,
        lastChecked: DateTime.now(),
        priceHistory: getPriceHistory(),
      ),
      TrackedProduct(
        id: '2',
        productName: 'Samsung Galaxy S24 Ultra',
        targetPrice: 1100000,
        currentPrice: 1250000,
        platform: 'jumia',
        imageUrl: 'https://picsum.photos/200/200?random=2',
        priceDifference: -150000,
        isTargetReached: false,
        lastChecked: DateTime.now(),
        priceHistory: getPriceHistory(),
      ),
      TrackedProduct(
        id: '3',
        productName: 'MacBook Pro M3',
        targetPrice: 2200000,
        currentPrice: 2150000,
        platform: 'jumia',
        imageUrl: 'https://picsum.photos/200/200?random=3',
        priceDifference: 50000,
        isTargetReached: true,
        lastChecked: DateTime.now(),
        priceHistory: getPriceHistory(),
      ),
    ];
  }

  static List<TrackedProduct> getKongaTrackedProducts() {
    return [
      TrackedProduct(
        id: '4',
        productName: 'Sony WH-1000XM5',
        targetPrice: 350000,
        currentPrice: 320000,
        platform: 'konga',
        imageUrl: 'https://picsum.photos/200/200?random=4',
        priceDifference: 30000,
        isTargetReached: true,
        lastChecked: DateTime.now(),
        priceHistory: getPriceHistory(),
      ),
      TrackedProduct(
        id: '5',
        productName: 'iPad Pro 12.9"',
        targetPrice: 950000,
        currentPrice: 980000,
        platform: 'konga',
        imageUrl: 'https://picsum.photos/200/200?random=5',
        priceDifference: -30000,
        isTargetReached: false,
        lastChecked: DateTime.now(),
        priceHistory: getPriceHistory(),
      ),
    ];
  }

  static List<TrackedProduct> getJijiTrackedProducts() {
    return [
      TrackedProduct(
        id: '6',
        productName: 'Google Pixel 8 Pro',
        targetPrice: 750000,
        currentPrice: 680000,
        platform: 'jiji',
        imageUrl: 'https://picsum.photos/200/200?random=6',
        priceDifference: 70000,
        isTargetReached: true,
        lastChecked: DateTime.now(),
        priceHistory: getPriceHistory(),
      ),
      TrackedProduct(
        id: '7',
        productName: 'Nintendo Switch OLED',
        targetPrice: 350000,
        currentPrice: 380000,
        platform: 'jiji',
        imageUrl: 'https://picsum.photos/200/200?random=7',
        priceDifference: -30000,
        isTargetReached: false,
        lastChecked: DateTime.now(),
        priceHistory: getPriceHistory(),
      ),
    ];
  }

  static List<BestDeal> getBestDeals() {
    return [
      BestDeal(
        id: '1',
        productName: 'iPhone 15 Pro Max - Best Deal on Jumia',
        price: 1150000,
        platform: 'jumia',
        imageUrl: 'https://picsum.photos/200/200?random=1',
        rating: 4.8,
        reviewCount: 1245,
        productUrl: 'https://jumia.com/iphone-15-pro-max',
        savings: 50000,
        savingsPercentage: 4.2,
      ),
      BestDeal(
        id: '2',
        productName: 'Sony WH-1000XM5 - Best Deal on Konga',
        price: 320000,
        platform: 'konga',
        imageUrl: 'https://picsum.photos/200/200?random=4',
        rating: 4.7,
        reviewCount: 892,
        productUrl: 'https://konga.com/sony-wh-1000xm5',
        savings: 30000,
        savingsPercentage: 8.6,
      ),
      BestDeal(
        id: '3',
        productName: 'Google Pixel 8 Pro - Best Deal on Jiji',
        price: 680000,
        platform: 'jiji',
        imageUrl: 'https://picsum.photos/200/200?random=6',
        rating: 4.6,
        reviewCount: 567,
        productUrl: 'https://jiji.com/google-pixel-8-pro',
        savings: 70000,
        savingsPercentage: 9.3,
      ),
    ];
  }

  static List<PlatformTracking> getPlatformTracking() {
    return [
      PlatformTracking(
        platform: 'jumia',
        products: getJumiaTrackedProducts(),
        activeAlerts: 5,
        triggeredAlerts: 2,
        platformColor: Colors.orange,
        platformIcon: Icons.shopping_bag,
      ),
      PlatformTracking(
        platform: 'konga',
        products: getKongaTrackedProducts(),
        activeAlerts: 3,
        triggeredAlerts: 1,
        platformColor: Colors.red,
        platformIcon: Icons.store,
      ),
      PlatformTracking(
        platform: 'jiji',
        products: getJijiTrackedProducts(),
        activeAlerts: 4,
        triggeredAlerts: 1,
        platformColor: Colors.green,
        platformIcon: Icons.shop,
      ),
    ];
  }
}