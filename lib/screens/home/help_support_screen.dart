import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/app_badge.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/cards/settings_tile.dart';
import '../../widgets/overlays/app_toast.dart';

class _Faq {
  const _Faq(this.question, this.answer);
  final String question;
  final String answer;
}

const _topics = ['Orders', 'Payments', 'Returns', 'Account', 'Sellers'];

const _faqs = [
  _Faq(
    'How do I track my order?',
    'Open My orders from your profile and tap any order to see its live status and delivery timeline.',
  ),
  _Faq(
    "What's your return policy?",
    'Most items can be returned within 7 days of delivery, unworn and in original packaging. Refunds are issued to your original payment method.',
  ),
  _Faq(
    'How do sellers get verified?',
    'Every seller submits a business name, category and phone number, and is reviewed by our team within 2 business days before going live.',
  ),
  _Faq(
    'Which payment methods are supported?',
    'We accept Visa and Mastercard, plus MTN MoMo and other mobile money wallets at checkout.',
  ),
  _Faq(
    'How long does delivery take?',
    'Most orders arrive within 2-4 business days, depending on your location and the seller.',
  ),
];

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _query.trim().isEmpty
        ? _faqs
        : _faqs
              .where(
                (f) => f.question.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();

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
                    Text('Help & support', style: AppTypography.h2),
                    Text(
                      "We're here seven days a week",
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.neutral500,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      style: AppTypography.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Search help articles',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.neutral400,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < _topics.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    AppChip(
                      label: _topics[i],
                      selected: false,
                      onTap: () => AppToast.show(context, _topics[i]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Frequently asked', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            if (filteredFaqs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'No help articles match "$_query"',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
              )
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < filteredFaqs.length; i++) ...[
                      _FaqTile(faq: filteredFaqs[i]),
                      if (i < filteredFaqs.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            Text('Contact us', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SettingsTile(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat with us',
                    onTap: () =>
                        AppToast.show(context, 'Live chat coming soon'),
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    icon: Icons.mail_outline,
                    label: 'Email support',
                    onTap: () =>
                        AppToast.show(context, 'support@sporttech.com'),
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    icon: Icons.phone_outlined,
                    label: 'Call us',
                    onTap: () => AppToast.show(context, '+233 000 000 000'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.faq});
  final _Faq faq;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.faq.question,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.faq.answer,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
