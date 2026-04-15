import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/features/media_ai/presentation/pages/ai_camera_mapping_screen.dart';
import 'package:swiftspace/features/payment/presentation/pages/payment_success_screen.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';

class PropertyOnboardingScreen extends StatefulWidget {
  const PropertyOnboardingScreen({super.key});

  @override
  State<PropertyOnboardingScreen> createState() => _PropertyOnboardingScreenState();
}

class _PropertyOnboardingScreenState extends State<PropertyOnboardingScreen> {
  int _currentStep = 0;
  
  // Form State
  String _transactionType = 'Sale'; // Sale, Rent, Rent-To-Own
  PropertyType _selectedPropertyType = PropertyType.flatsAndApartments;
  // ignore: unused_field
  String _title = '';
  bool _premiumUnlocked = false;
  
  // Map State (Mock)
  double _lat = 9.0765;
  double _lng = 7.3986;
  bool _isDraggingMap = false;

  // Upload States
  bool _floorPlanUploaded = false;
  bool _videoUploaded = false;
  bool _titleUploaded = false;
  bool _surveyPlanUploaded = false;
  int _aiNodesMapped = 0;

  final TextEditingController _termsController = TextEditingController();

  @override
  void dispose() {
    _termsController.dispose();
    super.dispose();
  }

  void _nextStep() {
    AudioManager().playClick(context);
    AudioManager().triggerHaptic(context);
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Final Submission
      AudioManager().playSuccess(context);
      AudioManager().triggerHeavyHaptic(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property Listed Successfully!')),
      );
      Navigator.pop(context);
    }
  }

  void _prevStep() {
    AudioManager().playClick(context);
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _unlockPremiumPlacement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PaymentSuccessScreen(
          title: 'Premium Placement Unlocked',
          description: 'Your property will now be featured with an interactive 3D walkthrough, boosting visibility by up to 5x.',
        ),
      ),
    );
    if (result == true) {
      setState(() {
        _premiumUnlocked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Property Listing', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: _prevStep,
        onStepTapped: (index) {
          setState(() => _currentStep = index);
          AudioManager().playClick(context);
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _currentStep == 4 ? 'Publish Listing' : 'Continue',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: details.onStepCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Basic Details'),
            subtitle: const Text('Type, Price, Spec'),
            content: _buildStep1Basic(theme),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Geolocation'),
            subtitle: const Text('Pin exact map location'),
            content: _buildStep2Location(theme, isDark),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Media & Assets'),
            subtitle: const Text('Photos, Videos, Floor Plans'),
            content: _buildStep3Media(theme),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Legal & Documents'),
            subtitle: const Text('C-of-O, Terms'),
            content: _buildStep4Documents(theme),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Publish & Boost'),
            subtitle: const Text('Finish and Monitize'),
            content: _buildStep5Publish(theme),
            isActive: _currentStep >= 4,
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Basic(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            _buildTypeToggle('Sale', theme),
            const SizedBox(width: 8),
            _buildTypeToggle('Rent', theme),
            const SizedBox(width: 8),
            _buildTypeToggle('Rent-To-Own', theme),
          ],
        ),
        const SizedBox(height: 24),
        const SizedBox(height: 24),
        const Text('Property Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 12),
        DropdownButtonFormField<PropertyType>(
          value: _selectedPropertyType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.withValues(alpha: 0.05),
          ),
          items: PropertyType.values.map((type) => DropdownMenuItem(
            value: type,
            child: Text(type.displayName),
          )).toList(),
          onChanged: (val) {
            if (val != null) {
              AudioManager().playClick(context);
              setState(() => _selectedPropertyType = val);
            }
          },
        ),
        const SizedBox(height: 24),
        TextField(
          onChanged: (val) => setState(() => _title = val),
          decoration: InputDecoration(
            labelText: 'Property Title',
            hintText: 'e.g. Luxury 4-Bed Duplex in Maitama',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _transactionType == 'Rent' ? 'Price per Year (₦)' : 'Target Price (₦)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
           children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Bedrooms',
                    prefixIcon: const Icon(LucideIcons.bed),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Bathrooms',
                    prefixIcon: const Icon(LucideIcons.bath),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
           ],
        ),
        const SizedBox(height: 16),
        TextField(
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Describe the property features and state...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeToggle(String type, ThemeData theme) {
    final isSelected = _transactionType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AudioManager().playClick(context);
          setState(() => _transactionType = type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
            border: Border.all(color: isSelected ? theme.colorScheme.primary : Colors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            type,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? theme.colorScheme.primary : Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep2Location(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('Drag the map to pin the exact geolocation for accurate search indexing.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _isDraggingMap = true;
              _lat -= details.delta.dy * 0.0001; // Fake logic
              _lng += details.delta.dx * 0.0001; // Fake logic
            });
          },
          onPanEnd: (details) {
            setState(() {
              _isDraggingMap = false;
            });
            AudioManager().triggerHaptic(context);
          },
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'), // Mock Map satellite view
                fit: BoxFit.cover,
              )
            ),
            child: Center(
              child: AnimatedContainer(
                 duration: const Duration(milliseconds: 150),
                 transform: Matrix4.translationValues(0, _isDraggingMap ? -10 : 0, 0),
                 child: Icon(LucideIcons.mapPin, color: theme.colorScheme.primary, size: 48),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
           children: [
              Expanded(
                child: TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Latitude',
                    hintText: _lat.toStringAsFixed(6),
                    prefixIcon: const Icon(LucideIcons.compass),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Longitude',
                    hintText: _lng.toStringAsFixed(6),
                    prefixIcon: const Icon(LucideIcons.compass),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
           ],
        ),
      ],
    );
  }

  Widget _buildStep3Media(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        _MediaUploaderCard(
          title: 'Floor Plan (PDF/Image)',
          icon: LucideIcons.layers,
          isUploaded: _floorPlanUploaded,
          onUpload: () {
            _simulateUpload(() => setState(() => _floorPlanUploaded = true));
          },
        ),
        const SizedBox(height: 12),
        _MediaUploaderCard(
          title: 'Video Walkthrough (.mp4)',
          icon: LucideIcons.video,
          isUploaded: _videoUploaded,
          onUpload: () {
            _simulateUpload(() => setState(() => _videoUploaded = true));
          },
        ),
        const SizedBox(height: 16),
        const Text('OR PROVIDE EXTERNAL LINKS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            labelText: 'External Video URL (YouTube/Vimeo)',
            prefixIcon: const Icon(LucideIcons.link),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            labelText: '3D Walkthrough URL (Matterport/Panorama)',
            prefixIcon: const Icon(LucideIcons.map),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(LucideIcons.scanLine, color: Colors.blue, size: 32),
              ),
              const SizedBox(height: 12),
              const Text('AI Virtual Walkthrough', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Use your phone camera to scan rooms and automatically generate a 3D navigable tour.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 16),
              Text('$_aiNodesMapped Nodes Mapped', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AiCameraMappingScreen()));
                  if (result == true) {
                    setState(() => _aiNodesMapped++);
                  }
                },
                icon: const Icon(LucideIcons.camera),
                label: const Text('Map Interior Now', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep4Documents(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Text('Upload required legal documents and define specific terms to fast-track verification.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        _MediaUploaderCard(
          title: 'Certificate of Occupancy / Title',
          icon: LucideIcons.fileText,
          isUploaded: _titleUploaded,
          onUpload: () {
            _simulateUpload(() => setState(() => _titleUploaded = true));
          },
        ),
        const SizedBox(height: 12),
        _MediaUploaderCard(
          title: 'Survey Plan (Verified)',
          icon: LucideIcons.map,
          isUploaded: _surveyPlanUploaded,
          onUpload: () {
            _simulateUpload(() => setState(() => _surveyPlanUploaded = true));
          },
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(LucideIcons.gavel, color: theme.colorScheme.primary, size: 18),
            const SizedBox(width: 12),
            const Text('Lawyer\'s Terms & Conditions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _termsController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter specific legal terms or conditions provided by your attorney (e.g. payout structure, agency fees, possession clauses)...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.shieldCheck, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Auto-Verification Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Our legal AI checks uploaded titles against government registries.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          title: const Text('Require Identity Verification'),
          subtitle: const Text('Only verified users can book inspections.'),
          value: true,
          onChanged: (val) {},
          activeThumbColor: theme.colorScheme.primary,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildStep5Publish(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF3B2DB0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(LucideIcons.rocket, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              const Text('Boost Your Visibility', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Properties with Premium 3D Placement get 5x more serious inquiries.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              _premiumUnlocked 
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.checkCircle2, color: Colors.greenAccent),
                          SizedBox(width: 8),
                          Text('Premium Placed', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _unlockPremiumPlacement,
                      icon: const Icon(LucideIcons.zap),
                      label: const Text('Unlock Premium for ₦10,000', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6C63FF),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  void _simulateUpload(VoidCallback onComplete) {
    AudioManager().playClick(context);
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
         Future.delayed(const Duration(seconds: 2), () {
            navigator.pop();
            if (!mounted) return;
            AudioManager().playSuccess(context);
            onComplete();
         });
         return const AlertDialog(
           backgroundColor: Colors.transparent,
           elevation: 0,
           content: Center(
             child: CircularProgressIndicator(color: Colors.white),
           ),
         );
      }
    );
  }
}

class _MediaUploaderCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isUploaded;
  final VoidCallback onUpload;

  const _MediaUploaderCard({
    required this.title,
    required this.icon,
    required this.isUploaded,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
               color: isUploaded ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
               borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(isUploaded ? LucideIcons.checkCircle : icon, color: isUploaded ? Colors.green : Colors.grey, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w600, color: isUploaded ? (isDark ? Colors.white : Colors.black) : Colors.grey),
            ),
          ),
          isUploaded 
            ? IconButton(icon: const Icon(LucideIcons.x, color: Colors.grey), onPressed: () {})
            : ElevatedButton(
                onPressed: onUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  foregroundColor: theme.colorScheme.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Upload', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
        ],
      ),
    );
  }
}
