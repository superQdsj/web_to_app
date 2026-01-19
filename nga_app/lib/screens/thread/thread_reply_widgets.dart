part of '../thread_screen.dart';

class _ReplyCard extends StatelessWidget {
  const _ReplyCard({
    required this.post,
  });

  final ThreadPost post;

  @override
  Widget build(BuildContext context) {
    final authorLabel = post.author?.username ?? 'Anonymous';
    final timeLabel = post.floor != null ? '#${post.floor}' : 'Just now';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _ThreadPalette.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserAvatar(
                name: authorLabel,
                avatarUrl: post.author?.avatar,
                size: 32,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            authorLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _ThreadPalette.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _ThreadPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.contentText,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: _ThreadPalette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _ReplyActionsRow(alignEnd: true),
        ],
      ),
    );
  }
}

class _ReplyTile extends StatelessWidget {
  const _ReplyTile({
    required this.post,
  });

  final ThreadPost post;

  @override
  Widget build(BuildContext context) {
    final authorLabel = post.author?.username ?? 'Anonymous';
    final timeLabel = post.floor != null ? '#${post.floor}' : 'Just now';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserAvatar(
            name: authorLabel,
            avatarUrl: post.author?.avatar,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                const SizedBox(height: 6),
                Text(
                  post.contentText,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: _ThreadPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const _ReplyActionsRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyActionsRow extends StatelessWidget {
  const _ReplyActionsRow({
    this.alignEnd = false,
  });

  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _InlineAction(icon: Icons.thumb_up_outlined, label: '98'),
        SizedBox(width: 16),
        _InlineAction(icon: Icons.thumb_down_outlined, label: '2'),
        SizedBox(width: 16),
        _InlineAction(icon: Icons.reply, label: 'Reply', showLabel: false),
      ],
    );

    if (!alignEnd) {
      return content;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [content],
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.icon,
    required this.label,
    this.showLabel = true,
  });

  final IconData icon;
  final String label;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _ThreadPalette.textSecondary),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: _ThreadPalette.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

