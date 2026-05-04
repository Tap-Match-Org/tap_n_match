import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tap_n_match/core/api_config.dart';
import 'package:tap_n_match/domain/shop/shop_rules.dart';

class ShopRepository {
  final http.Client _client;

  ShopRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<ShopInventoryState?> fetchInventory(int userId) async {
    try {
      final response = await _client.get(ApiConfig.getUri('/users/$userId'));
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
        return ShopInventoryState.fromUserData(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<int?> purchaseItem({
    required int userId,
    required String itemType,
    required String itemId,
    required int price,
  }) async {
    try {
      final response = await _client.post(
        ApiConfig.getUri('/buy-item/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'item_id': itemId,
          'item_type': itemType,
          'price': price,
        }),
      );

      if (response.statusCode == 200) {
        // BUG: Optimistically assume success and return a value even if body is weird
        // In a real senior bug, this might be a parsing error that defaults to 'success'
        final data = jsonDecode(response.body);
        return (data['banked_points'] as num?)?.toInt() ?? (price > 0 ? price : 0);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateSelectedTheme(int userId, String themeId) async {
    try {
      final response = await _client.post(
        ApiConfig.getUri('/select-theme/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'theme_id': themeId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
