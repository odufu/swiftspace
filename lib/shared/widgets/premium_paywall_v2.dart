import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';

class PremiumPaywallV2 extends StatefulWidget {
  final String propertyTitle;
  final VoidCallback onUnlock;

  const PremiumPaywallV2({
    super.key,
    required this.propertyTitle,
    required this.onUnlock,
  });

  static void show(BuildContext context, {required String propertyTitle, required VoidCallback onUnlock}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PremiumPaywallV2(
        propertyTitle: propertyTitle,
        onUnlock: onUnlock,
      ),
    );
  }

  @override
  State<PremiumPaywallV2> createState() => _PremiumPaywallV2State();
}

class _PremiumPaywallV2State extends State<PremiumPaywallV2> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 32,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF121212).withValues(alpha: 0.85),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border(
            top: BorderSide(color: Colors.amber.withValues(alpha: 0.2), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Floating Gold Lock
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(LucideIcons.gem, color: Colors.black, size: 28),
            ),
            const SizedBox(height: 24),

            // Header
            const Text(
              'Exclusive Access',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.propertyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Premium Perks
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  _buildPerk(LucideIcons.map, 'Revealed Address & Routing'),
                  const Divider(color: Colors.white10, height: 24),
                  _buildPerk(LucideIcons.phoneCall, 'Direct Agent & Owner Contact'),
                  const Divider(color: Colors.white10, height: 24),
                  _buildPerk(LucideIcons.fileCheck2, 'Verified Legal Documents'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Price & Guarantee
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Commitment Deposit',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(LucideIcons.shieldCheck, size: 14, color: Colors.greenAccent[400]),
                        const SizedBox(width: 4),
                        Text(
                          '100% Refundable',
                          style: TextStyle(color: Colors.greenAccent[400], fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                const Text(
                  '₦5,000',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Action Button
            GestureDetector(
              onTap: _isProcessing ? null : () async {
                setState(() => _isProcessing = true);
                await Future.delayed(const Duration(seconds: 2));
                if (!mounted) return;
                widget.onUnlock();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: _isProcessing
                    ? const Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Unlock Now',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(LucideIcons.arrowRight, color: Colors.black, size: 20),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Secured by SwiftSpace via Paystack',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPerk(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFFFD700), size: 16),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
