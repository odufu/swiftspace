import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/features/auth/presentation/state/admin_provider.dart';
import 'package:swiftspace/features/auth/presentation/state/verification_provider.dart';
import 'package:swiftspace/features/auth/domain/models/user_profile.dart';
import 'package:swiftspace/core/constants/app_constants.dart';

class RealtorsSection extends StatelessWidget {
  const RealtorsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ap = Provider.of<AdminProvider>(context);
    final vp = Provider.of<VerificationProvider>(context);
    final realtors = ap.realtors;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Realtor Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: realtors.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final realtor = realtors[index];
                return _buildRealtorCard(context, realtor, vp);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtorCard(BuildContext context, UserProfile realtor, VerificationProvider vp) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: realtor.avatarUrl != null ? NetworkImage(realtor.avatarUrl!) : null,
                child: realtor.avatarUrl == null ? const Icon(LucideIcons.user, size: 24) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(realtor.fullName ?? 'Anonymous', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(realtor.email, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              _buildVerificationStatus(realtor),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildInfoTag(LucideIcons.star, '${realtor.yearsExperience} Years Experience'),
              const SizedBox(width: 12),
              _buildInfoTag(LucideIcons.shieldCheck, realtor.role.displayName),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDocumentDialog(context, realtor),
                  icon: const Icon(LucideIcons.fileSearch, size: 18),
                  label: const Text('Review documents'),
                ),
              ),
              if (!realtor.isVerified) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => vp.approveProfessional(realtor.id),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus(UserProfile realtor) {
    final verified = realtor.isVerified;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: verified ? Colors.green.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        verified ? 'VERIFIED' : 'PENDING',
        style: TextStyle(color: verified ? Colors.green : Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  void _showDocumentDialog(BuildContext context, UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Verification Documents', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
                ],
              ),
              const SizedBox(height: 32),
              _buildDocPreview(context, 'Government Issued ID', user.governmentIdUrl),
              const SizedBox(height: 24),
              _buildDocPreview(context, 'Broker / Professional License', user.brokerLicenseUrl),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocPreview(BuildContext context, String label, String? url) {
    final isPdf = url?.toLowerCase().endsWith('.pdf') ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[50],
            child: url == null
                ? const Center(child: Text('No document uploaded'))
                : isPdf
                    ? _buildPdfPlaceholder(url)
                    : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildErrorState()),
          ),
        ),
      ],
    );
  }

  Widget _buildPdfPlaceholder(String url) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(LucideIcons.fileText, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        const Text('PDF Document', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            // In a real app, use url_launcher to open the PDF
          },
          child: const Text('View PDF in Browser'),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return const Center(child: Text('Could not load document preview'));
  }
}
