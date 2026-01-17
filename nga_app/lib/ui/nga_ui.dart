import 'dart:math' as math;

import 'package:flutter/material.dart';

class NgaRadii {
  static const double card = 22;
  static const double pill = 18;
}

String formatRelativeTime(int? unixSeconds) {
  if (unixSeconds == null || unixSeconds <= 0) return 'recent';
  final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class NgaShadows {
  static List<BoxShadow> soft(ColorScheme scheme) {
    return [
      BoxShadow(
        color: scheme.shadow.withOpacity(0.08),
        blurRadius: 22,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: scheme.shadow.withOpacity(0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }
}

class NgaCard extends StatelessWidget {
  const NgaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(NgaRadii.card),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: NgaShadows.soft(scheme),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class NgaAvatar extends StatelessWidget {
  const NgaAvatar({
    super.key,
    required this.seed,
    this.size = 44,
  });

  final String seed;
  final double size;

  Color _colorFromSeed(int base, double t) {
    final v = (base + (t * 70).round()) % 360;
    return HSLColor.fromAHSL(1, v.toDouble(), 0.45, 0.55).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final s = seed.trim().isEmpty ? 'U' : seed.trim();
    final code = s.codeUnits.fold<int>(0, (p, c) => p + c);

    final c1 = _colorFromSeed(code, 0.0);
    final c2 = _colorFromSeed(code, 1.0);
    final c3 = _colorFromSeed(code, 2.0);

    final initial = s.substring(0, 1).toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: const Alignment(-1, -1),
          end: const Alignment(1, 1),
          colors: [c1, c2, c3],
          stops: const [0.0, 0.55, 1.0],
          transform: GradientRotation(math.pi / 12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class NgaPill extends StatelessWidget {
  const NgaPill({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.emphasis = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final bg = emphasis ? scheme.primaryContainer : scheme.surface;
    final fg = emphasis ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(NgaRadii.pill),
      child: Ink(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(NgaRadii.pill),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<int?> showFidPickerDialog(
  BuildContext context, {
  required int initialFid,
}) async {
  final controller = TextEditingController(text: '$initialFid');
  final scheme = Theme.of(context).colorScheme;

  return showDialog<int>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        title: Text(
          'Open Forum',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter fid',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g. 7',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final fid = int.tryParse(controller.text.trim());
              Navigator.of(context).pop(fid);
            },
            child: const Text('Load'),
          ),
        ],
      );
    },
  );
}

void showStubSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
    ),
  );
}
