import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/savings_provider.dart';
import '../models/savings_plan.dart';
import '../services/audio_manager.dart';
import '../models/property.dart'; // To get PropertyType

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  void _startNewPlan() {
    AudioManager().playClick(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _CreatePlanWizard()));
  }

  @override
  Widget build(BuildContext context) {
    final savingsProvider = Provider.of<SavingsProvider>(context);
    final theme = Theme.of(context);
    final plan = savingsProvider.activePlan;

    if (plan == null) {
      return _buildEmptyState(theme);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(plan, theme),
            const SizedBox(height: 24),
            _buildCountdownBanner(plan, savingsProvider.simulatedTime, theme),
            const SizedBox(height: 32),
            _buildGamifiedHeatmap(plan, theme),
            const SizedBox(height: 32),
            _buildBankPartnerInfo(plan, theme),
            const SizedBox(height: 48),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          savingsProvider.simulateFastForward();
          AudioManager().playSuccess(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulated early top-up success!')));
        },
        icon: const Icon(LucideIcons.zap),
        label: const Text('Top-Up Now'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [theme.colorScheme.primary, Colors.teal]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5),
                  ]
                ),
                child: const Icon(LucideIcons.piggyBank, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 32),
              const Text(
                'Power Your Real Estate Goal',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Partner with top banks to save automatically for your rent or purchase targets. Watch your Vault grow with premium interest yields.',
                style: TextStyle(color: Colors.grey[600], fontSize: 16, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _startNewPlan,
                icon: const Icon(LucideIcons.rocket),
                label: const Text('Setup Vault Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(SavingsPlan plan, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.goalName.toUpperCase(),
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12),
              ),
              const Icon(LucideIcons.target, color: Colors.white70, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Vault Balance',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₦${plan.savedSoFar.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 8),
                child: Text(
                  '/ ₦${(plan.targetAmount / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildMiniStat(LucideIcons.trendingUp, 'Yield', '+₦${plan.accruedInterest.toStringAsFixed(2)}'),
              const SizedBox(width: 24),
              _buildMiniStat(LucideIcons.calendarClock, 'Cycle', plan.frequency.name.toUpperCase()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildCountdownBanner(SavingsPlan plan, DateTime now, ThemeData theme) {
    final nextDate = plan.nextPaymentDate;
    final diff = nextDate.difference(now);
    
    String countdownStr;
    if (diff.isNegative) {
      countdownStr = 'Processing next cycle...';
    } else {
      final d = diff.inDays;
      final h = (diff.inHours % 24).toString().padLeft(2, '0');
      final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
      countdownStr = d > 0 ? '$d days $h:$m:$s' : '$h:$m:$s';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.clock, color: Colors.orange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next Auto-Debit • ₦${plan.amountPerCycle.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 4),
                Text(countdownStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamifiedHeatmap(SavingsPlan plan, ThemeData theme) {
    // Dynamic lively gamification map
    final totalBlocks = plan.maxCycles;
    final completedBlocks = plan.history.where((r) => r.isCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vault Consistency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(totalBlocks, (index) {
                  final isDone = index < completedBlocks;
                  final isNext = index == completedBlocks;
                  
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutBack,
                    width: isDone ? 22 : 18,
                    height: isDone ? 22 : 18,
                    decoration: BoxDecoration(
                      color: isDone 
                          ? theme.colorScheme.primary 
                          : isNext 
                              ? Colors.orange.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: isDone ? [
                        BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1)
                      ] : null,
                    ),
                    child: isDone ? const Icon(Icons.check, size: 14, color: Colors.white) : 
                           isNext ? const Icon(Icons.downloading, size: 12, color: Colors.orange) : null,
                  );
                }),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('Successfully Saved', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  Text('$completedBlocks / $totalBlocks', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBankPartnerInfo(SavingsPlan plan, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Secured By Partner Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Image.network(plan.bank.logoUrl, width: 48, height: 48, errorBuilder: (_,__,___) => const Icon(LucideIcons.building, size: 48)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.bank.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(plan.bank.tagLine, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${plan.bank.interestRate}% P.A Yield', style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------
// Creation Wizard
// ----------------------------------------------------------------------

class _CreatePlanWizard extends StatefulWidget {
  const _CreatePlanWizard();

  @override
  State<_CreatePlanWizard> createState() => _CreatePlanWizardState();
}

class _CreatePlanWizardState extends State<_CreatePlanWizard> {
  String _goalType = 'Acquisition'; // 'Acquisition' or 'Rent'
  PropertyType _propType = PropertyType.flatsAndApartments;
  SavingsFrequency _frequency = SavingsFrequency.monthly;
  int _durationMonths = 12;
  PartnerBank? _selectedBank;

  double _getAveragePriceFor(PropertyType type) {
    if (_goalType == 'Rent') {
      // Average annual rent
      switch (type) {
        case PropertyType.detachedDuplex:
        case PropertyType.semiDetachedDuplex:
          return 12000000;
        case PropertyType.flatsAndApartments:
          return 3500000;
        case PropertyType.detachedBungalows:
          return 5000000;
        default:
          return 2500000;
      }
    }
    // Purchase prices
    switch (type) {
      case PropertyType.detachedDuplex:
        return 150000000;
      case PropertyType.detachedBungalows:
        return 65000000;
      case PropertyType.flatsAndApartments:
        return 45000000;
      case PropertyType.lands:
        return 20000000;
      default:
        return 55000000;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final banks = SavingsProvider.partnerBanks;
    final avgPrice = _getAveragePriceFor(_propType);

    return Scaffold(
      appBar: AppBar(title: const Text('Vault Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What is your savings goal?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _goalTypeTile(
                    'Acquisition',
                    LucideIcons.home,
                    'Save to Buy',
                    _goalType == 'Acquisition',
                    theme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _goalTypeTile(
                    'Rent',
                    LucideIcons.repeat,
                    'Recurring Rent',
                    _goalType == 'Rent',
                    theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text('What property type are you targeting?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PropertyType.values.map((pt) {
                final isSelected = _propType == pt;
                return ChoiceChip(
                  label: Text(pt.name.toUpperCase()),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _propType = pt),
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: isSelected ? theme.colorScheme.primary : Colors.grey[700], fontWeight: isSelected ? FontWeight.bold : null),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(16)
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'The average market price for a ${_propType.name} is assessed at ₦${(avgPrice/1000000).toStringAsFixed(1)}M. We will set this as your vault goal.',
                      style: TextStyle(color: Colors.blue[900], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text('Plan Maturity Timeframe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _durationMonths,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              items: const [
                DropdownMenuItem(value: 6, child: Text('6 Months')),
                DropdownMenuItem(value: 12, child: Text('1 Year (12 Months)')),
                DropdownMenuItem(value: 24, child: Text('2 Years (24 Months)')),
                DropdownMenuItem(value: 36, child: Text('3 Years (36 Months)')),
                DropdownMenuItem(value: 60, child: Text('5 Years (60 Months)')),
              ],
              onChanged: (val) => setState(() => _durationMonths = val!),
            ),
            const SizedBox(height: 32),

            const Text('Saving Rhythm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: SavingsFrequency.values.map((f) {
                final isSelected = _frequency == f;
                return ChoiceChip(
                  label: Text(f.name.toUpperCase()),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _frequency = f),
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: isSelected ? theme.colorScheme.primary : Colors.grey[700], fontWeight: isSelected ? FontWeight.bold : null),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            const Text('Select Target Partner Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            const Text('Your funds are held securely yielding interest until you are ready.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            ...banks.map((bank) {
              final isSub = _selectedBank?.id == bank.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedBank = bank),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSub ? theme.colorScheme.primary.withValues(alpha: 0.05) : theme.colorScheme.surface,
                    border: Border.all(color: isSub ? theme.colorScheme.primary : Colors.grey.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Image.network(bank.logoUrl, width: 40, height: 40, errorBuilder: (_,__,___) => const Icon(LucideIcons.landmark)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bank.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${bank.interestRate}% APY', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      if (isSub) Icon(LucideIcons.checkCircle2, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedBank == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a partner bank')));
                    return;
                  }
                  final provider = Provider.of<SavingsProvider>(context, listen: false);
                  provider.createPlan(
                    goalName: '${_propType.displayName.toUpperCase()} ${_goalType == 'Rent' ? 'RENTAL' : 'ACQUISITION'}',
                    bank: _selectedBank!,
                    frequency: _frequency,
                    targetAmount: avgPrice,
                    durationMonths: _durationMonths,
                  );
                  AudioManager().playSuccess(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Create Plan & Link Card', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalTypeTile(
    String type,
    IconData icon,
    String label,
    bool isSelected,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _goalType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? theme.colorScheme.primary : Colors.grey),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.colorScheme.primary : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
