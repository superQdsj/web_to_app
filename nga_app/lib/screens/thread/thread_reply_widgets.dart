part of '../thread_screen.dart';

/// 引用块组件
///
/// 左侧带紫色装饰条的引用样式，用于显示回复引用的内容
class _QuoteBlock extends StatefulWidget {
  const _QuoteBlock({required this.quotedPost});

  final QuotedPost quotedPost;

  @override
  State<_QuoteBlock> createState() => _QuoteBlockState();
}

class _QuoteBlockState extends State<_QuoteBlock> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final authorName = widget.quotedPost.authorName ?? 'Anonymous';
    final hasQuotedText = widget.quotedPost.quotedText.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _ThreadPalette.quoteBackground,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: _ThreadPalette.quoteAccent, width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 作者行：Username wrote:
            Text(
              '$authorName wrote:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _ThreadPalette.quoteAuthor,
              ),
            ),
            if (hasQuotedText) ...[
              const SizedBox(height: 4),
              // 引用内容（斜体+引号）带展开/收起功能
              LayoutBuilder(
                builder: (context, constraints) {
                  const textStyle = TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: _ThreadPalette.quoteText,
                    height: 1.4,
                  );
                  final text = '"${widget.quotedPost.quotedText}"';
                  final textSpan = TextSpan(text: text, style: textStyle);
                  final textPainter = TextPainter(
                    text: textSpan,
                    maxLines: 3,
                    textDirection: TextDirection.ltr,
                  );
                  textPainter.layout(maxWidth: constraints.maxWidth);
                  final exceedsMaxLines = textPainter.didExceedMaxLines;
                  textPainter.dispose();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: textStyle,
                        maxLines: _isExpanded ? null : 3,
                        overflow: _isExpanded ? null : TextOverflow.ellipsis,
                      ),
                      if (exceedsMaxLines)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _isExpanded = !_isExpanded),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _isExpanded ? '收起' : '展开',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _ThreadPalette.quoteAuthor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ] else ...[
              const SizedBox(height: 4),
              const Text(
                '(查看原帖)',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: _ThreadPalette.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReplyCard extends StatelessWidget {
  const _ReplyCard({required this.post});

  final ThreadPost post;

  @override
  Widget build(BuildContext context) {
    final authorLabel = post.author?.username ?? 'Anonymous';
    final timeLabel = post.floor != null ? '#${post.floor}' : 'Just now';
    // 如果有引用，显示回复内容；否则显示原始内容
    final displayContent = post.replyContent ?? post.contentText;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _ThreadPalette.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                child: Row(
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
              ),
              // Post date in top-right corner
              if (post.postDate != null) _PostDateDisplay(date: post.postDate!),
            ],
          ),
          const SizedBox(height: 8),
          // 引用块（如果有）
          if (post.quotedPost != null)
            _QuoteBlock(quotedPost: post.quotedPost!),
          // Content
          Text(
            displayContent,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: _ThreadPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const _ReplyActionsRow(alignEnd: true),
        ],
      ),
    );
  }
}

class _ReplyTile extends StatelessWidget {
  const _ReplyTile({required this.post});

  final ThreadPost post;

  @override
  Widget build(BuildContext context) {
    final authorLabel = post.author?.username ?? 'Anonymous';
    final timeLabel = post.floor != null ? '#${post.floor}' : 'Just now';
    // 如果有引用，显示回复内容；否则显示原始内容
    final displayContent = post.replyContent ?? post.contentText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          // 引用块（如果有）
          if (post.quotedPost != null)
            _QuoteBlock(quotedPost: post.quotedPost!),
          // Content
          Text(
            displayContent,
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
    );
  }
}

class _ReplyActionsRow extends StatelessWidget {
  const _ReplyActionsRow({this.alignEnd = false});

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

    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [content]);
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
