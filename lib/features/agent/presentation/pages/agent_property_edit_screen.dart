import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:swiftspace/features/property/presentation/state/property_provider.dart';
import 'package:swiftspace/features/auth/presentation/state/verification_provider.dart';
import 'package:swiftspace/core/services/audio_manager.dart';

class AgentPropertyEditScreen extends StatefulWidget {
  final String propertyId;

  const AgentPropertyEditScreen({super.key, required this.propertyId});

  @override
  State<AgentPropertyEditScreen> createState() => _AgentPropertyEditScreenState();
}

class _AgentPropertyEditScreenState extends State<AgentPropertyEditScreen> {
  int _currentImageIndex = 0;

  void _editField(String label, String initialValue, Function(String) onSave, {bool isNumeric = false, int maxLines = 1}) {
    final controller = TextEditingController(text: initialValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit $label', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: maxLines,
              keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.05),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onSave(controller.text);
                      Navigator.pop(context);
                      AudioManager().playSuccess(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _editAmenities(List<String> currentAmenities, Function(List<String>) onSave) {
    // Simplified multi-select for amenities
    List<String> selected = List.from(currentAmenities);
    final allAmenities = [
      '24/7 Power', 'Running Water', 'Security Guard', 'Fenced & Gated',
      'Pre-paid Meter', 'Generator House', 'Tarred Road', 'En-suite',
      'POP Ceiling', 'Wardrobe', 'Ample Parking', 'Swimming Pool'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Amenities', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allAmenities.map((a) {
                  final isSelected = selected.contains(a);
                  return FilterChip(
                    label: Text(a),
                    selected: isSelected,
                    onSelected: (val) {
                      setModalState(() {
                        if (val) selected.add(a);
                        else selected.remove(a);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onSave(selected);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Selection'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _editPropertyType(Property p, PropertyProvider provider) {
    PropertyType selected = p.type;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Change Property Type', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<PropertyType>(
                value: selected,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: PropertyType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                )).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => selected = val);
                  }
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    provider.updateProperty(p.copyWith(type: selected));
                    Navigator.pop(context);
                  },
                  child: const Text('Confirm'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _editMediaLinks(Property p, PropertyProvider provider) {
    final videoController = TextEditingController(text: p.videoUrl ?? '');
    final walkthroughController = TextEditingController(text: p.panoramaUrl ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Media & Virtual Tour Links', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: videoController,
              decoration: InputDecoration(
                labelText: 'YouTube / Video URL',
                prefixIcon: const Icon(LucideIcons.video),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: walkthroughController,
              decoration: InputDecoration(
                labelText: '3D Walkthrough (Matterport/Panorama) URL',
                prefixIcon: const Icon(LucideIcons.map),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  provider.updateProperty(p.copyWith(
                    videoUrl: videoController.text.isEmpty ? null : videoController.text,
                    hasVideo: videoController.text.isNotEmpty,
                    panoramaUrl: walkthroughController.text.isEmpty ? null : walkthroughController.text,
                    has360View: walkthroughController.text.isNotEmpty,
                  ));
                  Navigator.pop(context);
                },
                child: const Text('Save Metadata'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _manageDocuments(Property p, PropertyProvider provider) {
    List<LegalDocument> docs = List.from(p.legalDocuments);
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Property Documents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
                ],
              ),
              const SizedBox(height: 8),
              if (p.verificationStatus == PropertyVerificationStatus.issuesFlagged)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'One or more documents were REJECTED. Please review the feedback and re-upload.',
                          style: TextStyle(color: Colors.red[700], fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    Color statusColor = Colors.grey;
                    IconData statusIcon = LucideIcons.clock;
                    
                    if (doc.status == LegalDocumentStatus.verified) {
                      statusColor = Colors.green;
                      statusIcon = LucideIcons.checkCircle;
                    } else if (doc.status == LegalDocumentStatus.rejected) {
                      statusColor = Colors.red;
                      statusIcon = LucideIcons.xCircle;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(statusIcon, color: statusColor, size: 18),
                            ),
                            title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(doc.documentType, style: const TextStyle(fontSize: 12)),
                            trailing: IconButton(
                              icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 20),
                              onPressed: () {
                                setModalState(() => docs.removeAt(index));
                              },
                            ),
                          ),
                          if (doc.adminFeedback != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Feedback: ${doc.adminFeedback}',
                                  style: TextStyle(fontSize: 12, color: Colors.orange[900], fontStyle: FontStyle.italic),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              const Text('Add New Document', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Doc Title (e.g. Survey Plan)', 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(LucideIcons.fileText),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: 'Document URL', 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(LucideIcons.link),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (titleController.text.isNotEmpty && urlController.text.isNotEmpty) {
                      setModalState(() {
                        docs.add(LegalDocument(
                          title: titleController.text, 
                          url: urlController.text,
                          documentType: 'PDF Document',
                          verificationDate: DateTime.now(),
                          status: LegalDocumentStatus.pending,
                        ));
                        titleController.clear();
                        urlController.clear();
                      });
                    }
                  },
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Add Document to Queue'),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final verificationProvider = Provider.of<VerificationProvider>(context, listen: false);
                    verificationProvider.submitForVerification(p.id, docs);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Documents submitted for Admin review.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Submit for Verification'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final p = propertyProvider.getPropertyById(widget.propertyId);

    if (p == null) {
      return const Scaffold(body: Center(child: Text('Property not found')));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            title: Text(p.isActive ? 'Active Listing' : 'Listing Off-Market', 
              style: TextStyle(fontSize: 16, color: p.isActive ? Colors.white : Colors.white70)),
            backgroundColor: p.isActive ? theme.colorScheme.primary : Colors.grey[800],
            actions: [
              Row(
                children: [
                   Text(p.isActive ? 'ACTIVE' : 'OFF MARKET', 
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  Switch(
                    value: p.isActive,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.greenAccent,
                    onChanged: (val) {
                      propertyProvider.togglePropertyStatus(p.id);
                      AudioManager().triggerHaptic(context);
                    },
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Opacity(
                opacity: p.isActive ? 1.0 : 0.5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      itemCount: p.imagesGallery.length,
                      onPageChanged: (index) => setState(() => _currentImageIndex = index),
                      itemBuilder: (context, index) => CachedNetworkImage(
                        imageUrl: p.imagesGallery[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${_currentImageIndex + 1} / ${p.imagesGallery.length}', style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                    Center(
                      child: IconButton(
                        icon: const Icon(LucideIcons.camera, color: Colors.white, size: 40),
                        onPressed: () {
                          // Mock Gallery Update
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gallery editor would open here')));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPerformanceStats(p),
                  const SizedBox(height: 32),
                  _buildEditableHeader(p, propertyProvider),
                  if (p.priceTerm != 'buy') ...[
                    const SizedBox(height: 32),
                    _buildFeeConfiguration(p, propertyProvider),
                  ],
                  const SizedBox(height: 32),
                  _buildEditableSection('Description', p.description, (val) {
                    propertyProvider.updateProperty(p.copyWith(description: val));
                  }, maxLines: 5),
                  const SizedBox(height: 32),
                  _buildEditableAmenities(p.amenities, (val) {
                    propertyProvider.updateProperty(p.copyWith(amenities: val));
                  }),
                  const SizedBox(height: 32),
                  _buildEditableMediaLinks(p, propertyProvider),
                  const SizedBox(height: 32),
                  _buildEditableDocuments(p, propertyProvider),
                  const SizedBox(height: 32),
                  _buildEditableSection('Location Name', p.locationName, (val) {
                    propertyProvider.updateProperty(p.copyWith(locationName: val));
                  }),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        // Confirm Delete
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Property?'),
                            content: const Text('This action cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () {
                                  propertyProvider.deleteProperty(p.id);
                                  Navigator.pop(context); // Dialog
                                  Navigator.pop(context); // Screen
                                },
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.trash2, color: Colors.red),
                      label: const Text('Delete Listing', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableHeader(Property p, PropertyProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _editField('Title', p.title, (val) {
                  provider.updateProperty(p.copyWith(title: val));
                }),
                child: Row(
                  children: [
                    Expanded(child: Text(p.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                    const Icon(LucideIcons.pencil, size: 16, color: Colors.grey),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _editPropertyType(p, provider),
                child: Row(
                  children: [
                    Text(p.type.displayName, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.chevronDown, size: 12, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () => _editField('Price', p.price.toString(), (val) {
            final double? newPrice = double.tryParse(val);
            if (newPrice != null) {
              provider.updateProperty(p.copyWith(price: newPrice, formattedPrice: '₦${(newPrice/1000000).toStringAsFixed(1)}M'));
            }
          }, isNumeric: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(p.formattedPrice, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.pencil, size: 16, color: Colors.grey),
                ],
              ),
              Text('Target Price', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeeConfiguration(Property p, PropertyProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rental Fees Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Toggle standard percentage-based fees that will be collected in escrow during checkout.', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 16),
        _feeSwitchSwitchListTile('Caution Fee (10% Refundable)', p.appliesCautionFee, (val) => provider.updateProperty(p.copyWith(appliesCautionFee: val))),
        _feeSwitchSwitchListTile('Agency Fee (10%)', p.appliesAgencyFee, (val) => provider.updateProperty(p.copyWith(appliesAgencyFee: val))),
        _feeSwitchSwitchListTile('Legal Fee (5%)', p.appliesLegalFee, (val) => provider.updateProperty(p.copyWith(appliesLegalFee: val))),
        _feeSwitchSwitchListTile('Platform Service Fee (1.5%)', p.appliesServiceFee, (val) => provider.updateProperty(p.copyWith(appliesServiceFee: val))),
      ],
    );
  }

  Widget _feeSwitchSwitchListTile(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Colors.grey.withValues(alpha: value ? 0.2 : 0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: value ? FontWeight.bold : FontWeight.normal)),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildEditableSection(String label, String value, Function(String) onSave, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(LucideIcons.pencil, size: 20, color: Colors.grey),
              onPressed: () => _editField(label, value, onSave, maxLines: maxLines),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEditableMediaLinks(Property p, PropertyProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Virtual Tour & Media', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(LucideIcons.pencil, size: 20, color: Colors.grey),
              onPressed: () => _editMediaLinks(p, provider),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (p.hasVideo)
          ListTile(
            dense: true,
            leading: const Icon(LucideIcons.video, size: 16),
            title: const Text('Live Property Video Attached'),
            subtitle: Text(p.videoUrl ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        if (p.has360View)
          ListTile(
            dense: true,
            leading: const Icon(LucideIcons.map, size: 16),
            title: const Text('3D Walkthrough Link Active'),
            subtitle: Text(p.panoramaUrl ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        if (!p.hasVideo && !p.has360View)
          const Text('No interactive media linked yet.', style: TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _buildEditableDocuments(Property p, PropertyProvider provider) {
    final theme = Theme.of(context);
    
    String statusLabel = 'Unverified';
    Color statusColor = Colors.grey;
    IconData statusIcon = LucideIcons.shieldAlert;

    switch (p.verificationStatus) {
      case PropertyVerificationStatus.pendingReview:
        statusLabel = 'Pending Review';
        statusColor = Colors.orange;
        statusIcon = LucideIcons.clock;
        break;
      case PropertyVerificationStatus.verified:
        statusLabel = 'Verified';
        statusColor = Colors.green;
        statusIcon = LucideIcons.shieldCheck;
        break;
      case PropertyVerificationStatus.issuesFlagged:
        statusLabel = 'Issues Flagged';
        statusColor = Colors.red;
        statusIcon = LucideIcons.alertTriangle;
        break;
      case PropertyVerificationStatus.fraudBlocked:
        statusLabel = 'Fraud Blocked';
        statusColor = Colors.black;
        statusIcon = LucideIcons.ban;
        break;
      default:
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Compliance & Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(LucideIcons.uploadCloud, size: 20, color: Colors.blue),
              onPressed: () => _manageDocuments(p, provider),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Text(
                statusLabel,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (p.legalDocuments.isEmpty)
          const Text('No legal documents uploaded yet. Upload title docs and survey plans to get verified.', 
            style: TextStyle(color: Colors.grey, fontSize: 13))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: p.legalDocuments.map((doc) {
                Color docColor = Colors.grey;
                if (doc.status == LegalDocumentStatus.verified) docColor = Colors.green;
                if (doc.status == LegalDocumentStatus.rejected) docColor = Colors.red;
                
                return Chip(
                  avatar: Icon(
                    doc.status == LegalDocumentStatus.verified ? LucideIcons.check : LucideIcons.fileText, 
                    size: 14, 
                    color: docColor
                  ),
                  label: Text(doc.title, style: const TextStyle(fontSize: 11)),
                  backgroundColor: docColor.withValues(alpha: 0.1),
                  side: BorderSide(color: docColor.withValues(alpha: 0.2)),
                );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildEditableAmenities(List<String> amenities, Function(List<String>) onSave) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Amenities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(LucideIcons.pencil, size: 20, color: Colors.grey),
              onPressed: () => _editAmenities(amenities, onSave),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((a) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(a, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPerformanceStats(Property p) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.barChart3, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Listing Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: const Text('LIVE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Total Views', '${p.viewsCount}', LucideIcons.eye),
              _buildStatItem('Saved', '${p.favoritesCount}', LucideIcons.heart),
              _buildStatItem('Video Plays', '${p.videoViewsCount}', LucideIcons.playCircle),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              Icon(LucideIcons.zap, size: 14, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.viewsCount > 100 ? 'High interest! Consider adding more photos to close faster.' : 'Trending up. Your listing is being seen.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700], fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}
