import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/features/auth/presentation/state/admin_provider.dart';
import 'package:swiftspace/features/auth/presentation/state/verification_provider.dart';
import 'package:swiftspace/features/auth/domain/models/user_profile.dart';
import 'package:swiftspace/core/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class RealtorsSection extends StatelessWidget {
  const RealtorsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ap = Provider.of<AdminProvider>(context);
    final vp = Provider.of<VerificationProvider>(context);
    
    // Sort realtors: Pending first, then by name
    final sortedRealtors = List<UserProfile>.from(ap.realtors)
      ..sort((a, b) {
        if (a.isVerified != b.isVerified) {
          return a.isVerified ? 1 : -1;
        }
        return (a.fullName ?? '').compareTo(b.fullName ?? '');
      });

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Realtor Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => ap.fetchAllData(), icon: const Icon(LucideIcons.refreshCw, size: 18)),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ap.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ap.error != null
                ? Center(child: Text('Error: ${ap.error}', style: const TextStyle(color: Colors.red)))
                : sortedRealtors.isEmpty 
                  ? const Center(child: Text('No realtors or applicants found'))
              : ListView.separated(
                  itemCount: sortedRealtors.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final realtor = sortedRealtors[index];
                    return _buildRealtorCard(context, realtor, vp, ap);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtorCard(BuildContext context, UserProfile realtor, VerificationProvider vp, AdminProvider ap) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
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
                  onPressed: () => _showApplicationDetailsDialog(context, realtor, vp, ap),
                  icon: const Icon(LucideIcons.fileSearch, size: 18),
                  label: const Text('Review'),
                ),
              ),
              if (!realtor.isVerified) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await vp.rejectProfessional(realtor.id);
                      await ap.fetchAllData();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await vp.approveProfessional(realtor.id);
                      await ap.fetchAllData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, 
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await vp.unverifyProfessional(realtor.id);
                      await ap.fetchAllData();
                    },
                    icon: const Icon(LucideIcons.shieldAlert, size: 18),
                    label: const Text('Unverify'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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

  void _showApplicationDetailsDialog(BuildContext context, UserProfile user, VerificationProvider vp, AdminProvider ap) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 800,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Professional Application', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                      child: user.avatarUrl == null ? const Icon(LucideIcons.user, size: 40) : null,
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName ?? 'Anonymous', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text(user.email, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                          const SizedBox(height: 8),
                          _buildVerificationStatus(user),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        _buildStatBox('Experience', '${user.yearsExperience} yrs'),
                        const SizedBox(height: 8),
                        _buildStatBox('Role', user.role.displayName),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 64),
                const Text('Verification Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildDocPreview(context, 'Government Issued ID', user.governmentIdUrl)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildDocPreview(context, 'Professional License', user.brokerLicenseUrl)),
                  ],
                ),
                const SizedBox(height: 48),
                if (!user.isVerified) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await vp.rejectProfessional(user.id);
                            await ap.fetchAllData();
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Reject Application', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await vp.approveProfessional(user.id);
                            await ap.fetchAllData();
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Approve Agent', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Close Details'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDocPreview(BuildContext context, String label, String? url) {
    if (url == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 12),
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: const Center(child: Text('No document uploaded', style: TextStyle(color: Colors.grey))),
          ),
        ],
      );
    }

    final isPdf = url.toLowerCase().endsWith('.pdf');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showFullscreenPreview(context, label, url, isPdf),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[50],
                    child: isPdf
                        ? _buildPdfPlaceholder(url)
                        : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildErrorState()),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.maximize2, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFullscreenPreview(BuildContext context, String label, String url, bool isPdf) {
    if (isPdf) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfPlaceholder(String url) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(LucideIcons.fileText, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        const Text('PDF Document', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Click to view full document', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildErrorState() {
    return const Center(child: Text('Could not load document preview'));
  }
}
