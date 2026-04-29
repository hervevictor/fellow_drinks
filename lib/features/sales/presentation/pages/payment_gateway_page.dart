import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/sale_model.dart';
import '../../data/repositories/sale_repository.dart';
import '../../providers/sale_provider.dart';

final _currFmt = NumberFormat.currency(
    locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

// ── Payment gateway page ───────────────────────────────────────────────────────
// Receives the already-created SaleModel + handles UI confirmation flow

class PaymentGatewayPage extends ConsumerStatefulWidget {
  final SaleModel sale;
  const PaymentGatewayPage({super.key, required this.sale});

  @override
  ConsumerState<PaymentGatewayPage> createState() =>
      _PaymentGatewayPageState();
}

enum _Step {
  // Mobile money steps
  mobileMoneyProvider,
  mobileMoneyInstructions,
  mobileMoneyReference,
  // Card steps
  cardForm,
  // Final
  receipt,
}

class _PaymentGatewayPageState
    extends ConsumerState<PaymentGatewayPage> {
  late _Step _step;

  // Mobile money
  String _mmProvider = 'flooz'; // flooz | tmoney

  // Card
  final _cardNameCtrl   = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl     = TextEditingController();
  final _cvvCtrl        = TextEditingController();
  final _formKey        = GlobalKey<FormState>();

  // Reference (mobile money)
  final _refCtrl = TextEditingController();

  bool _loading = false;
  late SaleModel _currentSale;

  @override
  void initState() {
    super.initState();
    _currentSale = widget.sale;
    _step = _initialStep();
  }

  _Step _initialStep() {
    return switch (_currentSale.paymentMethod) {
      'mobile_money' => _Step.mobileMoneyProvider,
      'card'         => _Step.cardForm,
      _              => _Step.receipt, // cash → show QR immediately
    };
  }

  @override
  void dispose() {
    _cardNameCtrl.dispose();
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  // ── Submit mobile money reference ──────────────────────────────────────────
  Future<void> _submitMobileMoneyRef() async {
    final ref = _refCtrl.text.trim();
    if (ref.isEmpty) return;
    setState(() => _loading = true);
    try {
      final updated = await SaleRepository().updatePaymentReference(
        saleId:    _currentSale.id,
        reference: ref,
      );
      setState(() {
        _currentSale = updated;
        _step = _Step.receipt;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Submit card payment ────────────────────────────────────────────────────
  Future<void> _submitCard() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    // Simulated processing delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      final last4 = _cardNumberCtrl.text.replaceAll(' ', '').substring(
          _cardNumberCtrl.text.replaceAll(' ', '').length - 4);
      final updated = await ref
          .read(saleCreationProvider.notifier)
          .confirmPayment(
            saleId:           _currentSale.id,
            paymentReference: 'CARD-****$last4',
          );
      if (updated != null && mounted) {
        setState(() {
          _currentSale = updated;
          _step = _Step.receipt;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _Step.receipt,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step != _Step.receipt) {
          setState(() => _step = _previousStep());
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_appBarTitle()),
          leading: _step != _Step.receipt
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    final prev = _previousStep();
                    if (prev == _step) {
                      context.go('/sales');
                    } else {
                      setState(() => _step = prev);
                    }
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.home_outlined),
                  onPressed: () => context.go('/home'),
                ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: AppColors.divider),
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildStep(),
        ),
      ),
    );
  }

  String _appBarTitle() => switch (_step) {
        _Step.mobileMoneyProvider    => 'Mode Mobile Money',
        _Step.mobileMoneyInstructions => 'Instructions de paiement',
        _Step.mobileMoneyReference   => 'Confirmer le paiement',
        _Step.cardForm               => 'Paiement par carte',
        _Step.receipt                => 'Confirmation de commande',
      };

  _Step _previousStep() => switch (_step) {
        _Step.mobileMoneyInstructions => _Step.mobileMoneyProvider,
        _Step.mobileMoneyReference    => _Step.mobileMoneyInstructions,
        _Step.cardForm                => _Step.cardForm,
        _                             => _step,
      };

  Widget _buildStep() {
    return switch (_step) {
      _Step.mobileMoneyProvider    => _MobileMoneyProviderStep(
          key: const ValueKey('mmProvider'),
          selected: _mmProvider,
          onSelected: (p) => setState(() => _mmProvider = p),
          onNext: () =>
              setState(() => _step = _Step.mobileMoneyInstructions),
        ),
      _Step.mobileMoneyInstructions => _MobileMoneyInstructionsStep(
          key: const ValueKey('mmInstructions'),
          provider: _mmProvider,
          amount:   _currentSale.totalAmount,
          onNext: () =>
              setState(() => _step = _Step.mobileMoneyReference),
        ),
      _Step.mobileMoneyReference => _MobileMoneyReferenceStep(
          key: const ValueKey('mmRef'),
          ctrl:    _refCtrl,
          loading: _loading,
          onSubmit: _submitMobileMoneyRef,
        ),
      _Step.cardForm => _CardFormStep(
          key:       const ValueKey('card'),
          formKey:   _formKey,
          nameCtrl:  _cardNameCtrl,
          numCtrl:   _cardNumberCtrl,
          expCtrl:   _expiryCtrl,
          cvvCtrl:   _cvvCtrl,
          amount:    _currentSale.totalAmount,
          loading:   _loading,
          onSubmit:  _submitCard,
        ),
      _Step.receipt => _ReceiptStep(
          key:  const ValueKey('receipt'),
          sale: _currentSale,
        ),
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 1 — Mobile Money : choisir Flooz ou T-Money
// ═══════════════════════════════════════════════════════════════════════════════

class _MobileMoneyProviderStep extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onNext;
  const _MobileMoneyProviderStep({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisissez votre opérateur',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sélectionnez l\'opérateur que vous utilisez pour envoyer le paiement.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _ProviderCard(
            name:     'Flooz',
            subtitle: 'Togocom',
            color:    const Color(0xFF00A859),
            icon:     Icons.phone_android_outlined,
            selected: selected == 'flooz',
            onTap:    () => onSelected('flooz'),
          ),
          const SizedBox(height: 16),
          _ProviderCard(
            name:     'T-Money',
            subtitle: 'Moov Africa',
            color:    const Color(0xFF0066CC),
            icon:     Icons.phone_android_outlined,
            selected: selected == 'tmoney',
            onTap:    () => onSelected('tmoney'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Continuer'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ProviderCard({
    required this.name,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: selected ? color : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 2 — Mobile Money : instructions d'envoi
// ═══════════════════════════════════════════════════════════════════════════════

class _MobileMoneyInstructionsStep extends StatelessWidget {
  final String provider;
  final double amount;
  final VoidCallback onNext;
  const _MobileMoneyInstructionsStep({
    super.key,
    required this.provider,
    required this.amount,
    required this.onNext,
  });

  static const _shopNumber = AppConstants.appPhone;

  @override
  Widget build(BuildContext context) {
    final color = provider == 'flooz'
        ? const Color(0xFF00A859)
        : const Color(0xFF0066CC);
    final providerName = provider == 'flooz' ? 'Flooz' : 'T-Money';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.phone_android_outlined, color: color, size: 40),
                const SizedBox(height: 8),
                Text(
                  'Paiement $providerName',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Amount
          _InfoBlock(
            label: 'Montant à envoyer',
            value: _currFmt.format(amount),
            valueStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Number to send to
          _InfoBlock(
            label: 'Numéro de la boutique',
            value: _shopNumber,
            canCopy: true,
            valueStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Steps
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comment procéder :',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                _Step2Item(n: '1', text: 'Ouvrez votre application $providerName'),
                _Step2Item(n: '2', text: 'Envoyez exactement ${_currFmt.format(amount)} au numéro $_shopNumber'),
                _Step2Item(n: '3', text: 'Notez le code de confirmation reçu par SMS'),
                _Step2Item(n: '4', text: 'Revenez ici et saisissez ce code'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('J\'ai effectué le paiement'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step2Item extends StatelessWidget {
  final String n;
  final String text;
  const _Step2Item({required this.n, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            margin: const EdgeInsets.only(right: 10, top: 1),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(n,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  )),
            ),
          ),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                )),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 3 — Mobile Money : saisir le code de transaction
// ═══════════════════════════════════════════════════════════════════════════════

class _MobileMoneyReferenceStep extends StatelessWidget {
  final TextEditingController ctrl;
  final bool loading;
  final VoidCallback onSubmit;
  const _MobileMoneyReferenceStep({
    super.key,
    required this.ctrl,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Code de confirmation',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Saisissez le code de confirmation reçu par SMS après votre transfert Mobile Money.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
            decoration: const InputDecoration(
              labelText: 'Code de transaction (ex: TXN123456)',
              prefixIcon: Icon(Icons.confirmation_number_outlined),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ce code sera vérifié par la boutique pour confirmer votre paiement.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              child: loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Valider ma commande'),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP CARD — Formulaire carte bancaire
// ═══════════════════════════════════════════════════════════════════════════════

class _CardFormStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController numCtrl;
  final TextEditingController expCtrl;
  final TextEditingController cvvCtrl;
  final double amount;
  final bool loading;
  final VoidCallback onSubmit;
  const _CardFormStep({
    super.key,
    required this.formKey,
    required this.nameCtrl,
    required this.numCtrl,
    required this.expCtrl,
    required this.cvvCtrl,
    required this.amount,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card visual
            Container(
              width: double.infinity,
              height: 180,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A237E).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Fellow Drink',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Icon(Icons.credit_card,
                          color: Colors.white.withValues(alpha: 0.8), size: 28),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    '•••• •••• •••• ••••',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      letterSpacing: 3,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Titulaire',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        _currFmt.format(amount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Nom titulaire
            TextFormField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nom du titulaire',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 14),

            // Numéro carte
            TextFormField(
              controller: numCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CardNumberFormatter(),
              ],
              maxLength: 19,
              decoration: const InputDecoration(
                labelText: 'Numéro de carte',
                prefixIcon: Icon(Icons.credit_card_outlined),
                counterText: '',
              ),
              validator: (v) {
                final digits = (v ?? '').replaceAll(' ', '');
                return digits.length < 16 ? 'Numéro invalide' : null;
              },
            ),
            const SizedBox(height: 14),

            // Expiry + CVV
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: expCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ExpiryFormatter(),
                  ],
                  maxLength: 5,
                  decoration: const InputDecoration(
                    labelText: 'MM/AA',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.length < 5) return 'Invalide';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: cvvCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 3,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    prefixIcon: Icon(Icons.lock_outline),
                    counterText: '',
                  ),
                  validator: (v) =>
                      (v ?? '').length < 3 ? 'Invalide' : null,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            const Text(
              '🔒 Vos informations sont sécurisées et chiffrées.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: loading ? null : onSubmit,
                child: loading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Traitement en cours...'),
                        ],
                      )
                    : Text('Payer ${_currFmt.format(amount)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP FINAL — Reçu + QR code de preuve
// ═══════════════════════════════════════════════════════════════════════════════

class _ReceiptStep extends StatelessWidget {
  final SaleModel sale;
  const _ReceiptStep({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final isPending = sale.isPendingPayment;
    final color     = isPending ? AppColors.warning : AppColors.success;
    final dateFmt   = DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        children: [
          // ── Status banner ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  isPending
                      ? Icons.hourglass_top_outlined
                      : Icons.check_circle_outline,
                  color: color,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  isPending
                      ? 'Commande réservée'
                      : 'Paiement confirmé !',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPending
                      ? 'Présentez ce QR lors du retrait et effectuez le paiement en boutique.'
                      : 'Votre paiement a été reçu. Présentez ce QR lors du retrait.',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── QR Code ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.08),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                QrImageView(
                  data:            sale.qrData,
                  version:         QrVersions.auto,
                  size:            200,
                  eyeStyle:        const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color:    AppColors.textPrimary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color:           AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  sale.receiptNumber,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFmt.format(sale.createdAt.toLocal()),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Résumé commande ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Détails de la commande',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _Row(label: 'Montant',
                    value: _currFmt.format(sale.totalAmount)),
                _Row(label: 'Paiement', value: sale.paymentLabel),
                if (sale.paymentReference != null)
                  _Row(label: 'Référence', value: sale.paymentReference!),
                _Row(
                  label: 'Statut',
                  value: isPending ? 'En attente de confirmation' : 'Validé',
                  valueColor: color,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Buttons ──────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Retour à l\'accueil'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.go('/sales/receipt/${sale.id}'),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Voir le reçu complet'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _Row({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textSecondary,
              )),
          Text(value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}

// ── Info block (copiable) ─────────────────────────────────────────────────────

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final bool canCopy;
  const _InfoBlock({
    required this.label,
    required this.value,
    this.valueStyle,
    this.canCopy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.textSecondary,
              )),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(value,
                    style: valueStyle ??
                        const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
              ),
              if (canCopy)
                IconButton(
                  icon: const Icon(Icons.copy_outlined,
                      size: 18, color: AppColors.primary),
                  tooltip: 'Copier',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Numéro copié !'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Input formatters ──────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final str = buffer.toString();
    return newValue.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '');
    if (text.length >= 3) {
      text = '${text.substring(0, 2)}/${text.substring(2)}';
    }
    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
