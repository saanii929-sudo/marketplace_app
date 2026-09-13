double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productSlug,
    required this.variantId,
    required this.variantLabel,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
  });

  final int id;
  final int productId;
  final String productName;
  final String productSlug;
  final int? variantId;
  final String? variantLabel;
  final int qty;
  final double unitPrice;
  final double lineTotal;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] as int,
    productId: json['product'] as int,
    productName: json['product_name'] as String? ?? '',
    productSlug: json['product_slug'] as String? ?? '',
    variantId: json['variant'] as int?,
    variantLabel: json['variant_label'] as String?,
    qty: json['qty'] as int? ?? 1,
    unitPrice: _num(json['unit_price']),
    lineTotal: _num(json['line_total']),
  );
}

class Cart {
  const Cart({
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.deliveryFee,
    required this.total,
    required this.couponCode,
    required this.couponError,
  });

  final List<CartItem> items;
  final double subtotal;
  final double discountAmount;
  final double deliveryFee;
  final double total;
  final String? couponCode;
  final String? couponError;

  int get itemCount => items.fold(0, (sum, item) => sum + item.qty);

  bool hasProduct(int productId) => items.any((item) => item.productId == productId);

  static const empty = Cart(
    items: [],
    subtotal: 0,
    discountAmount: 0,
    deliveryFee: 0,
    total: 0,
    couponCode: null,
    couponError: null,
  );

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
    items: (json['items'] as List<dynamic>? ?? []).map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList(),
    subtotal: _num(json['subtotal']),
    discountAmount: _num(json['discount_amount']),
    deliveryFee: _num(json['delivery_fee']),
    total: _num(json['total']),
    couponCode: json['coupon_code'] as String?,
    couponError: json['coupon_error'] as String?,
  );
}
