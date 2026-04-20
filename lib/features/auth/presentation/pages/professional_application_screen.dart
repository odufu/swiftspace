import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../../../../core/services/audio_manager.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/constants/app_constants.dart';

class ProfessionalApplicationScreen extends StatefulWidget {
  const ProfessionalApplicationScreen({super.key});

  @override
  State<ProfessionalApplicationScreen> createState() => _ProfessionalApplicationScreenState();
}

class _ProfessionalApplicationScreenState extends State<ProfessionalApplicationScreen> {
  final _nameController = TextEditingController();
  final _experienceController = TextEditingController();
  
  XFile? _governmentId;
  Uint8List? _govIdBytes;
  XFile? _brokerLicense;
  Uint8List? _licenseBytes;
  bool _termsAccepted = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AuthProvider>(context, listen: false).profile;
    _nameController.text = profile?.fullName ?? '';
    if (profile?.yearsExperience != 0) {
      _experienceController.text = profile?.yearsExperience.toString() ?? '';
    }
  }

  Future<void> _pickDocument(bool isGovId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
      withData: true,
    );
    
    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      final xFile = XFile(file.path ?? '');
      sl<AudioManager>().playSuccess(context);
      
      setState(() {
        if (isGovId) {
          _governmentId = xFile;
          _govIdBytes = file.bytes;
        } else {
          _brokerLicense = xFile;
          _licenseBytes = file.bytes;
        }
      });
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.isEmpty || _experienceController.text.isEmpty) {
        UiUtils.showError(context, 'Please fill in all details');
        return;
      }
    }
    if (_currentStep == 1) {
      if (_governmentId == null || _brokerLicense == null) {
        UiUtils.showError(context, 'Please upload both documents');
        return;
      }
    }

    sl<AudioManager>().playClick(context);
    setState(() => _currentStep++);
  }

  void _prevStep() {
    sl<AudioManager>().playClick(context);
    setState(() => _currentStep--);
  }

  Future<void> _submit() async {
    if (!_termsAccepted) {
      UiUtils.showError(context, 'Please accept the terms');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      await authProvider.submitApplication(
        fullName: _nameController.text,
        yearsExperience: int.parse(_experienceController.text),
        governmentIdPath: kIsWeb ? null : _governmentId?.path,
        governmentIdBytes: _govIdBytes,
        govIdFileName: _governmentId?.name,
        brokerLicensePath: kIsWeb ? null : _brokerLicense?.path,
        brokerLicenseBytes: _licenseBytes,
        licenseFileName: _brokerLicense?.name,
      );
      
      if (mounted) {
        UiUtils.showSuccess(context, 'Application submitted successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) UiUtils.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final roleName = authProvider.profile?.role.displayName ?? 'Professional';

    return Scaffold(
      appBar: AppBar(
        title: Text('Apply as $roleName'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: authProvider.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildProgressIndicator(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildStepContent(),
                ),
              ),
              _buildFooter(),
            ],
          ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
              decoration: BoxDecoration(
                color: index <= _currentStep ? AppColors.primaryLight : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _buildStepOne();
      case 1: return _buildStepTwo();
      case 2: return _buildStepThree();
      default: return const SizedBox();
    }
  }

  Widget _buildStepOne() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Professional Credentials', 
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Help us verify your expertise in the field.', 
          style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 32),
        _buildTextField(
          controller: _nameController,
          label: 'Full Legal Name',
          icon: LucideIcons.user,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _experienceController,
          label: 'Years of Experience',
          icon: LucideIcons.calendar,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildStepTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Legal Documents', 
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Upload valid documents for administrative review.', 
          style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 32),
        _buildFilePicker(
          title: 'Government Issued ID',
          subtitle: 'Passport, Driver License, or National ID',
          hasFile: _governmentId != null,
          bytes: _govIdBytes,
          path: _governmentId?.path,
          onTap: () => _pickDocument(true),
          fileName: _governmentId?.name,
          icon: LucideIcons.contact,
        ),
        const SizedBox(height: 24),
        _buildFilePicker(
          title: 'Broker / Professional License',
          subtitle: 'Evidence of your legal authority to practice',
          hasFile: _brokerLicense != null,
          bytes: _licenseBytes,
          path: _brokerLicense?.path,
          onTap: () => _pickDocument(false),
          fileName: _brokerLicense?.name,
          icon: LucideIcons.fileText,
        ),
      ],
    );
  }

  Widget _buildStepThree() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Finalize Application', 
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _buildSummaryItem('Name', _nameController.text),
              _buildSummaryItem('Experience', '${_experienceController.text} Years'),
              _buildSummaryItem('Documents', '2 Files Attached'),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Checkbox(
              value: _termsAccepted, 
              onChanged: (v) => setState(() => _termsAccepted = v!),
              activeColor: AppColors.primaryLight,
            ),
            const Expanded(
              child: Text('I agree to the Professional Terms of Service and verify that all provided data is accurate.'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildFilePicker({
    required String title,
    required String subtitle,
    required bool hasFile,
    required Uint8List? bytes,
    required String? path,
    required String? fileName,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final isPdf = fileName?.toLowerCase().endsWith('.pdf') ?? false;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: hasFile ? Colors.green.withValues(alpha: 0.05) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasFile ? Colors.green.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasFile ? Colors.green : AppColors.primaryLight.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFile ? LucideIcons.check : icon,
                color: hasFile ? Colors.white : AppColors.primaryLight,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            if (hasFile && (bytes != null || path != null))
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: isPdf 
                  ? Container(
                      width: 40,
                      height: 40,
                      color: Colors.red.withValues(alpha: 0.1),
                      child: const Icon(LucideIcons.fileText, color: Colors.red, size: 20),
                    )
                  : (kIsWeb 
                       ? Image.memory(bytes!, width: 40, height: 40, fit: BoxFit.cover)
                       : Image.file(File(path!), width: 40, height: 40, fit: BoxFit.cover)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _currentStep == 2 ? _submit : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(_currentStep == 2 ? 'Submit Application' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
