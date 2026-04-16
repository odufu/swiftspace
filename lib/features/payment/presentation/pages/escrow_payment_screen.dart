import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';

/// Escrow states a payment can be in
enum EscrowState {
  awaitingPayment,
  held,
  inspectionPassed,
  released,
  refunded,
  overdue,
}

/// Basic milestone/installment for a deal
class EscrowInstallment {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  bool isPaid;
  bool isOverdue;

  EscrowInstallment({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
    this.isOverdue = false,
  });
}

/// A financial invoice/receipt record
class AccountInvoice {
  final String id;
  final String transactionId;
  final double amount;
  final DateTime date;
  final String type; // 'Invoice' or 'Receipt'
  final String status; // 'Paid', 'Pending', 'Defaulted'

  AccountInvoice({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.date,
    required this.type,
    this.status = 'Paid',
  });
}

/// A single escrow transaction record (shared mock state)
class EscrowTransaction {
  final String id;
  final String propertyTitle;
  final String location;
  final String propertyImage;
  final String clientName;
  final String agentName;
  final double amount;
  final String dealType;
  final String currency;
  EscrowState state;
  final DateTime createdAt;

  final List<EscrowInstallment> installments;
  final List<AccountInvoice> invoices;

  EscrowTransaction({
    required this.id,
    required this.propertyTitle,
    required this.location,
    required this.propertyImage,
    required this.clientName,
    required this.agentName,
    required this.amount,
    required this.dealType,
    this.currency = '₦',
    this.state = EscrowState.awaitingPayment,
    required this.createdAt,
    this.installments = const [],
    this.invoices = const [],
  });

  String get formattedAmount {
    if (amount >= 1000000) {
      return '$currency${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '$currency${(amount / 1000).toStringAsFixed(0)}k';
    }
    return '$currency${amount.toStringAsFixed(0)}';
  }
}

/// Shared mock escrow store
class MockEscrowStore {
  static final MockEscrowStore _instance = MockEscrowStore._();
  MockEscrowStore._();
  factory MockEscrowStore() => _instance;

  final List<EscrowTransaction> transactions = [
    EscrowTransaction(
      id: 'ESC-001',
      propertyTitle: 'Luxury 4-Bed Duplex',
      location: 'Maitama, Abuja',
      propertyImage:
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      clientName: 'Joel Developer',
      agentName: 'Sarah Agents Ltd',
      amount: 5000,
      dealType: 'Inspection Fee',
      state: EscrowState.held,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      invoices: [
        AccountInvoice(
          id: 'INV-101',
          transactionId: 'ESC-001',
          amount: 5000,
          date: DateTime.now().subtract(const Duration(hours: 2)),
          type: 'Receipt',
        ),
      ],
    ),
    EscrowTransaction(
      id: 'ESC-002',
      propertyTitle: 'Studio Apartment, Lekki',
      location: 'Lekki Phase 1, Lagos',
      propertyImage:
          'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      clientName: 'Joel Developer',
      agentName: 'Prime Properties NG',
      amount: 250000,
      dealType: 'First Month Rent',
      state: EscrowState.inspectionPassed,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      installments: [
        EscrowInstallment(
          id: 'IST-01',
          title: 'Security Deposit',
          amount: 100000,
          dueDate: DateTime.now().subtract(const Duration(days: 5)),
          isPaid: true,
        ),
        EscrowInstallment(
          id: 'IST-02',
          title: 'First Month Rent',
          amount: 150000,
          dueDate: DateTime.now().add(const Duration(days: 20)),
        ),
      ],
      invoices: [
        AccountInvoice(
          id: 'INV-102',
          transactionId: 'ESC-002',
          amount: 100000,
          date: DateTime.now().subtract(const Duration(days: 5)),
          type: 'Receipt',
        ),
      ],
    ),
    EscrowTransaction(
      id: 'ESC-003',
      propertyTitle: 'Semi-Detached Bungalow',
      location: 'Kubwa, Abuja',
      propertyImage:
          'https://images.unsplash.com/photo-1568605114967-8130f3a36994?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      clientName: 'Michael Okafor',
      agentName: 'Abuja Realty',
      amount: 35000000,
      dealType: 'Full Purchase',
      state: EscrowState.overdue,
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
      installments: [
        EscrowInstallment(
          id: 'IST-03',
          title: 'Initial Deposit (30%)',
          amount: 10500000,
          dueDate: DateTime.now().subtract(const Duration(days: 40)),
          isPaid: true,
        ),
        EscrowInstallment(
          id: 'IST-04',
          title: 'Second Milestone',
          amount: 12250000,
          dueDate: DateTime.now().subtract(const Duration(days: 2)),
          isOverdue: true,
        ),
        EscrowInstallment(
          id: 'IST-05',
          title: 'Final Balance',
          amount: 12250000,
          dueDate: DateTime.now().add(const Duration(days: 30)),
        ),
      ],
      invoices: [
        AccountInvoice(
          id: 'INV-103',
          transactionId: 'ESC-003',
          amount: 10500000,
          date: DateTime.now().subtract(const Duration(days: 40)),
          type: 'Receipt',
        ),
        AccountInvoice(
          id: 'INV-104',
          transactionId: 'ESC-003',
          amount: 12250000,
          date: DateTime.now().subtract(const Duration(days: 2)),
          type: 'Invoice',
          status: 'Defaulted',
        ),
      ],
    ),
  ];

  void payInstallment(String transactionId, String installmentId) {
    final txIndex = transactions.indexWhere((t) => t.id == transactionId);
    if (txIndex != -1) {
      final tx = transactions[txIndex];
      final instIndex = tx.installments.indexWhere(
        (i) => i.id == installmentId,
      );
      if (instIndex != -1) {
        final inst = tx.installments[instIndex];
        inst.isPaid = true;
        inst.isOverdue = false;

        // Add receipt
        tx.invoices.add(
          AccountInvoice(
            id: 'INV-${DateTime.now().millisecondsSinceEpoch}',
            transactionId: transactionId,
            amount: inst.amount,
            date: DateTime.now(),
            type: 'Receipt',
          ),
        );

        // Update transaction state if everything is paid
        final allPaid = tx.installments.every((i) => i.isPaid);
        if (allPaid) {
          tx.state = EscrowState.released;
        } else {
          // If was overdue, might still be held
          tx.state = EscrowState.held;
        }
      }
    }
  }

  /// Creates and stores a new escrow transaction (e.g. inspection fee).
  EscrowTransaction addTransaction(EscrowTransaction tx) {
    transactions.add(tx);
    return tx;
  }

  /// Finds a transaction by its booking reference ID.
  EscrowTransaction? findByBookingId(String bookingId) {
    try {
      return transactions.firstWhere((t) => t.id == 'INSP-$bookingId');
    } catch (_) {
      return null;
    }
  }

  /// Marks the inspection fee escrow as released (to agent on completion)
  /// or refunded (on decline/cancel).
  void settleInspectionFee(String bookingId, {bool refund = false}) {
    final tx = findByBookingId(bookingId);
    if (tx != null) {
      tx.state = refund ? EscrowState.refunded : EscrowState.released;
    }
  }
}

// -------------------------------------------------------
// Escrow Payment Initiation Screen
// -------------------------------------------------------
class EscrowPaymentScreen extends StatefulWidget {
  final String propertyTitle;
  final String location;
  final String propertyImage;
  final double amount;
  final String dealType;
  final Property? property;

  const EscrowPaymentScreen({
    super.key,
    required this.propertyTitle,
    required this.location,
    required this.propertyImage,
    required this.amount,
    required this.dealType,
    this.property,
  });

  @override
  State<EscrowPaymentScreen> createState() => _EscrowPaymentScreenState();
}

class _EscrowPaymentScreenState extends State<EscrowPaymentScreen> {
  int _step = 0;
  String _selectedMethod = 'Bank Transfer';
  final List<String> _methods = ['Bank Transfer', 'Card Payment', 'USSD'];

  bool get _isRental => widget.dealType == 'Rental Agreement';
  double get _rent => widget.amount;
  double get _caution =>
      (_isRental && (widget.property?.appliesCautionFee ?? true))
      ? widget.amount * 0.1
      : 0;
  double get _agency =>
      (_isRental && (widget.property?.appliesAgencyFee ?? true))
      ? widget.amount * 0.1
      : 0;
  double get _legal => (_isRental && (widget.property?.appliesLegalFee ?? true))
      ? widget.amount * 0.05
      : 0;

  double get _serviceFee =>
      (widget.property?.appliesServiceFee ?? true) ? widget.amount * 0.015 : 0;
  double get _subTotal =>
      _isRental ? _rent + _caution + _agency + _legal : widget.amount;
  double get _total => _subTotal + _serviceFee;

  String _fmt(double v) {
    if (v >= 1000000) return '₦${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '₦${(v / 1000).toStringAsFixed(1)}k';
    return '₦${v.toStringAsFixed(0)}';
  }

  void _confirmPayment() async {
    setState(() => _step = 1);
    sl<AudioManager>().playClick(context);
    await SharePlus.instance.share(ShareParams(text: 'Payment initiated for ${widget.propertyTitle}'));
    await Future.delayed(const Duration(seconds: 2));
    final escrowId = 'ESC-${DateTime.now().millisecondsSinceEpoch}';
    List<EscrowInstallment> installments = [];
    if (_isRental) {
      installments.add(
        EscrowInstallment(
          id: 'IST-${DateTime.now().millisecondsSinceEpoch}-1',
          title: 'Rent',
          amount: _rent,
          dueDate: DateTime.now(),
          isPaid: true,
        ),
      );
      if (widget.property?.appliesCautionFee ?? true) {
        installments.add(
          EscrowInstallment(
            id: 'IST-${DateTime.now().millisecondsSinceEpoch}-2',
            title: 'Caution Fee',
            amount: _caution,
            dueDate: DateTime.now(),
            isPaid: true,
          ),
        );
      }
      if (widget.property?.appliesAgencyFee ?? true) {
        installments.add(
          EscrowInstallment(
            id: 'IST-${DateTime.now().millisecondsSinceEpoch}-3',
            title: 'Agency Fee',
            amount: _agency,
            dueDate: DateTime.now(),
            isPaid: true,
          ),
        );
      }
      if (widget.property?.appliesLegalFee ?? true) {
        installments.add(
          EscrowInstallment(
            id: 'IST-${DateTime.now().millisecondsSinceEpoch}-4',
            title: 'Legal Fee',
            amount: _legal,
            dueDate: DateTime.now(),
            isPaid: true,
          ),
        );
      }
    }

    final newTx = EscrowTransaction(
      id: escrowId,
      propertyTitle: widget.propertyTitle,
      location: widget.location,
      propertyImage: widget.propertyImage,
      clientName: 'You',
      agentName: 'Agent',
      amount: _subTotal,
      dealType: widget.dealType,
      state: EscrowState.held,
      createdAt: DateTime.now(),
      installments: installments,
      invoices: [
        AccountInvoice(
          id: 'INV-${DateTime.now().millisecondsSinceEpoch}',
          transactionId: escrowId,
          amount: _total,
          date: DateTime.now(),
          type: 'Receipt',
        ),
      ],
    );
    MockEscrowStore().transactions.insert(0, newTx);
    if (!mounted) return;
    sl<AudioManager>().playSuccess(context);
    sl<AudioManager>().triggerHeavyHaptic(context);
    setState(() => _step = 2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Secure Payment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _step == 1
          ? _buildProcessing()
          : _step == 2
          ? _buildSuccess(theme)
          : _buildSummary(theme, isDark),
    );
  }

  Widget _buildSummary(ThemeData theme, bool isDark) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.shieldCheck,
                      color: Colors.blue,
                      size: 32,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Protected by Swift Space Escrow',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your money is held securely and only released after inspection & deal confirmation.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.propertyImage,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(height: 160, color: Colors.grey[300]),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.propertyTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(LucideIcons.mapPin, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    widget.location,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    _buildRow(
                      _isRental ? 'Annual Rent' : widget.dealType,
                      _fmt(widget.amount),
                    ),
                    if (_isRental &&
                        (widget.property?.appliesCautionFee ?? true)) ...[
                      const SizedBox(height: 12),
                      _buildRow(
                        'Caution Fee (10% - Refundable)',
                        _fmt(_caution),
                        color: Colors.grey[600],
                      ),
                    ],
                    if (_isRental &&
                        (widget.property?.appliesAgencyFee ?? true)) ...[
                      const SizedBox(height: 12),
                      _buildRow(
                        'Agency Fee (10%)',
                        _fmt(_agency),
                        color: Colors.grey[600],
                      ),
                    ],
                    if (_isRental &&
                        (widget.property?.appliesLegalFee ?? true)) ...[
                      const SizedBox(height: 12),
                      _buildRow(
                        'Legal Fee (5%)',
                        _fmt(_legal),
                        color: Colors.grey[600],
                      ),
                    ],
                    if (widget.property == null ||
                        widget.property!.appliesServiceFee) ...[
                      const SizedBox(height: 12),
                      _buildRow(
                        'Platform Fee (1.5%)',
                        _fmt(_serviceFee),
                        color: Colors.grey[600],
                      ),
                    ],
                    const Divider(height: 24),
                    _buildRow(
                      'Total',
                      _fmt(_total),
                      isBold: true,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Method',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...List.generate(_methods.length, (i) {
                final m = _methods[i];
                final sel = _selectedMethod == m;
                return GestureDetector(
                  onTap: () {
                    sl<AudioManager>().playClick(context);
                    setState(() => _selectedMethod = m);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: sel
                          ? theme.colorScheme.primary.withValues(alpha: 0.07)
                          : (isDark ? Colors.grey[900] : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel
                            ? theme.colorScheme.primary
                            : Colors.grey.withValues(alpha: 0.2),
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          i == 0
                              ? LucideIcons.landmark
                              : i == 1
                              ? LucideIcons.creditCard
                              : LucideIcons.smartphone,
                          color: sel ? theme.colorScheme.primary : Colors.grey,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          m,
                          style: TextStyle(
                            fontWeight: sel
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: sel ? theme.colorScheme.primary : null,
                          ),
                        ),
                        const Spacer(),
                        if (sel)
                          Icon(
                            LucideIcons.checkCircle2,
                            color: theme.colorScheme.primary,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _confirmPayment,
                  icon: const Icon(LucideIcons.lock),
                  label: Text(
                    'Pay ${_fmt(_total)} into Escrow',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.shield, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      '256-bit encrypted • PCI DSS compliant',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessing() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text(
            'Securing your funds...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Placing payment in escrow vault'),
        ],
      ),
    );
  }

  Widget _buildSuccess(ThemeData theme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.shieldCheck,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Payment in Escrow!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '${_fmt(_total)} is now safely held by Swift Space. It will be released to the agent only when your deal conditions are met.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.green.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Escrow Milestones',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildEscrowStep(
                      theme,
                      1,
                      'Funds Received & Secured',
                      true,
                    ),
                    _buildLine(true),
                    _buildEscrowStep(theme, 2, 'Inspection Scheduled', false),
                    _buildLine(false),
                    _buildEscrowStep(theme, 3, 'Deal Conditions Met', false),
                    _buildLine(false),
                    _buildEscrowStep(
                      theme,
                      4,
                      'Funds Released to Agent',
                      false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Great, Track in Activity',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLine(bool active) {
    return Container(
      margin: const EdgeInsets.only(left: 11),
      height: 20,
      width: 2,
      color: active ? Colors.green : Colors.grey.withValues(alpha: 0.2),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: color ?? (isBold ? null : Colors.grey[600]),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildEscrowStep(ThemeData theme, int step, String label, bool done) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: done ? Colors.green : Colors.grey.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: done
                ? const Icon(LucideIcons.check, color: Colors.white, size: 13)
                : Text(
                    '$step',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontWeight: done ? FontWeight.bold : FontWeight.normal,
            color: done ? Colors.green : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------
// Escrow Status Badge (embeddable widget)
// -------------------------------------------------------
class EscrowStatusBadge extends StatelessWidget {
  final EscrowState state;
  const EscrowStatusBadge({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late IconData icon;
    late String label;
    switch (state) {
      case EscrowState.awaitingPayment:
        color = Colors.grey;
        icon = LucideIcons.clock;
        label = 'Awaiting Payment';
      case EscrowState.held:
        color = Colors.orange;
        icon = LucideIcons.lock;
        label = 'Funds Held';
      case EscrowState.inspectionPassed:
        color = Colors.blue;
        icon = LucideIcons.clipboardCheck;
        label = 'Inspection Passed';
      case EscrowState.released:
        color = Colors.green;
        icon = LucideIcons.checkCircle2;
        label = 'Funds Released';
      case EscrowState.refunded:
        color = Colors.red;
        icon = LucideIcons.rotateCcw;
        label = 'Refunded';
      case EscrowState.overdue:
        color = Colors.redAccent;
        icon = LucideIcons.alertTriangle;
        label = 'Overdue';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------
// Agent Escrow Overview Widget (Agent Dashboard Overview tab)
// -------------------------------------------------------
class AgentEscrowSummaryCard extends StatelessWidget {
  const AgentEscrowSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = MockEscrowStore().transactions;
    final heldTx = transactions
        .where(
          (t) =>
              t.state == EscrowState.held ||
              t.state == EscrowState.inspectionPassed,
        )
        .toList();
    final totalHeld = heldTx.fold<double>(0, (sum, t) => sum + t.amount);
    final releasedTotal = transactions
        .where((t) => t.state == EscrowState.released)
        .fold<double>(0, (sum, t) => sum + t.amount);

    String fmt(double v) {
      if (v >= 1000000) return '₦${(v / 1000000).toStringAsFixed(1)}M';
      if (v >= 1000) return '₦${(v / 1000).toStringAsFixed(0)}k';
      return '₦${v.toStringAsFixed(0)}';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.landmark, color: Colors.orange, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Escrow Vault',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (heldTx.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${heldTx.length} pending',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  'Funds Held',
                  fmt(totalHeld),
                  Colors.orange,
                  LucideIcons.lock,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStat(
                  'Released',
                  fmt(releasedTotal),
                  Colors.green,
                  LucideIcons.arrowDownToLine,
                ),
              ),
            ],
          ),
          if (heldTx.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            ...heldTx
                .take(2)
                .map(
                  (tx) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.propertyTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tx.dealType,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          tx.formattedAmount,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        EscrowStatusBadge(state: tx.state),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        ],
      ),
    );
  }
}
