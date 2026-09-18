import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_catalog.dart';
import '../../features/addresses/address.dart';
import '../../features/addresses/addresses_controller.dart';
import '../../features/cart/cart.dart';
import '../../features/cart/cart_controller.dart';
import '../../features/checkout/checkout_controllers.dart';
import '../../features/payments/payment_method.dart';
import '../../features/payments/payments_controller.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/cards/payment_card_logo.dart';
import '../../widgets/states/confirmation_state.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';
import 'add_payment_method_screen.dart';
import 'address_form_screen.dart';
import 'order_detail_screen.dart';

class _DeliveryOption {
  const _DeliveryOption({
    required this.label,
    required this.subtitle,
    required this.price,
  });
  final String label;
  final String subtitle;
  final double price;
}

const _freeDeliveryThreshold = 500.0;
const _expressDeliveryFee = 35.0;

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  /// Selected address/payment method ids, resolved lazily once each real
  /// list loads (defaulting to whichever the account has marked default).
  int? _selectedAddressId;
  int? _selectedPaymentId;
  int _selectedDelivery = 0;
  bool _placingOrder = false;
  bool _orderPlaced = false;
  String _orderId = '';
  List<Product> _orderItems = [];
  double _orderTotal = 0;

  List<_DeliveryOption> _deliveryOptions(double subtotal) => [
    _DeliveryOption(
      label: 'Standard delivery',
      subtitle: '3–5 business days',
      price: subtotal >= _freeDeliveryThreshold ? 0 : 20,
    ),
    const _DeliveryOption(
      label: 'Express delivery',
      subtitle: '1–2 business days',
      price: _expressDeliveryFee,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Always fetch a fresh summary when Checkout opens, rather than reusing
    // a cached read from a previous visit.
    Future.microtask(() => ref.invalidate(checkoutSummaryProvider));
  }

  Future<void> _placeOrder(Cart cart) async {
    setState(() => _placingOrder = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _orderId = 'ST-${10000 + Random().nextInt(90000)}';
      _orderItems = cart.items
          .map(
            (line) => Product(
              id: line.productId.toString(),
              name: line.productName,
              brand: '',
              category: '',
              subcategory: '',
              price: line.unitPrice,
              rating: 0,
              reviewCount: 0,
              icon: Icons.shopping_bag_outlined,
              imageUrl: '',
              description: '',
              slug: line.productSlug,
            ),
          )
          .toList();
      _orderTotal = cart.total;
      _placingOrder = false;
      _orderPlaced = true;
    });
    await ref.read(cartControllerProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartControllerProvider);
    final itemCount = _orderPlaced ? _orderItems.length : (cartAsync.value?.itemCount ?? 0);
    final addressesAsync = ref.watch(addressesControllerProvider);
    addressesAsync.whenData((addresses) {
      if (_selectedAddressId == null && addresses.isNotEmpty) {
        final defaultAddress = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedAddressId = defaultAddress.id);
        });
      }
    });
    final paymentMethodsAsync = ref.watch(paymentMethodsControllerProvider);
    paymentMethodsAsync.whenData((methods) {
      if (_selectedPaymentId == null && methods.isNotEmpty) {
        final defaultMethod = methods.firstWhere((p) => p.isDefault, orElse: () => methods.first);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedPaymentId = defaultMethod.id);
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            Row(
              children: [
                AppBackButton(onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Checkout', style: AppTypography.h2),
                    Text(
                      '$itemCount item${itemCount == 1 ? '' : 's'}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_orderPlaced)
              _OrderPlacedView(
                orderId: _orderId,
                items: _orderItems,
                total: _orderTotal,
              )
            else
              _buildForm(cartAsync, addressesAsync, paymentMethodsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(
    AsyncValue<Cart> cartAsync,
    AsyncValue<List<Address>> addressesAsync,
    AsyncValue<List<PaymentMethod>> paymentMethodsAsync,
  ) {
    final deliveryOptions = _deliveryOptions(cartAsync.value?.subtotal ?? 0);
    final summaryAsync = ref.watch(checkoutSummaryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Delivery address'),
        const SizedBox(height: AppSpacing.sm),
        addressesAsync.when(
          loading: () => const AddressListShimmer(),
          error: (error, _) => ErrorState(
            title: 'Something went wrong',
            message: error is ApiException ? error.message : 'Couldn\'t load your addresses.',
            onRetry: () => ref.read(addressesControllerProvider.notifier).refresh(),
          ),
          data: (addresses) => addresses.isEmpty
              ? _SelectableTile(
                  selected: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddressFormScreen()),
                  ),
                  child: Text('+ Add a delivery address', style: AppTypography.bodyMedium),
                )
              : Column(
                  children: [
                    for (final address in addresses) ...[
                      _SelectableTile(
                        selected: address.id == _selectedAddressId,
                        onTap: () => setState(() => _selectedAddressId = address.id),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(address.label, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(address.fullAddress, style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionLabel('Delivery method'),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < deliveryOptions.length; i++) ...[
          _SelectableTile(
            selected: i == _selectedDelivery,
            onTap: () => setState(() => _selectedDelivery = i),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deliveryOptions[i].label,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        deliveryOptions[i].subtitle,
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  deliveryOptions[i].price == 0
                      ? 'Free*'
                      : formatPrice(deliveryOptions[i].price),
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.lg),
        _SectionLabel('Payment method'),
        const SizedBox(height: AppSpacing.sm),
        paymentMethodsAsync.when(
          loading: () => const ShimmerBox(width: double.infinity, height: 72, borderRadius: AppRadius.lg),
          error: (error, _) => ErrorState(
            title: 'Something went wrong',
            message: error is ApiException ? error.message : 'Couldn\'t load your payment methods.',
            onRetry: () => ref.read(paymentMethodsControllerProvider.notifier).refresh(),
          ),
          data: (methods) => methods.isEmpty
              ? _SelectableTile(
                  selected: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddPaymentMethodScreen()),
                  ),
                  child: Text('+ Add a payment method', style: AppTypography.bodyMedium),
                )
              : Column(
                  children: [
                    for (final method in methods) ...[
                      _SelectableTile(
                        selected: method.id == _selectedPaymentId,
                        onTap: () => setState(() => _selectedPaymentId = method.id),
                        child: Row(
                          children: [
                            PaymentCardLogo(type: method.type),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '•••• ${method.last4}',
                                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(method.subtitle, style: AppTypography.caption),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionLabel('Order summary'),
        const SizedBox(height: AppSpacing.sm),
        summaryAsync.when(
          loading: () => const ShimmerBox(width: double.infinity, height: 140, borderRadius: AppRadius.lg),
          error: (error, _) => ErrorState(
            title: 'Something went wrong',
            message: error is ApiException ? error.message : 'Couldn\'t load your order summary.',
            onRetry: () => ref.invalidate(checkoutSummaryProvider),
          ),
          data: (summary) => AppCard(
            child: Column(
              children: [
                _SummaryRow(label: 'Subtotal', value: formatPrice(summary.subtotal)),
                if (summary.discountAmount > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _SummaryRow(label: 'Discount', value: '-${formatPrice(summary.discountAmount)}'),
                ],
                const SizedBox(height: AppSpacing.sm),
                _SummaryRow(
                  label: 'Delivery',
                  value: summary.deliveryFee == 0 ? 'Free' : formatPrice(summary.deliveryFee),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                _SummaryRow(label: 'Total', value: formatPrice(summary.total), bold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '*Free standard delivery on orders over ${formatPrice(_freeDeliveryThreshold)}.',
          style: AppTypography.caption,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Place order${summaryAsync.value != null ? ' · ${formatPrice(summaryAsync.value!.total)}' : ''}',
          loading: _placingOrder,
          onPressed: (cartAsync.value == null || cartAsync.value!.items.isEmpty)
              ? null
              : () => _placeOrder(cartAsync.value!),
        ),
      ],
    );
  }
}

class _OrderPlacedView extends StatelessWidget {
  const _OrderPlacedView({
    required this.orderId,
    required this.items,
    required this.total,
  });
  final String orderId;
  final List<Product> items;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: ConfirmationState(
              title: 'Order placed',
              message:
                  "Order $orderId is confirmed. We'll email you as soon as it ships.",
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Track this order',
            expand: false,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(
                  orderNumber: orderId,
                  localPreview: LocalOrderPreview(items: items, total: total),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Continue shopping',
            variant: AppButtonVariant.secondary,
            expand: false,
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.label.copyWith(color: AppColors.neutral500),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.selected,
    required this.onTap,
    required this.child,
  });
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? AppColors.neutral100 : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RadioDot(selected: selected),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(top: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.ink : AppColors.neutral300,
          width: 1.5,
        ),
      ),
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? AppTypography.h3
        : AppTypography.bodyMedium.copyWith(color: AppColors.neutral600);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: bold
              ? AppTypography.h3
              : AppTypography.bodyMedium.copyWith(color: AppColors.neutral600),
        ),
        Text(value, style: style),
      ],
    );
  }
}
