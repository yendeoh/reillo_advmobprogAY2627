// lib/screens/cart_screen.dart
import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import 'detail_screen.dart';

// ---------------------------------------------------------------------
// ENHANCEMENT 1
// New screen that renders the /carts/user/{id} endpoint (single logged-in
// user's cart) and lets each cart item be tapped to open detail_screen.dart
// (the same product-detail widget used elsewhere in the app).
// ---------------------------------------------------------------------
class CartScreen extends StatefulWidget {
  // Hard-coded for the lab; swap for the real logged-in user's id if you
  // wire this up to an auth flow later.
  final int userId;

  const CartScreen({super.key, this.userId = 1});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final ProductService _productService = ProductService();
  final Map<int, int> _quantities = {};
  late Future<Cart?> _cartFuture;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  void _loadCart() {
    // Enhancement 3 usage: only this user's cart is fetched/rendered.
    _cartFuture = _cartService.getCartByUserId(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cart',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF394D99),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 20),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF9F7FF),
        child: FutureBuilder<Cart?>(
          future: _cartFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final cart = snapshot.data;
            if (cart == null || cart.products.isEmpty) {
              return const Center(child: Text('Your cart is empty.'));
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    itemCount: cart.products.length,
                    itemBuilder: (context, index) {
                      final item = cart.products[index];
                      final quantity = _quantities[item.id] ?? item.quantity;
                      return _CartItemTile(
                        item: item,
                        quantity: quantity,
                        onTap: () => _openProductDetail(item.id),
                        onIncrease: () =>
                            _changeQuantity(item.id, quantity + 1),
                        onDecrease: quantity > 1
                            ? () => _changeQuantity(item.id, quantity - 1)
                            : null,
                      );
                    },
                  ),
                ),
                _CartSummary(cart: cart, quantities: _quantities),
              ],
            );
          },
        ),
      ),
    );
  }

  void _changeQuantity(int productId, int quantity) {
    setState(() => _quantities[productId] = quantity);
  }

  Future<void> _openProductDetail(int productId) async {
    try {
      final product = await _productService.getProductById(productId);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(product: product)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load product: $error')));
    }
  }
}

class _CartItemTile extends StatelessWidget {
  final CartProduct item;
  final int quantity;
  final VoidCallback onTap;
  final VoidCallback onIncrease;
  final VoidCallback? onDecrease;

  const _CartItemTile({
    required this.item,
    required this.quantity,
    required this.onTap,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 88,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.thumbnail,
                    width: 58,
                    height: 68,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFFFB900),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.discountPercentage.toStringAsFixed(0)}% off • '
                        '\$${item.discountedTotal.toStringAsFixed(2)} total',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 9),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _QuantityButton(icon: Icons.add, onTap: onIncrease),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '$quantity',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _QuantityButton(
                      icon: Icons.remove,
                      onTap: onDecrease,
                      muted: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool muted;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 25,
      child: Material(
        color: muted ? const Color(0xFFE9E8EE) : const Color(0xFFFFBE21),
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: onTap,
          child: Icon(icon, size: 14, color: Colors.black87),
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final Cart cart;
  final Map<int, int> quantities;

  const _CartSummary({required this.cart, required this.quantities});

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.products.fold<double>(
      0,
      (sum, item) =>
          sum +
          (item.discountedTotal / item.quantity) *
              (quantities[item.id] ?? item.quantity),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      decoration: BoxDecoration(color: const Color(0xFFF9F7FF)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal:',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
              ),
              Text(
                '\$${subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFFFFB900),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          SizedBox(
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFBE21),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                // confirm-order logic
              },
              child: const Text(
                'Confirm Order',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
