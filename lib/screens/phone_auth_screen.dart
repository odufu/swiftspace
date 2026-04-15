import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'otp_verification_screen.dart';

// Country model
class _Country {
  final String flag;
  final String name;
  final String dialCode;
  final String hint;
  const _Country({required this.flag, required this.name, required this.dialCode, required this.hint});
}

const List<_Country> _countries = [
  _Country(flag: '🇳🇬', name: 'Nigeria', dialCode: '+234', hint: '801 234 5678'),
  _Country(flag: '🇬🇧', name: 'United Kingdom', dialCode: '+44', hint: '7911 123456'),
  _Country(flag: '🇺🇸', name: 'United States', dialCode: '+1', hint: '202 555 0100'),
  _Country(flag: '🇨🇦', name: 'Canada', dialCode: '+1', hint: '416 555 0100'),
  _Country(flag: '🇬🇭', name: 'Ghana', dialCode: '+233', hint: '24 123 4567'),
  _Country(flag: '🇰🇪', name: 'Kenya', dialCode: '+254', hint: '712 345 678'),
  _Country(flag: '🇿🇦', name: 'South Africa', dialCode: '+27', hint: '71 234 5678'),
  _Country(flag: '🇪🇬', name: 'Egypt', dialCode: '+20', hint: '10 2345 6789'),
  _Country(flag: '🇪🇹', name: 'Ethiopia', dialCode: '+251', hint: '91 123 4567'),
  _Country(flag: '🇹🇿', name: 'Tanzania', dialCode: '+255', hint: '621 234 567'),
  _Country(flag: '🇺🇬', name: 'Uganda', dialCode: '+256', hint: '712 345 678'),
  _Country(flag: '🇷🇼', name: 'Rwanda', dialCode: '+250', hint: '788 123 456'),
  _Country(flag: '🇸🇳', name: 'Senegal', dialCode: '+221', hint: '77 123 4567'),
  _Country(flag: '🇨🇮', name: "Côte d'Ivoire", dialCode: '+225', hint: '07 12 34 56'),
  _Country(flag: '🇨🇲', name: 'Cameroon', dialCode: '+237', hint: '6 71 23 45 67'),
  _Country(flag: '🇦🇺', name: 'Australia', dialCode: '+61', hint: '412 345 678'),
  _Country(flag: '🇮🇳', name: 'India', dialCode: '+91', hint: '98765 43210'),
  _Country(flag: '🇦🇪', name: 'UAE', dialCode: '+971', hint: '50 123 4567'),
  _Country(flag: '🇸🇦', name: 'Saudi Arabia', dialCode: '+966', hint: '51 234 5678'),
  _Country(flag: '🇩🇪', name: 'Germany', dialCode: '+49', hint: '151 1234 5678'),
  _Country(flag: '🇫🇷', name: 'France', dialCode: '+33', hint: '6 12 34 56 78'),
  _Country(flag: '🇪🇸', name: 'Spain', dialCode: '+34', hint: '612 345 678'),
  _Country(flag: '🇮🇹', name: 'Italy', dialCode: '+39', hint: '312 345 6789'),
  _Country(flag: '🇳🇱', name: 'Netherlands', dialCode: '+31', hint: '6 12345678'),
  _Country(flag: '🇨🇳', name: 'China', dialCode: '+86', hint: '131 2345 6789'),
  _Country(flag: '🇯🇵', name: 'Japan', dialCode: '+81', hint: '90 1234 5678'),
  _Country(flag: '🇧🇷', name: 'Brazil', dialCode: '+55', hint: '11 91234-5678'),
  _Country(flag: '🇮🇳', name: 'India', dialCode: '+91', hint: '98765 43210'),
];

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  _Country _selected = _countries.first; // Nigeria by default

  void _showCountryPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchCtrl = TextEditingController();
    List<_Country> filtered = List.from(_countries);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          builder: (_, ctrl) => Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(children: [
              const SizedBox(height: 12),
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Select Country', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search country...',
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (q) {
                    setModal(() {
                      filtered = _countries.where((c) =>
                        c.name.toLowerCase().contains(q.toLowerCase()) ||
                        c.dialCode.contains(q)
                      ).toList();
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    final isCurrent = c.dialCode == _selected.dialCode && c.name == _selected.name;
                    return ListTile(
                      leading: Text(c.flag, style: const TextStyle(fontSize: 28)),
                      title: Text(c.name, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(c.dialCode, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                        if (isCurrent) ...[const SizedBox(width: 8), Icon(LucideIcons.checkCircle2, color: Theme.of(context).colorScheme.primary, size: 18)],
                      ]),
                      onTap: () {
                        setState(() {
                          _selected = c;
                          _phoneController.clear();
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _submitPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => OtpVerificationScreen(phoneNumber: '${_selected.dialCode} $phone'),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.fastOutSlowIn)),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your mobile\nnumber',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We will send you a 4-digit verification code.',
                    style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(height: 48),

                  // Phone Input
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _phoneController.text.isNotEmpty ? theme.colorScheme.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(children: [
                      // Country picker button
                      GestureDetector(
                        onTap: _showCountryPicker,
                        child: Row(children: [
                          Text(_selected.flag, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 6),
                          Text(
                            _selected.dialCode,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                          ),
                          const SizedBox(width: 4),
                          Icon(LucideIcons.chevronDown, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 10),
                          Container(width: 1, height: 24, color: isDark ? Colors.white24 : Colors.grey[300]),
                          const SizedBox(width: 12),
                        ]),
                      ),
                      // Number input
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: _selected.hint,
                            hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey[400], fontWeight: FontWeight.normal),
                          ),
                          onChanged: (_) => setState(() {}),
                          autofocus: true,
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 12),
                  // Selected country label
                  Row(children: [
                    Icon(LucideIcons.globe, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(_selected.name, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _showCountryPicker,
                      child: Text('Change', style: TextStyle(fontSize: 13, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    ),
                  ]),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _phoneController.text.length >= 7 && !_isLoading ? _submitPhone : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        disabledBackgroundColor: isDark ? const Color(0xFF333333) : Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
