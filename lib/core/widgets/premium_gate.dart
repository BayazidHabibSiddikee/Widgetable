import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps premium-only content. If `unlocked` is false and there's no
/// SharedPreferences flag `premium = true`, it renders a paywall teaser
/// instead of [child].
///
/// This is intentionally a simple wrapper — swap in RevenueCat / Play Billing
/// by reading `isPremium` from your subscription SDK.
class PremiumGate extends StatelessWidget {
  const PremiumGate({
    required this.child,
    this.feature = 'feature',
    this.unlockText = 'Unlock Premium',
    super.key,
  });

  final Widget child;
  final String feature;
  final String unlockText;

  static Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('premium') ?? false;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
        future: isPremium(),
        builder: (_, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data == true) return child;

          // Teaser paywall
          final cs = Theme.of(context).colorScheme;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [cs.surfaceContainerHighest, cs.surface.withValues(alpha: 0.8)],
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.lock, size: 42, color: cs.primary),
                const SizedBox(height: 12),
                Text(
                  'Premium — $feature',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlock premium templates, stickers, and more. One-time payment or subscription.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _showPaywall(context),
                  child: Text(unlockText),
                ),
              ],
            ),
          );
        },
      );
}

void _showPaywall(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('WidgetBoard Premium', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text('• 50+ exclusive note templates\n• Animated stickers\n• Priority support'),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
            child: FilledButton(
              onPressed: () => _unlockPremium(),
              child: const Text('Subscribe — \$1.99/mo'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.tonal(
              onPressed: () => _unlockPremium(),
              child: const Text('One-time — \$9.99'),
            ),
          ),
        ]),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Maybe later')),
      ]),
    ),
  );
}

Future<void> _unlockPremium() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('premium', true);
  // TODO: Integrate Play Billing / Stripe via your payment SDK here.
}
