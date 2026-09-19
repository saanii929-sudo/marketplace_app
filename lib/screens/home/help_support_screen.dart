import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/chat/chat_controllers.dart';
import '../../features/chat/chat_models.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/app_badge.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/cards/settings_tile.dart';
import '../../widgets/overlays/app_toast.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';
import 'chat_screen.dart';

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

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _startingChat = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _chatWithUs() async {
    if (_startingChat) return;
    setState(() => _startingChat = true);
    try {
      final conversation = await ref.read(chatApiProvider).startConversation(kind: 'customer_support');
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conversation.id, title: 'Support')));
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t start a chat right now. Please try again.',
        tone: AppToastTone.error,
      );
    } finally {
      if (mounted) setState(() => _startingChat = false);
    }
  }

  Future<void> _contactTap(SupportContact contact) async {
    final uri = contact.isEmail
        ? Uri(scheme: 'mailto', path: contact.value)
        : contact.isPhone
        ? Uri(scheme: 'tel', path: contact.value)
        : null;
    if (uri == null) {
      AppToast.show(context, contact.value);
      return;
    }
    try {
      await launchUrl(uri);
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, contact.value);
    }
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
              child: SettingsTile(
                icon: Icons.chat_bubble_outline,
                label: 'Chat with us',
                trailing: _startingChat
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : null,
                onTap: _chatWithUs,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ref
                .watch(supportContactsProvider)
                .when(
                  loading: () => const ShimmerBox(width: double.infinity, height: 96, borderRadius: AppRadius.lg),
                  error: (error, _) => ErrorState(
                    title: 'Something went wrong',
                    message: error is ApiException ? error.message : 'Couldn\'t load our contact details.',
                    onRetry: () => ref.invalidate(supportContactsProvider),
                  ),
                  data: (contacts) => contacts.isEmpty
                      ? const SizedBox.shrink()
                      : AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (var i = 0; i < contacts.length; i++) ...[
                                SettingsTile(
                                  icon: contacts[i].isEmail
                                      ? Icons.mail_outline
                                      : contacts[i].isPhone
                                      ? Icons.phone_outlined
                                      : Icons.info_outline,
                                  label: contacts[i].label.isNotEmpty ? contacts[i].label : contacts[i].value,
                                  onTap: () => _contactTap(contacts[i]),
                                ),
                                if (i < contacts.length - 1) const Divider(height: 1),
                              ],
                            ],
                          ),
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
