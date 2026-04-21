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
  final int _totalSteps = 5;
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
    '24/7 Security', 'Swimming Pool', 'Gym', 'Parking Space', 
    'Elevator', 'Fenced', 'Electricity Supply', 'Running Water'
  ];

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
      if (_images.length < 5) {
        UiUtils.showError(context, 'Please upload at least 5 photos');
        return false;
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
      proximityToRoadMeters: 0,
      electricitySupplyHours: 0,
      hasRunningWater: true,
      proximityToHospitalKm: 0,
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
      case 4: return _buildStepReview();
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
        const SizedBox(height: 24),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildStepReview() {
    return Column(
      key: const ValueKey(4),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ready to go?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Review your listing details before publishing.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        _buildReviewRow('Title', _titleController.text),
        _buildReviewRow('Price', '₦${_priceController.text}/$_priceTerm'),
        _buildReviewRow('Type', _propertyType.displayName),
        _buildReviewRow('Photos', '${_images.length} uploaded'),
        _buildReviewRow('Location', _locationName.isEmpty ? 'Abuja' : _locationName),
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
