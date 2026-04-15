import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/features/auth/presentation/state/verification_provider.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verificationProvider = Provider.of<VerificationProvider>(context);
    final pendingProperties = verificationProvider.pendingVerifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Verification Portal', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: pendingProperties.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.checkCircle, size: 64, color: Colors.green.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('No pending verifications', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingProperties.length,
              itemBuilder: (context, index) {
                final property = pendingProperties[index];
                return _buildVerificationCard(property, theme);
              },
            ),
    );
  }

  Widget _buildVerificationCard(Property property, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: property.imageUrl,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'PENDING REVIEW',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Agent: ${property.listerName}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 20),
                const Text('Documents to Review:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                ...property.legalDocuments.map((doc) => _buildDocumentItem(property, doc, theme)).toList(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _confirmFraud(property.id);
                        },
                        icon: const Icon(LucideIcons.ban, size: 18),
                        label: const Text('Flag Fraud'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(Property property, LegalDocument doc, ThemeData theme) {
    bool isPending = doc.status == LegalDocumentStatus.pending;
    bool isVerified = doc.status == LegalDocumentStatus.verified;
    bool isRejected = doc.status == LegalDocumentStatus.rejected;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(LucideIcons.fileText, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text('Type: ${doc.documentType}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ),
              if (isPending) ...[
                IconButton(
                  icon: const Icon(LucideIcons.xCircle, color: Colors.red, size: 22),
                  onPressed: () => _rejectDoc(property.id, doc.title),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.checkCircle, color: Colors.green, size: 22),
                  onPressed: () {
                    Provider.of<VerificationProvider>(context, listen: false)
                        .adminVerifyDocument(property.id, doc.title);
                  },
                ),
              ] else if (isVerified)
                const Icon(LucideIcons.check, color: Colors.green, size: 20)
              else if (isRejected)
                const Icon(LucideIcons.x, color: Colors.red, size: 20),
            ],
          ),
          if (isRejected && doc.adminFeedback != null)
             Padding(
               padding: const EdgeInsets.only(top: 8, left: 30),
               child: Text(
                 'Rejected: ${doc.adminFeedback}',
                 style: const TextStyle(color: Colors.red, fontSize: 11, fontStyle: FontStyle.italic),
               ),
             ),
        ],
      ),
    );
  }

  void _rejectDoc(String propertyId, String docTitle) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Document'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'e.g. Image blurry or document expired',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Provider.of<VerificationProvider>(context, listen: false)
                    .adminRejectDocument(propertyId, docTitle, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );
  }

  void _confirmFraud(String propertyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚨 FLAG AS FRAUD?'),
        content: const Text(
          'This will IMMEDIATELY delisted the property and mark the agent account for investigation. This action is critical.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Provider.of<VerificationProvider>(context, listen: false).adminMarkFraud(propertyId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(backgroundColor: Colors.red, content: Text('Property blocked for fraud.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('YES, BLOCK PROPERTY'),
          ),
        ],
      ),
    );
  }
}
