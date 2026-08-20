// lib/screens/cart_screen.dart
import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import '../services/user_service.dart';
import 'detail_screen.dart';

// ENHANCEMENT 3: The cart is requested with the saved User.id, so each signed
// in user sees their own DummyJSON cart instead of a hard-coded cart.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final UserService _userService = UserService();
  late Future<Cart?> _cartFuture;

  @override
  void initState() {
    super.initState();
    _cartFuture = _loadCartForSavedUser();
  }

  Future<Cart?> _loadCartForSavedUser() async {
    final user = await _userService.getUser(); // saved user, Enhancement 3
    return _cartService.getCartByUserId(user.id);
  }

  Future<void> _openProductDetail(
    BuildContext context,
    CartProduct item,
  ) async {
    try {
      final product = await ProductService().getProductById(item.id);
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(product: product)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load product: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text(
          'Your cart',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<Cart?>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load cart: ${snapshot.error}'),
            );
          }
          final cart = snapshot.data;
          if (cart == null || cart.products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.black26,
                  ),
                  SizedBox(height: 12),
                  Text('Your cart is empty.', style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.products.length,
                  itemBuilder: (context, index) {
                    final item = cart.products[index];
                    return _CartItemTile(
                      item: item,
                      onTap: () => _openProductDetail(context, item),
                    );
                  },
                ),
              ),
              _CartSummary(cart: cart),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartProduct item;
  final VoidCallback onTap;

  const _CartItemTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            item.thumbnail,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
          ),
        ),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '\$${item.price.toStringAsFixed(2)}  •  '
          '${item.discountPercentage.toStringAsFixed(0)}% off  •  '
          '\$${item.discountedTotal.toStringAsFixed(2)} total',
        ),
        trailing: Text('x${item.quantity}'),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final Cart cart;
  const _CartSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:'),
              Text('\$${cart.discountedTotal.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {},
            child: const Text('Confirm Order'),
          ),
        ],
      ),
    );
  }
}
