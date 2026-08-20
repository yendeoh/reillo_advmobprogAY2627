import 'package:flutter_dotenv/flutter_dotenv.dart';

// HOST already includes the /products path, e.g. https://dummyjson.com/products
var host = dotenv.env['HOST'];

// Derived base API URL (without /products) so we can call other dummyjson endpoints like /carts and /carts/add using the same .env value, instead of needing a second HOST variable.
String get apiBase =>
    (host ?? 'https://dummyjson.com/products').replaceFirst('/products', '');

// dummyjson doesn't have real login for this activity, so we treat this as the "current" logged-in user id for the cart enhancement.
const int currentUserId = 1;
