// lib/services/cart_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/cart.dart';

class CartService {
  // Base method (given in the handout) — kept for reference / admin use.
  Future<List<Cart>> getAllCarts() async {
    final response = await http.get(Uri.parse('$apiBase/carts'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      return cartsJson.map((json) => Cart.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load carts');
    }
  }

  Future<Cart?> getCartByUserId(int userId) async {
    final response = await http.get(Uri.parse('$apiBase/carts/user/$userId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];

      if (cartsJson.isEmpty) return null;

      // Only render the one cart that belongs to this user.
      return Cart.fromJson(cartsJson.first);
    } else {
      throw Exception('Failed to load cart for user $userId');
    }
  }

  Future<Cart> addToCart({
    required int userId,
    required List<Map<String, dynamic>> products,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBase/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'products': products}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Cart.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add product to cart');
    }
  }
}
