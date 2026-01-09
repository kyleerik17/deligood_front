class ApiConfig {
  // ==========================
  // BASE URL (LOCAL - CHROME)
  // ==========================
  static const String baseUrl = 'http://127.0.0.1:8000';

  // ==========================
  // AUTH
  // ==========================
  static const String login = '$baseUrl/api/auth/login/';
  static const String register = '$baseUrl/api/auth/register/';

  // ==========================
  // MENU
  // ==========================
  static const String menuItems = '$baseUrl/api/menu/';
  static String menuItemDetail(int id) =>
      '$baseUrl/api/menu/$id/';

  // ==========================
  // PANIER
  // ==========================
  static const String cart = '$baseUrl/api/cart/';
  static const String addToCart = '$baseUrl/api/cart/add/';
  static const String updateCart = '$baseUrl/api/cart/update/';
  static String removeFromCart(int id) =>
      '$baseUrl/api/cart/remove/$id/';

  // ==========================
  // COMMANDES (ORDERS)
  // ==========================
  static const String orders = '$baseUrl/api/orders/';
  static const String createOrder = '$baseUrl/api/orders/create/';
  static const String clientOrders = '$baseUrl/api/orders/client/';
  static String orderDetail(int id) =>
      '$baseUrl/api/orders/$id/';
  static String updateOrderStatus(int id) =>
      '$baseUrl/api/orders/$id/status/';

  // ==========================
  // LIVRAISON
  // ==========================
  static const String deliveredOrders =
      '$baseUrl/api/orders/delivered/';
}
