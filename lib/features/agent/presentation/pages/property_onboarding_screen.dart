import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:confetti/confetti.dart';
import 'package:swiftspace/core/constants/app_constants.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/core/utils/ui_utils.dart';
import 'package:swiftspace/features/auth/presentation/state/auth_provider.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:swiftspace/features/property/presentation/state/property_provider.dart';
import 'package:swiftspace/features/property/presentation/pages/components/media_picker_component.dart';
import 'package:swiftspace/features/property/presentation/pages/components/location_picker_component.dart';

class PropertyOnboardingScreen extends StatefulWidget {
  const PropertyOnboardingScreen({super.key});

  @override
  State<PropertyOnboardingScreen> createState() => _PropertyOnboardingScreenState();
}

class _PropertyOnboardingScreenState extends State<PropertyOnboardingScreen> {
  int _currentStep = 0;
  final int _totalSteps = 7;
  late ConfettiController _confettiController;

  // Step 1: Basics
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  PropertyType _propertyType = PropertyType.flatsAndApartments;
  String _priceTerm = 'yr'; // yr, mo, buy

  // Step 2: Media
  List<XFile> _images = [];
  XFile? _video;
  XFile? _floorPlan;

  // Step 3: Location
  LatLng _selectedLocation = const LatLng(9.0765, 7.3986); // Abuja default
  String _locationName = '';

  // Step 4: Details & Amenities
  int _beds = 0;
  int _baths = 0;
  final List<String> _selectedAmenities = [];
  final List<String> _allAmenities = [
    '24/7 Power', 'Running Water', 'Security Guard', 'Fenced & Gated', 
    'Pre-paid Meter', 'Generator House', 'Tarred Road', 'En-suite', 
    'POP Ceiling', 'Wardrobe', 'Ample Parking', 'Swimming Pool', 
    'CCTV Cameras', 'Boys Quarters', 'Tiled Floors', 'Air Conditioning',
    'Fiber Internet', 'Gym', 'Playground', 'Garden', 'Smart Home'
  ];

  // Proximity Metrics
  int _proximityToRoad = 100;
  int _electricityHours = 12;
  double _proximityToHospital = 2.0;

  // Step 5: Technical Specs
  int? _yearBuilt;
  final _sqftController = TextEditingController();
  String _foundationType = 'Strip Foundation';
  bool _floodingHistory = false;

  // Step 6: Legal & Documents
  bool _hasCOofO = false;
  bool _hasGovernorsConsent = false;
  bool _hasSurveyPlan = false;
  bool _hasDeedOfAssignment = false;
  bool _hasBuildingPlanApproval = false;
  bool _hasSoilTest = false;
  bool _hasStructuralReport = false;
  final _dueDiligenceController = TextEditingController();
  bool _lawyerVerified = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _sqftController.dispose();
    _dueDiligenceController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      sl<AudioManager>().playClick(context);
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    sl<AudioManager>().playClick(context);
    setState(() => _currentStep--);
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_titleController.text.isEmpty || _priceController.text.isEmpty) {
        UiUtils.showError(context, 'Please fill in basic details');
        return false;
      }
    } else if (_currentStep == 1) {
      if (_images.length < 3) {
        UiUtils.showError(context, 'Please upload at least 3 photos');
        return false;
      }
    } else if (_currentStep == 4) {
      if (_yearBuilt == null) {
        UiUtils.showError(context, 'Please specify the building year');
        return false;
      }
    } else if (_currentStep == 5) {
      if (!_hasSurveyPlan && !_hasCOofO && !_hasGovernorsConsent) {
        UiUtils.showWarning(context, 'Proceeding without major title documents may slow down verification.');
      }
    }
    return true;
  }

  Future<void> _saveAsDraft() async {
    // In this simplified version, "Saving as Draft" just persists the current media progress
    // and returns to the dashboard. The PropertyProvider handles the SharedPreferences.
    sl<AudioManager>().playClick(context);
    UiUtils.showSuccess(context, 'Progress saved as draft locally');
    Navigator.pop(context);
  }

  Future<void> _submit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    
    // Check if background uploads are still in progress
    if (propertyProvider.isUploading) {
      UiUtils.showInfo(context, 'Waiting for media to finish uploading...');
    }

    final property = Property(
      id: '', // Will be set in provider
      title: _titleController.text,
      description: _descriptionController.text,
      price: double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0.0,
      priceTerm: _priceTerm,
      formattedPrice: '₦${_priceController.text}',
      locationName: _locationName.isEmpty ? 'Abuja, Nigeria' : _locationName,
      location: _selectedLocation,
      type: _propertyType,
      beds: _beds,
      baths: _baths,
      imageUrl: '', // Will be set after upload
      imagesGallery: [],
      has360View: false,
      hasVideo: _video != null,
      amenities: _selectedAmenities,
      listerName: authProvider.profile?.fullName ?? 'Verified Agent',
      listerType: ListerType.agent,
      agentPhone: authProvider.profile?.email ?? '',
      isVerified: false,
      proximityToRoadMeters: _proximityToRoad,
      electricitySupplyHours: _electricityHours.toDouble(),
      hasRunningWater: _selectedAmenities.contains('Running Water'),
      proximityToHospitalKm: _proximityToHospital,
      yearBuilt: _yearBuilt,
      totalSquareFootage: double.tryParse(_sqftController.text),
      floodingHistory: _floodingHistory,
      foundationType: _foundationType,
      hasCertificateOfOccupancy: _hasCOofO,
      hasGovernorsConsent: _hasGovernorsConsent,
      hasSurveyPlan: _hasSurveyPlan,
      hasDeedOfAssignment: _hasDeedOfAssignment,
      hasBuildingPlanApproval: _hasBuildingPlanApproval,
      hasSoilTestReport: _hasSoilTest,
      hasStructuralIntegrityReport: _hasStructuralReport,
      dueDiligenceNotes: _dueDiligenceController.text,
      hasLawyerVerifiedTerms: _lawyerVerified,
      verificationStatus: PropertyVerificationStatus.pendingReview,
      isActive: true,
    );

    final listerId = authProvider.user?.id;
    if (listerId == null) {
      UiUtils.showError(context, 'You must be logged in to publish a listing');
      return;
    }

    final success = await propertyProvider.createProperty(
      property: property,
      images: _images,
      listerId: listerId,
      video: _video,
      planImage: _floorPlan,
    );

    if (mounted) {
      if (success) {
        sl<AudioManager>().playSuccess(context);
        _confettiController.play();
        _showSuccessDialog();
      } else {
        UiUtils.showError(context, propertyProvider.error ?? 'Listing failed');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.rocket, color: AppColors.primaryLight, size: 64),
            const SizedBox(height: 24),
            const Text('Listing Published!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Your property is now under review and will be live shortly.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _confettiController.stop();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back to Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final isLoading = propertyProvider.isLoading;
    final isUploading = propertyProvider.isUploading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('List Property', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => _currentStep > 0 ? _prevStep() : Navigator.pop(context),
        ),
        actions: [
          if (!isLoading)
            TextButton(
              onPressed: _saveAsDraft,
              child: const Text('Save Draft', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
            ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('Step ${_currentStep + 1} of $_totalSteps', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            ),
          ),
        ],
      ),
      body: isLoading 
        ? Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text('Finalizing your listing...', style: TextStyle(fontWeight: FontWeight.bold)),
              if (isUploading)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text('Completing media uploads...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
            ],
          ))
        : Column(
            children: [
              _buildProgressBar(),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildCurrentStep(),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConfettiWidget(
                        confettiController: _confettiController,
                        blastDirectionality: BlastDirectionality.explosive,
                        shouldLoop: false,
                        colors: const [
                          Colors.green,
                          Colors.blue,
                          Colors.pink,
                          Colors.orange,
                          Colors.purple
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildBottomNav(),
            ],
          ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 4,
      width: double.infinity,
      color: Colors.grey.withValues(alpha: 0.1),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (_currentStep + 1) / _totalSteps,
        child: Container(color: AppColors.primaryLight),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildStepBasics();
      case 1: return _buildStepMedia();
      case 2: return _buildStepLocation();
      case 3: return _buildStepDetails();
      case 4: return _buildStepTechnical();
      case 5: return _buildStepLegal();
      case 6: return _buildStepReview();
      default: return Container();
    }
  }

  Widget _buildStepBasics() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Let\'s start with the basics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Select your property type and set your pricing.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        DropdownButtonFormField<PropertyType>(
          initialValue: _propertyType,
          items: PropertyType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.displayName))).toList(),
          onChanged: (v) => setState(() => _propertyType = v!),
          decoration: const InputDecoration(labelText: 'Property Type', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: 'Property Title', hintText: 'e.g. Modern 3-Bed Apartment', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (₦)', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _priceTerm,
                items: const [
                  DropdownMenuItem(value: 'yr', child: Text('/yr')),
                  DropdownMenuItem(value: 'mo', child: Text('/mo')),
                  DropdownMenuItem(value: 'buy', child: Text('Buy')),
                ],
                onChanged: (v) => setState(() => _priceTerm = v!),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepMedia() {
    return Column(
      key: const ValueKey(1),
      children: [
        const Text('Bring your listing to life', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Upload high-quality media to attract more leads.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        MediaPickerComponent(
          images: _images,
          video: _video,
          onImagesChanged: (list) => setState(() => _images = list),
          onVideoChanged: (file) => setState(() => _video = file),
        ),
      ],
    );
  }

  Widget _buildStepLocation() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Where is it based?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        LocationPickerComponent(
          initialLocation: _selectedLocation,
          onLocationChanged: (loc) => setState(() => _selectedLocation = loc),
        ),
        const SizedBox(height: 24),
        TextField(
          onChanged: (v) => setState(() => _locationName = v),
          decoration: const InputDecoration(labelText: 'Area / Neighborhood Name', hintText: 'e.g. Maitama, Abuja', border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildStepDetails() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Final details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        Row(
          children: [
            _buildCounter('Bedrooms', _beds, (v) => setState(() => _beds = v)),
            const SizedBox(width: 16),
            _buildCounter('Bathrooms', _baths, (v) => setState(() => _baths = v)),
          ],
        ),
        const SizedBox(height: 32),
        const Text('Amenities', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _allAmenities.map((a) {
            final isSelected = _selectedAmenities.contains(a);
            return FilterChip(
              label: Text(a),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedAmenities.add(a);
                  } else {
                    _selectedAmenities.remove(a);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        const Text('Proximity & Vital Signs', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildSlider('Road Proximity (meters)', _proximityToRoad.toDouble(), 0, 1000, (v) => setState(() => _proximityToRoad = v.toInt())),
        _buildSlider('Avg. Electricity (hrs/day)', _electricityHours.toDouble(), 0, 24, (v) => setState(() => _electricityHours = v.toInt())),
        _buildSlider('Hospital Proximity (km)', _proximityToHospital, 0, 20, (v) => setState(() => _proximityToHospital = v)),
        const SizedBox(height: 24),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'General Description', border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildStepTechnical() {
    return Column(
      key: const ValueKey(4),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Technical Specifications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Provide technical details about the structure.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        DropdownButtonFormField<int>(
          initialValue: _yearBuilt,
          items: List.generate(50, (index) => 2026 - index).map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
          onChanged: (v) => setState(() => _yearBuilt = v),
          decoration: const InputDecoration(labelText: 'Year Built', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _sqftController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Total Square Footage (approx)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          initialValue: _foundationType,
          items: ['Strip Foundation', 'Raft Foundation', 'Pile Foundation', 'Pad Foundation'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _foundationType = v!),
          decoration: const InputDecoration(labelText: 'Foundation Type', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          title: const Text('History of Flooding in Area?'),
          subtitle: const Text('Integrity check for low-lying areas'),
          value: _floodingHistory,
          onChanged: (v) => setState(() => _floodingHistory = v),
          activeThumbColor: AppColors.primaryLight,
        ),
      ],
    );
  }

  Widget _buildStepLegal() {
    return Column(
      key: const ValueKey(5),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Verification & Documents', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Check the boxes for documents you have available.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        _buildCheckItem('Certificate of Occupancy (C of O)', _hasCOofO, (v) => setState(() => _hasCOofO = v!)),
        _buildCheckItem('Governor\'s Consent', _hasGovernorsConsent, (v) => setState(() => _hasGovernorsConsent = v!)),
        _buildCheckItem('Survey Plan', _hasSurveyPlan, (v) => setState(() => _hasSurveyPlan = v!)),
        _buildCheckItem('Deed of Assignment', _hasDeedOfAssignment, (v) => setState(() => _hasDeedOfAssignment = v!)),
        _buildCheckItem('Building Plan Approval', _hasBuildingPlanApproval, (v) => setState(() => _hasBuildingPlanApproval = v!)),
        const Divider(height: 48),
        const Text('Due Diligence', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildCheckItem('Soil Test Report Available', _hasSoilTest, (v) => setState(() => _hasSoilTest = v!)),
        _buildCheckItem('Structural Integrity Report', _hasStructuralReport, (v) => setState(() => _hasStructuralReport = v!)),
        _buildCheckItem('Lawyer Verified Terms', _lawyerVerified, (v) => setState(() => _lawyerVerified = v!)),
        const SizedBox(height: 24),
        TextField(
          controller: _dueDiligenceController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Internal Due Diligence Notes', hintText: 'Any extra technical or legal notes...', border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildCheckItem(String label, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.primaryLight,
      dense: true,
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: AppColors.primaryLight,
        ),
      ],
    );
  }

  Widget _buildStepReview() {
    return Column(
      key: const ValueKey(6),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReviewRow('Title', _titleController.text),
        _buildReviewRow('Price', '₦${_priceController.text}/$_priceTerm'),
        _buildReviewRow('Type', _propertyType.displayName),
        _buildReviewRow('Photos', '${_images.length} uploaded'),
        _buildReviewRow('Location', _locationName.isEmpty ? 'Abuja' : _locationName),
        const Divider(height: 32),
        const Text('Technical Specs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight)),
        const SizedBox(height: 12),
        _buildReviewRow('Year Built', '$_yearBuilt'),
        _buildReviewRow('SQFT', _sqftController.text.isEmpty ? 'N/A' : _sqftController.text),
        _buildReviewRow('Flooding History', _floodingHistory ? 'Yes' : 'No'),
        const Divider(height: 32),
        const Text('Legal Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight)),
        const SizedBox(height: 12),
        _buildReviewRow('C of O', _hasCOofO ? 'Available' : 'Not Listed'),
        _buildReviewRow('Survey Plan', _hasSurveyPlan ? 'Available' : 'Not Listed'),
        _buildReviewRow('Lawyer Verified', _lawyerVerified ? 'Yes' : 'No'),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCounter(String label, int value, Function(int) onChanged) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(LucideIcons.minusCircle), onPressed: value > 0 ? () => onChanged(value - 1) : null),
                Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(LucideIcons.plusCircle), onPressed: () => onChanged(value + 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)))),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _currentStep == _totalSteps - 1 ? _submit : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _currentStep == _totalSteps - 1 ? 'Publish Listing' : 'Continue',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
