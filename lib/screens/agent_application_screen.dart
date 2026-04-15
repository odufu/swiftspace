import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/audio_manager.dart';

class AgentApplicationScreen extends StatefulWidget {
  const AgentApplicationScreen({super.key});

  @override
  State<AgentApplicationScreen> createState() => _AgentApplicationScreenState();
}

class _AgentApplicationScreenState extends State<AgentApplicationScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  void _nextStep() {
    AudioManager().playClick(context);
    AudioManager().triggerHaptic(context);
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _submitApplication();
    }
  }

  void _prevStep() {
    AudioManager().playClick(context);
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  void _submitApplication() async {
    setState(() => _isSubmitting = true);
    AudioManager().playClick(context);
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    AudioManager().playSuccess(context);
    AudioManager().triggerHeavyHaptic(context);
    
    // Let's pass true back, simulating an "Instant Approval" for prototyping
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Application', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isSubmitting 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text('Verifying Credentials...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('This usually takes 24 hours.', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          )
        : Stepper(
            currentStep: _currentStep,
            onStepContinue: _nextStep,
            onStepCancel: _prevStep,
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
                          _currentStep == 2 ? 'Submit Application' : 'Continue',
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
                title: const Text('Agent Details'),
                content: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Full Name or Agency Name',
                        prefixIcon: const Icon(LucideIcons.user),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Years of Experience',
                        prefixIcon: const Icon(LucideIcons.clock),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Identity & License'),
                content: Column(
                  children: [
                    const Text('Upload your Government ID and Real Estate Broker License to verify your identity.', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    _buildUploadButton('Upload Government ID', LucideIcons.creditCard),
                    const SizedBox(height: 12),
                    _buildUploadButton('Upload Broker License', LucideIcons.fileBadge),
                  ],
                ),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Terms & Verification'),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('By submitting this application, you agree to the Swift Space Agent Code of Conduct and commit to upholding accurate, high-quality listings.', style: TextStyle(height: 1.5)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(value: true, onChanged: (v) {}),
                        const Expanded(child: Text('I agree to the Agent Terms & Conditions')),
                      ],
                    ),
                  ],
                ),
                isActive: _currentStep >= 2,
              ),
            ],
          ),
    );
  }

  Widget _buildUploadButton(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(elevation: 0),
            child: const Text('Browse'),
          ),
        ],
      ),
    );
  }
}
