import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Uppercase, letter-spaced label used to separate dense dashboard sections.
class LockoutSectionLabel extends StatelessWidget {
  const LockoutSectionLabel(
    this.label, {
    this.trailing,
    this.padding,
    super.key,
  });

  final String label;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: LockoutPalette.muted,
                letterSpacing: 1.6,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Small status capsule, e.g. "STRICT", "ON TRACK" or "LOCKED".
class LockoutPill extends StatelessWidget {
  const LockoutPill(
    this.label, {
    this.color = LockoutPalette.mint,
    this.icon,
    this.filled = false,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? LockoutPalette.background : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: filled ? color : color.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded icon container used beside app names and settings rows.
class LockoutIconBadge extends StatelessWidget {
  const LockoutIconBadge(
    this.icon, {
    this.color = LockoutPalette.mint,
    this.size = 42,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}

/// Surface with the slightly lifted, outlined look used throughout the app.
class LockoutCardSurface extends StatelessWidget {
  const LockoutCardSurface({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = LockoutPalette.surface,
    this.borderColor = LockoutPalette.outline,
    this.gradient,
    this.onTap,
    this.radius = 22,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: gradient == null ? color : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
    );

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Two-line metric card used for today's summary and history stats.
class LockoutMetricCard extends StatelessWidget {
  const LockoutMetricCard({
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.accent = LockoutPalette.mint,
    super.key,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LockoutCardSurface(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: LockoutPalette.muted,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              if (icon != null) Icon(icon, size: 16, color: accent),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: LockoutPalette.text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 3),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: LockoutPalette.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Consistent thin progress bar for app rows and quotas.
class LockoutProgressBar extends StatelessWidget {
  const LockoutProgressBar({
    required this.value,
    this.color = LockoutPalette.mint,
    this.height = 6,
    super.key,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.isFinite ? value.clamp(0.0, 1.0) : 0,
        minHeight: height,
        color: color,
        backgroundColor: LockoutPalette.surfaceSoft,
      ),
    );
  }
}

/// Small empty/illustrated state with a title and supporting copy.
class LockoutEmptyState extends StatelessWidget {
  const LockoutEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LockoutCardSurface(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          LockoutIconBadge(icon, color: LockoutPalette.muted, size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: LockoutPalette.muted,
                    height: 1.4,
                  ),
                ),
                if (action != null) ...[const SizedBox(height: 8), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
