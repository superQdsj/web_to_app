part of '../thread_screen.dart';

class _MainPostHeader extends StatelessWidget {
  const _MainPostHeader({required this.post});

  final ThreadPost post;

  @override
  Widget build(BuildContext context) {
    final authorLabel = post.author?.username ?? 'Anonymous';
    final timeLabel = post.floor != null ? '#${post.floor}' : 'Just now';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with avatar, author info, and post date
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserAvatar(
                name: authorLabel,
                avatarUrl: post.author?.avatar,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        authorLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _ThreadPalette.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _ThreadPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Post date in top-right corner
              if (post.postDate != null) _PostDateDisplay(date: post.postDate!),
            ],
          ),
          const SizedBox(height: 8),
          // Content
          Text(
            post.contentText,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: _ThreadPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostActionsRow extends StatelessWidget {
  const _PostActionsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: const [
          _ActionPill(
            icon: Icons.arrow_upward,
            label: '1.2k',
            foreground: _ThreadPalette.primary,
            background: Color(0x1A1337EC),
          ),
          _ActionPill(
            icon: Icons.arrow_downward,
            label: '15',
            foreground: _ThreadPalette.textSecondary,
            background: _ThreadPalette.surfaceLight,
          ),
          _ActionPill(
            icon: Icons.bookmark_border,
            label: '234',
            foreground: _ThreadPalette.textSecondary,
            background: _ThreadPalette.surfaceLight,
          ),
          _ActionPill(
            icon: Icons.share_outlined,
            label: '89',
            foreground: _ThreadPalette.textSecondary,
            background: _ThreadPalette.surfaceLight,
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.icon, this.iconColor});

  final String title;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _ThreadPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable widget for displaying post date.
///
/// Ensures consistent styling across all post types:
/// - Font size: 12px
/// - Color: textTertiary
/// - Handles overflow with ellipsis
class _PostDateDisplay extends StatelessWidget {
  const _PostDateDisplay({required this.date});
  final String date;

  @override
  Widget build(BuildContext context) {
    return Text(
      date,
      style: const TextStyle(
        fontSize: 12,
        color: _ThreadPalette.textTertiary,
        fontWeight: FontWeight.w400,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
