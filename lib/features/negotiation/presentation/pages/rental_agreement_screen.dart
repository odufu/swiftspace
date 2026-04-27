import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/di/injection_container.dart';

class RentalAgreementScreen extends StatefulWidget {
  final Property property;
  final double negotiatedPrice;

  const RentalAgreementScreen({
    super.key,
    required this.property,
    required this.negotiatedPrice,
  });

  @override
  State<RentalAgreementScreen> createState() => _RentalAgreementScreenState();
}

class _RentalAgreementScreenState extends State<RentalAgreementScreen> {
  bool _isSigned = false;
  bool _showSuccess = false;

  final List<String> _clauses = [
    "The Tenant shall keep the property in a clean and tenantable condition.",
    "The Landlord shall be responsible for structural repairs and major maintenance.",
    "The Tenant shall not sub-let or part with possession of the property without written consent.",
    "The Caution Fee shall be used to rectify any damages caused by the Tenant's negligence.",
    "Utilities like electricity and water shall be paid promptly by the Tenant.",
    "A notice period of 3 months is required for termination of this lease agreement.",
  ];

  void _signAgreement() async {
    sl<AudioManager>().playClick(context);
    setState(() => _isSigned = true);
    
    // Simulate real-time processing/blockchain timestamping
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    
    sl<AudioManager>().playSuccess(context);
    sl<AudioManager>().triggerHeavyHaptic(context);
    setState(() => _showSuccess = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_showSuccess) return _buildSuccessOverlay(theme);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Tenancy Agreement', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 32),
            const Text(
              'Agreement Terms',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._clauses.map((clause) => _buildClauseItem(clause, theme)),
            const SizedBox(height: 48),
            _buildSignatureSection(theme),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(widget.property.imageUrl, height: 60, width: 60, fit: BoxFit.cover),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.property.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(widget.property.locationName, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Agreed Rent', style: TextStyle(fontWeight: FontWeight.w500)),
              Text(
                '₦${(widget.negotiatedPrice / 1000000).toStringAsFixed(1)}M / year',
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClauseItem(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(height: 1.5, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildSignatureSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Authorized Signatories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            _signatureTile('Landlord / Agent', widget.property.listerName, true, theme),
            const SizedBox(width: 16),
            _signatureTile('Tenant', 'You', _isSigned, theme),
          ],
        ),
      ],
    );
  }

  Widget _signatureTile(String role, String name, bool signed, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 140,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: signed ? Colors.green.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(role, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
            const Spacer(),
            if (signed)
              Text(name, style: const TextStyle(fontFamily: 'Cursive', fontSize: 24, color: Colors.blue))
            else
              const Icon(LucideIcons.penTool, color: Colors.grey, size: 32),
            const Spacer(),
            if (signed)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.checkCircle, size: 12, color: Colors.green),
                  SizedBox(width: 4),
                  Text('Verified', style: TextStyle(color: Colors.green, fontSize: 10)),
                ],
              )
            else
              Text('Awaiting...', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isSigned ? null : _signAgreement,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            _isSigned ? 'Signing...' : 'Sign Tenancy Agreement',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 80),
            const SizedBox(height: 32),
            const Text(
              'Lease Signed!',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Digital Handover Complete. The tenancy agreement has been signed and recorded.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            const SizedBox(height: 64),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
                minimumSize: const Size(200, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Back to My Hub', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
